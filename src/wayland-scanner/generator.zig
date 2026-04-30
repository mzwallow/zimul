const std = @import("std");
const zig = std.zig;
const testing = std.testing;
const mem = std.mem;

const common = @import("common.zig");
const Arg = @import("protocol.zig").Arg;
const Entry = @import("protocol.zig").Entry;
const Enum = @import("protocol.zig").Enum;
const parser = @import("parser.zig");
const Protocol = @import("protocol.zig").Protocol;
const Message = @import("protocol.zig").Message;
const Interface = @import("protocol.zig").Interface;

pub fn generate(allocator: mem.Allocator, writer: *std.Io.Writer, protocols: []const Protocol) !void {
    try writer.writeAll(
        \\// Generated from the protocol XML file. DO NOT EDIT.
        \\
        \\const std = @import("std");
        \\const mem = std.mem;
        \\
        \\const inner = @import("client.zig");
        \\const common = @import("common.zig");
        \\
        \\const Client = @This();
        \\
    );

    var iface_map = std.StringHashMap([]const u8).init(allocator);
    defer iface_map.deinit();
    for (protocols) |protocol| {
        const prefix = try protocolPrefix(allocator, protocol.name);
        for (protocol.interfaces.items) |interface| {
            try iface_map.put(interface.name, prefix);
        }
    }

    for (protocols) |protocol| {
        const prefix = try protocolPrefix(allocator, protocol.name);
        try writer.print(
            \\
            \\
            \\pub const {s} = struct {{
            \\
        , .{prefix});

        for (protocol.interfaces.items) |interface| {
            try writer.writeAll(try std.fmt.allocPrint(allocator,
                \\pub const {s} = opaque {{
                \\    const Self = @This();
                \\
                \\    const version: u32 = {d};
                \\
                \\
            , .{ try pascalCase(allocator, interface.name), interface.version }));

            for (interface.requests.items, 0..) |request, i| {
                const request_name = try camelCase(allocator, request.name);
                const args = try generateArgs(allocator, snakeCase(interface.name), request.args, prefix, iface_map);
                const return_type = try generateReturnType(allocator, request.args, prefix, iface_map);
                var args_iter = mem.splitScalar(u8, args, ',');
                const first_arg = args_iter.first();
                var first_arg_iter = mem.splitScalar(u8, first_arg, ':');
                const first_arg_name = first_arg_iter.first();
                try writer.print(
                    \\pub fn {s}({s}) !{s} {{
                    \\
                , .{
                    request_name,
                    args,
                    return_type,
                });
                if (mem.eql(u8, return_type, "void")) {
                    try writer.print(
                        \\const proxy: *inner.wl_proxy = @ptrCast(@alignCast({s}));
                        \\_ = inner.wl_proxy.wl_proxy_marshal_flags(
                        \\    proxy,
                        \\    {d},
                        \\    null,
                        \\    inner.wl_proxy.wl_proxy_get_version(proxy),
                        \\    0,
                        \\    {s}
                        \\);
                        \\
                    , .{ first_arg_name, i, try generateMarshallingArgs(allocator, request.args) });
                } else {
                    try writer.print(
                        \\const proxy: *inner.wl_proxy = @ptrCast(@alignCast({s}));
                        \\const id = inner.wl_proxy.wl_proxy_marshal_flags(
                        \\    proxy,
                        \\    {d},
                        \\    &{s}.interface,
                        \\    inner.wl_proxy.wl_proxy_get_version(proxy),
                        \\    0,
                        \\    {s}
                        \\) orelse return error.MarshalFailed;
                        \\
                        \\return @ptrCast(@alignCast(id));
                        \\
                    , .{ first_arg_name, i, mem.trimStart(u8, return_type, "*"), try generateMarshallingArgs(allocator, request.args) });
                }
                try writer.writeAll(
                    \\}
                    \\
                    \\
                );
            }

            try generateListener(allocator, writer, interface.name, interface.events, prefix, iface_map);

            try generateEnums(allocator, interface.enums, writer);

            try writer.print(
                \\
                \\pub const interface: common.Interface = .{{
                \\    .name = "{s}",
                \\    .version = {d},
                \\    .method_count = {d},
                \\    .methods = &.{{ {s} }},
                \\    .event_count = {d},
                \\    .events = &.{{ {s} }},
                \\
            , .{
                interface.name,
                interface.version,
                interface.requests.items.len,
                try generateInterfaceMessages(allocator, interface.requests.items, prefix, iface_map),
                interface.events.items.len,
                try generateInterfaceMessages(allocator, interface.events.items, prefix, iface_map),
            });

            try writer.writeAll(
                \\};
                \\
            );

            try writer.writeAll(
                \\}; // Interface
                \\
                \\
            );
        }

        try writer.writeAll(
            \\};
            \\
        );
    }
}

fn generateInterfaceMessages(arena: mem.Allocator, messages: []Message, current_prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    for (messages) |msg| {
        try list.print(arena,
            \\.{{
            \\    .name = "{s}",
            \\    .signature = "{s}",
            \\    .types = &.{{
            \\
        , .{ msg.name, try msg.signature(arena) });

        for (msg.args.items) |arg| {
            if (arg.type == .new_id and arg.interface == null) {
                // Special case: untyped new_id counts as 3 args (s, u, n) in libwayland
                try list.appendSlice(arena, "null,\n");
                try list.appendSlice(arena, "null,\n");
                try list.appendSlice(arena, "null,\n");
            } else if (arg.interface) |interface_name| {
                try list.print(arena, "&{s}.interface,\n", .{try qualifiedPascalCase(arena, interface_name, current_prefix, map)});
            } else {
                try list.appendSlice(arena, "null,\n");
            }
        }
        try list.appendSlice(arena,
            \\},
            \\
        );

        try list.appendSlice(arena,
            \\},
            \\
        );
    }

    return list.toOwnedSlice(arena);
}

fn generateDisplayClientApi() []const u8 {
    return
    \\/// Connect to a Wayland display.
    \\pub inline fn connect(name: ?[*:0]const u8) !*Self {
    \\    return @ptrCast(@alignCast(inner.wl_display.wl_display_connect(name) orelse error.ConnectionFailed));
    \\}
    \\
    \\/// Close a connection to a Wayland display.
    \\pub inline fn disconnect(self: *Self) void {
    \\    inner.wl_display.wl_display_disconnect(@ptrCast(@alignCast(self)));
    \\}
    \\
    \\/// Block until all pending request are processed by the server.
    \\pub inline fn roundtrip(self: *Self) !void {
    \\    if (inner.wl_display.wl_display_roundtrip(@ptrCast(@alignCast(self))) == -1)
    \\      return error.RoundtripFailed;
    \\}
    \\
    \\
    \\
    \\
    ;
}

fn generateEnums(arena: mem.Allocator, enums: std.ArrayList(Enum), writer: *std.Io.Writer) !void {
    for (enums.items) |@"enum"| {
        const enum_name = try pascalCase(arena, @"enum".name);

        try writer.writeAll(try std.fmt.allocPrint(arena,
            \\pub const {s} = enum(u32) {{
            \\
        , .{enum_name}));

        for (@"enum".entries.items) |entry| {
            try writer.writeAll(try std.fmt.allocPrint(arena,
                \\    {s} = {d},
                \\
            , .{ entry.name, entry.value }));
        }

        if (@"enum".bitfield) {
            try writer.print(
                \\
                \\pub fn contains(self: {s}, other: {s}) bool {{
                \\    return @intFromEnum(self) & @intFromEnum(other) != 0;
                \\}}
                \\
                \\pub fn merge(self: {s}, other: {s}) {s} {{
                \\    return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
                \\}}
                \\
            , .{ enum_name, enum_name, enum_name, enum_name, enum_name });
        }

        try writer.writeAll(
            \\};
            \\
            \\
        );
    }
}

fn generateMarshallingArgs(arena: mem.Allocator, args: std.ArrayList(Arg)) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    for (args.items) |arg| {
        if (arg.type == .new_id) {
            if (arg.interface == null) {
                // Untyped new_id: pass the interface name, version, and null (s, u, n in libwayland)
                try list.appendSlice(arena, "T.interface.name, T.interface.version, @as(?*anyopaque, null), ");
            } else {
                // Fixed new_id: just pass mandatory null (n in libwayland)
                try list.appendSlice(arena, "@as(?*anyopaque, null), ");
            }
        } else if (arg.@"enum" != null) {
            // Enums must be cast to their integer type before being passed
            try list.print(arena, "@intFromEnum({s}), ", .{arg.name});
        } else {
            // Regular argument: just pass it as-is
            try list.print(arena, "{s}, ", .{arg.name});
        }
    }

    return list.toOwnedSlice(arena);
}

// TODO: Generate listeners
fn generateListener(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, events: std.ArrayList(Message), current_prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    if (events.items.len == 0) return;

    try writer.writeAll("const Listener = extern struct {\n");
    for (events.items) |event| {
        try writer.print(
            "    {f}: ?*const fn(data: ?*anyopaque, {s}) callconv(.c) void,\n",
            .{
                std.zig.fmtId(try camelCase(arena, event.name)),
                try generateArgs(arena, interface_name, event.args, current_prefix, map),
            },
        );
    }
    try writer.writeAll("};\n\n");

    try writer.writeAll(
        \\pub fn addListener(
        \\    self: *Self,
        \\    comptime T: type,
        \\    state: *T,
        \\    comptime handlers: struct {
        \\
    );
    for (events.items) |event| {
        try writer.print(
            "        {f}: ?*const fn(data: *T, {s}) void = null,\n",
            .{
                std.zig.fmtId(try camelCase(arena, event.name)),
                mem.trimEnd(u8, try generateArgs(arena, interface_name, event.args, current_prefix, map), ", "),
            },
        );
    }
    try writer.writeAll("    },\n");
    try writer.writeAll(
        \\) !void {
        \\    const S = struct {
        \\
    );
    try writer.writeAll("const listener = Self.Listener{\n");
    for (events.items) |event| {
        const fn_name = std.zig.fmtId(try camelCase(arena, event.name));
        try writer.print(
            ".{f} = if (handlers.{f} != null) {f} else null,\n",
            .{ fn_name, fn_name, fn_name },
        );
    }
    try writer.writeAll("};\n\n");

    for (events.items) |event| {
        const argsPairs = try generateArgsContext(arena, interface_name, event.args, current_prefix, map);
        const fn_name = std.zig.fmtId(try camelCase(arena, event.name));

        try writer.print(
            \\        fn {f}(ptr: ?*anyopaque, {s}) callconv(.c) void {{
            \\            if (handlers.{f}) |h| {{
            \\                h(@ptrCast(@alignCast(ptr)), {s});
            \\            }}
            \\        }}
            \\
        ,
            .{
                fn_name,
                blk: {
                    var list: std.ArrayList(u8) = .empty;
                    for (argsPairs) |pair| {
                        try list.print(arena, "{s}_: {s}, ", .{ pair.name, pair.type });
                    }
                    break :blk mem.trimEnd(u8, try list.toOwnedSlice(arena), ", ");
                },
                fn_name,
                blk: {
                    var list: std.ArrayList(u8) = .empty;
                    for (argsPairs) |pair| {
                        try list.print(arena, "{s}_, ", .{pair.name});
                    }
                    break :blk mem.trimEnd(u8, try list.toOwnedSlice(arena), ", ");
                },
            },
        );
    }
    try writer.writeAll("};\n");

    try writer.writeAll(
        \\const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
        \\if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
        \\    return error.AddListenerFailed;
        \\}
        \\
    );

    try writer.writeAll("}\n\n");
}

fn protocolPrefix(arena: mem.Allocator, name: []const u8) ![]const u8 {
    if (mem.eql(u8, name, "wayland")) {
        return "Wl";
    } else if (mem.eql(u8, name, "xdg_shell")) {
        return "Xdg";
    } else {
        return try pascalCase(arena, name);
    }
}

fn qualifiedPascalCase(arena: mem.Allocator, name: []const u8, current_prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    const bare = try pascalCase(arena, name);
    const target_prefix = map.get(name) orelse return bare;
    if (mem.eql(u8, target_prefix, current_prefix)) return bare;
    return try std.fmt.allocPrint(arena, "{s}.{s}", .{ target_prefix, bare });
}

fn snakeCase(name: []const u8) []const u8 {
    if (std.mem.startsWith(u8, name, "wl_")) return name[3..];
    if (std.mem.startsWith(u8, name, "xdg_")) return name[4..];
    return name;
}

fn pascalCase(arena: mem.Allocator, name: []const u8) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    var capitalize_next = true;
    const stripped = if (std.mem.startsWith(u8, name, "wl_"))
        name[3..]
    else if (std.mem.startsWith(u8, name, "xdg_"))
        name[4..]
    else
        name;
    for (stripped) |c| {
        if (c == '_') {
            capitalize_next = true;
        } else if (c == '.') {
            try list.append(arena, c);
            capitalize_next = true;
        } else {
            if (capitalize_next) {
                try list.append(arena, std.ascii.toUpper(c));
                capitalize_next = false;
            } else {
                try list.append(arena, std.ascii.toLower(c));
            }
        }
    }

    return list.toOwnedSlice(arena);
}

fn camelCase(arena: mem.Allocator, name: []const u8) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    var capitalize_next = false;
    for (name) |c| {
        if (c == '_') {
            capitalize_next = true;
        } else {
            if (capitalize_next) {
                try list.append(arena, std.ascii.toUpper(c));
                capitalize_next = false;
            } else {
                try list.append(arena, std.ascii.toLower(c));
            }
        }
    }

    return list.toOwnedSlice(arena);
}

const ArgPair = struct { name: []const u8, type: []const u8 };

fn generateArgsContext(arena: mem.Allocator, interface: []const u8, args: std.ArrayList(Arg), current_prefix: []const u8, map: std.StringHashMap([]const u8)) ![]ArgPair {
    var pairs: std.ArrayList(ArgPair) = .empty;

    try pairs.append(arena, .{
        .name = snakeCase(interface),
        .type = try mem.concat(arena, u8, &[_][]const u8{ "*", try pascalCase(arena, interface) }),
    });
    outer: for (args.items) |arg| {
        try pairs.append(arena, .{
            .name = snakeCase(arg.name),
            .type = if (arg.@"enum") |@"enum"|
                try pascalCase(arena, @"enum")
            else switch (arg.type) {
                .int => "i32",
                .uint => "u32",
                .fixed => "common.Fixed",
                .string => if (arg.nullable) "?[*:0]const u8" else "[*:0]const u8",
                .object => blk: {
                    if (arg.interface) |interface_name| {
                        const iface = try qualifiedPascalCase(arena, interface_name, current_prefix, map);

                        break :blk if (arg.nullable)
                            try mem.concat(arena, u8, &[_][]const u8{ "?*const ", iface })
                        else
                            try mem.concat(arena, u8, &[_][]const u8{ "*const ", iface });
                    } else {
                        break :blk "?*anyopaque";
                    }
                },
                .array => if (arg.nullable) "?*common.Array" else "*common.Array",
                .new_id => {
                    if (arg.interface == null) {
                        try pairs.append(arena, .{ .name = "T", .type = "type" });
                    }
                    continue :outer;
                },
                .fd => "std.os.linux.fd_t",
            },
        });
    }

    return pairs.toOwnedSlice(arena);
}

fn generateArgs(arena: mem.Allocator, interface: []const u8, args: std.ArrayList(Arg), current_prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    try list.print(
        arena,
        "{s}: *{s}",
        .{ snakeCase(interface), try pascalCase(arena, interface) },
    );
    outer: for (args.items) |arg| {
        try list.print(arena, ", {s}: {s}", .{
            arg.name,
            if (arg.@"enum") |@"enum"|
                try pascalCase(arena, @"enum")
            else switch (arg.type) {
                .int => "i32",
                .uint => "u32",
                .fixed => "common.Fixed",
                .string => if (arg.nullable) "?[*:0]const u8" else "[*:0]const u8",
                .object => blk: {
                    if (arg.interface) |interface_name| {
                        const iface = try qualifiedPascalCase(arena, interface_name, current_prefix, map);

                        break :blk if (arg.nullable)
                            try mem.concat(arena, u8, &[_][]const u8{ "?*const ", iface })
                        else
                            try mem.concat(arena, u8, &[_][]const u8{ "*const ", iface });
                    } else {
                        break :blk "?*anyopaque";
                    }
                },
                .array => if (arg.nullable) "?*common.Array" else "*common.Array",
                .new_id => {
                    if (arg.interface == null) {
                        try list.appendSlice(arena, ", comptime T: type");
                    }
                    continue :outer;
                },
                .fd => "std.os.linux.fd_t",
            },
        });
    }

    return list.toOwnedSlice(arena);
}

fn generateReturnType(arena: mem.Allocator, args: std.ArrayList(Arg), current_prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    for (args.items) |arg| {
        if (arg.type == .new_id) {
            if (arg.interface) |interface| {
                return try mem.concat(arena, u8, &[_][]const u8{ "*", try qualifiedPascalCase(arena, interface, current_prefix, map) });
            } else {
                return "*T";
            }
        }
    }
    return "void";
}

test "generate args" {
    testing.log_level = .debug;

    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args: std.ArrayList(Arg) = .empty;

    try args.append(allocator, .{
        .name = "arg1",
        .type = .int,
        .interface = null,
        .nullable = false,
        .@"enum" = null,
        .summary = null,
    });

    try args.append(allocator, .{
        .name = "arg2",
        .type = .string,
        .interface = null,
        .nullable = true,
        .@"enum" = null,
        .summary = null,
    });

    try args.append(allocator, .{
        .name = "arg3",
        .type = .object,
        .interface = "wl_surface",
        .nullable = false,
        .@"enum" = null,
        .summary = null,
    });

    try args.append(allocator, .{
        .name = "face",
        .type = .uint,
        .interface = null,
        .nullable = false,
        .@"enum" = "wl_data_device_manager.dnd_action",
        .summary = null,
    });

    try args.append(allocator, .{
        .name = "arg4",
        .type = .new_id,
        .interface = "wl_surface",
        .nullable = true,
        .@"enum" = null,
        .summary = null,
    });

    var iface_map = std.StringHashMap([]const u8).init(allocator);
    defer iface_map.deinit();
    const result = try generateArgs(allocator, snakeCase("wl_surface"), args, "Wl", iface_map);
    std.debug.print("Generated args: ({s})\n", .{result});
}

test "generate return type" {
    testing.log_level = .debug;

    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args: std.ArrayList(Arg) = .empty;

    try args.append(allocator, .{
        .name = "arg1",
        .type = .int,
        .interface = null,
        .nullable = false,
        .@"enum" = null,
        .summary = null,
    });

    try args.append(allocator, .{
        .name = "arg2",
        .type = .new_id,
        .interface = "wl_surface",
        .nullable = true,
        .@"enum" = null,
        .summary = null,
    });

    var iface_map = std.StringHashMap([]const u8).init(allocator);
    defer iface_map.deinit();
    const result = try generateReturnType(allocator, args, "Wl", iface_map);
    std.debug.print("Generated return type: {s}\n", .{result});
}

test "generate enums" {
    testing.log_level = .debug;

    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var enums: std.ArrayList(Enum) = .empty;
    const entries = try allocator.dupe(Entry, &.{
        .{ .name = "argb8888", .value = 0, .since = 1, .summary = null, .description = null },
        .{ .name = "xrgb8888", .value = 1, .since = 1, .summary = null, .description = null },
        .{ .name = "c8", .value = 0x20203843, .since = 1, .summary = null, .description = null },
    });

    try enums.append(allocator, .{
        .name = "format",
        .entries = .fromOwnedSlice(entries),
        .bitfield = false,
        .description = null,
        .since = 1,
    });

    try enums.append(allocator, .{
        .name = "resize",
        .entries = .fromOwnedSlice(try allocator.dupe(Entry, &.{
            .{ .name = "none", .value = 0, .since = 1, .summary = null, .description = null },
            .{ .name = "top", .value = 1, .since = 1, .summary = null, .description = null },
            .{ .name = "bottom", .value = 2, .since = 1, .summary = null, .description = null },
            .{ .name = "left", .value = 3, .since = 1, .summary = null, .description = null },
            .{ .name = "top_left", .value = 4, .since = 1, .summary = null, .description = null },
            .{ .name = "bottom_left", .value = 6, .since = 1, .summary = null, .description = null },
            .{ .name = "right", .value = 8, .since = 1, .summary = null, .description = null },
            .{ .name = "top_right", .value = 9, .since = 1, .summary = null, .description = null },
            .{ .name = "bottom_right", .value = 10, .since = 1, .summary = null, .description = null },
        })),
        .bitfield = true,
        .description = null,
        .since = 1,
    });

    var buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stderr().writer(testing.io, &buf);
    const stdout = &stdout_writer.interface;

    try generateEnums(allocator, enums, stdout);
    try stdout.flush();
}

test "generate" {
    testing.log_level = .info;

    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;

    const wl_file = try std.Io.Dir.openFileAbsolute(testing.io, "/usr/share/wayland/wayland.xml", .{ .mode = .read_only });
    defer wl_file.close(testing.io);

    var input_reader = wl_file.reader(testing.io, &buf);

    const wl_protocol = try parser.parse(allocator, &input_reader.interface);

    const xdg_file = try std.Io.Dir.openFileAbsolute(testing.io, "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml", .{ .mode = .read_only });
    defer xdg_file.close(testing.io);

    input_reader = xdg_file.reader(testing.io, &buf);

    const xdg_protocol = try parser.parse(allocator, &input_reader.interface);

    const out = try std.Io.Dir.cwd().createFile(testing.io, "src/wayland-scanner/wl.zig", .{ .read = true });
    defer out.close(testing.io);
    var file_writer = out.writer(testing.io, &buf);

    try generate(allocator, &file_writer.interface, &[_]Protocol{
        wl_protocol,
        xdg_protocol,
    });

    try file_writer.flush();
}

// IGNORE THIS
//
// const MessageOffset = struct {
//     interface_name: []const u8,
//     message_name: []const u8,
//     offset: usize,
// };
// var all_type_entries: std.ArrayList(?[]const u8) = .empty;
// var offsets: std.ArrayList(MessageOffset) = .empty;

// // Offset 0 is always null (empty message placeholder)
// try all_type_entries.append(allocator, null);
// for (protocol.interfaces.items) |iface| {
//     // Combine requests and events into one loop
//     const all_messages = [_]std.ArrayList(Message){ iface.requests, iface.events };

//     for (all_messages) |messages| {
//         for (messages.items) |msg| {
//             // Record that this specific message starts at current index
//             try offsets.append(allocator, .{
//                 .interface_name = iface.name,
//                 .message_name = msg.name,
//                 .offset = all_type_entries.items.len,
//             });

//             // Add an entry for every argument
//             for (msg.args.items) |arg| {
//                 if (arg.type == .new_id and arg.interface == null) {
//                     // Special case: untyped new_id counts as 2 args (s, u)
//                     try all_type_entries.append(allocator, null);
//                     try all_type_entries.append(allocator, null);
//                 } else {
//                     try all_type_entries.append(allocator, arg.interface);
//                 }
//             }
//         }
//     }
// }
//
//     try writer.writeAll(try std.fmt.allocPrint(allocator,
//         \\const protocol_types = [_]?*common.Interface{{
//         \\
//     , .{}));
//     for (all_type_entries.items) |maybe_iface| {
//         if (maybe_iface) |iface_name| {
//             try writer.print("    &{s}_interface,\n", .{iface_name});
//         } else {
//             try writer.writeAll("    null,\n");
//         }
//     }
//     try writer.writeAll(
//         \\};
//         \\
//     );
