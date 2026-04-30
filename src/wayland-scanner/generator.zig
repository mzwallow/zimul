const std = @import("std");
const zig = std.zig;
const testing = std.testing;
const mem = std.mem;

const common = @import("common.zig");
const parser = @import("parser.zig");
const protocol = @import("protocol.zig");
const Arg = protocol.Arg;
const Entry = protocol.Entry;
const Enum = protocol.Enum;
const Protocol = protocol.Protocol;
const Message = protocol.Message;

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
    for (protocols) |proto| {
        const prefix = try protocolPrefix(allocator, proto.name);
        for (proto.interfaces.items) |iface| {
            try iface_map.put(iface.name, prefix);
        }
    }

    for (protocols) |proto| {
        const prefix = try protocolPrefix(allocator, proto.name);
        try writer.print("\n\npub const {s} = struct {{\n", .{prefix});
        for (proto.interfaces.items) |iface| {
            try generateInterface(allocator, writer, iface, prefix, iface_map);
        }
        try writer.writeAll("};\n");
    }
}

fn generateInterface(arena: mem.Allocator, writer: *std.Io.Writer, interface: protocol.Interface, prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    try writer.print("pub const {s} = opaque {{\n    const Self = @This();\n\n    const version: u32 = {d};\n\n", .{
        try pascalCase(arena, interface.name),
        interface.version,
    });

    for (interface.requests.items, 0..) |request, i| {
        try generateRequest(arena, writer, interface.name, request, i, prefix, map);
    }

    try generateListener(arena, writer, interface.name, interface.events, prefix, map);
    try generateEnums(arena, interface.enums, writer);

    try writer.print("\npub const interface: common.Interface = .{{\n    .name = \"{s}\",\n    .version = {d},\n    .method_count = {d},\n    .methods = &.{{ {s} }},\n    .event_count = {d},\n    .events = &.{{ {s} }},\n", .{
        interface.name,
        interface.version,
        interface.requests.items.len,
        try generateInterfaceMessages(arena, interface.requests.items, prefix, map),
        interface.events.items.len,
        try generateInterfaceMessages(arena, interface.events.items, prefix, map),
    });

    try writer.writeAll("};\n\n}; // Interface\n\n");
}

fn generateRequest(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, request: Message, opcode: usize, prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    const request_name = try camelCase(arena, request.name);
    const args = try generateArgs(arena, snakeCase(interface_name), request.args, prefix, map);
    const return_type = try generateReturnType(arena, request.args, prefix, map);
    var args_iter = mem.splitScalar(u8, args, ',');
    const first_arg = args_iter.first();
    var first_arg_iter = mem.splitScalar(u8, first_arg, ':');
    const first_arg_name = first_arg_iter.first();

    try writer.print(
        \\pub fn {s}({s}) !{s} {{
        \\
    , .{ request_name, args, return_type });

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
        , .{ first_arg_name, opcode, try generateMarshallingArgs(arena, request.args) });
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
        , .{ first_arg_name, opcode, mem.trimStart(u8, return_type, "*"), try generateMarshallingArgs(arena, request.args) });
    }

    try writer.writeAll(
        \\}
        \\
        \\
    );
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

fn generateListener(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, events: std.ArrayList(Message), current_prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    if (events.items.len == 0) return;

    try writeListenerStruct(arena, writer, interface_name, events, current_prefix, map);
    try writeAddListenerSig(arena, writer, interface_name, events, current_prefix, map);
    try writeListenerInit(arena, writer, events);
    try writeListenerWrappers(arena, writer, interface_name, events, current_prefix, map);
    try writeAddListenerBody(writer);
}

fn writeListenerStruct(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, events: std.ArrayList(Message), prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    try writer.writeAll("const Listener = extern struct {\n");
    for (events.items) |event| {
        const args = try generateArgs(arena, interface_name, event.args, prefix, map);
        try writer.print("    {f}: ?*const fn(data: ?*anyopaque, {s}) callconv(.c) void,\n", .{
            std.zig.fmtId(try camelCase(arena, event.name)),
            args,
        });
    }
    try writer.writeAll("};\n\n");
}

fn writeAddListenerSig(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, events: std.ArrayList(Message), prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    try writer.writeAll(
        \\pub fn addListener(
        \\    self: *Self,
        \\    comptime T: type,
        \\    state: *T,
        \\    comptime handlers: struct {
        \\
    );
    for (events.items) |event| {
        const args = try generateArgs(arena, interface_name, event.args, prefix, map);
        try writer.print("        {f}: ?*const fn(data: *T, {s}) void = null,\n", .{
            std.zig.fmtId(try camelCase(arena, event.name)),
            mem.trimEnd(u8, args, ", "),
        });
    }
    try writer.writeAll("    },\n) !void {\n    const S = struct {\n");
}

fn writeListenerInit(arena: mem.Allocator, writer: *std.Io.Writer, events: std.ArrayList(Message)) !void {
    try writer.writeAll("const listener = Self.Listener{\n");
    for (events.items) |event| {
        const fn_name = std.zig.fmtId(try camelCase(arena, event.name));
        try writer.print(".{f} = if (handlers.{f} != null) {f} else null,\n", .{ fn_name, fn_name, fn_name });
    }
    try writer.writeAll("};\n\n");
}

fn writeListenerWrappers(arena: mem.Allocator, writer: *std.Io.Writer, interface_name: []const u8, events: std.ArrayList(Message), prefix: []const u8, map: std.StringHashMap([]const u8)) !void {
    for (events.items) |event| {
        const argsPairs = try generateArgsContext(arena, interface_name, event.args, prefix, map);
        const fn_name = std.zig.fmtId(try camelCase(arena, event.name));

        var params: std.ArrayList(u8) = .empty;
        var args: std.ArrayList(u8) = .empty;
        for (argsPairs) |pair| {
            try params.print(arena, "{s}_: {s}, ", .{ pair.name, pair.type });
            try args.print(arena, "{s}_, ", .{pair.name});
        }

        try writer.print("        fn {f}(ptr: ?*anyopaque, {s}) callconv(.c) void {{\n            if (handlers.{f}) |h| {{\n                h(@ptrCast(@alignCast(ptr)), {s});\n            }}\n        }}\n", .{
            fn_name,
            mem.trimEnd(u8, try params.toOwnedSlice(arena), ", "),
            fn_name,
            mem.trimEnd(u8, try args.toOwnedSlice(arena), ", "),
        });
    }
    try writer.writeAll("};\n");
}

fn writeAddListenerBody(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
        \\if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
        \\    return error.AddListenerFailed;
        \\}
        \\
    );
    try writer.writeAll("}\n\n");
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

fn argTypeString(arena: mem.Allocator, arg: Arg, prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    if (arg.@"enum") |@"enum"| {
        return try pascalCase(arena, @"enum");
    }
    return switch (arg.type) {
        .int => "i32",
        .uint => "u32",
        .fixed => "common.Fixed",
        .string => if (arg.nullable) "?[*:0]const u8" else "[*:0]const u8",
        .object => if (arg.interface) |iname| blk: {
            const iface = try qualifiedPascalCase(arena, iname, prefix, map);
            break :blk if (arg.nullable)
                try mem.concat(arena, u8, &[_][]const u8{ "?*const ", iface })
            else
                try mem.concat(arena, u8, &[_][]const u8{ "*const ", iface });
        } else "?*anyopaque",
        .array => if (arg.nullable) "?*common.Array" else "*common.Array",
        .new_id, .fd => unreachable, // handled by callers
    };
}

fn generateArgsContext(arena: mem.Allocator, interface: []const u8, args: std.ArrayList(Arg), prefix: []const u8, map: std.StringHashMap([]const u8)) ![]ArgPair {
    var pairs: std.ArrayList(ArgPair) = .empty;

    try pairs.append(arena, .{
        .name = snakeCase(interface),
        .type = try mem.concat(arena, u8, &[_][]const u8{ "*", try pascalCase(arena, interface) }),
    });
    outer: for (args.items) |arg| {
        if (arg.type == .new_id) {
            if (arg.interface == null) {
                try pairs.append(arena, .{ .name = "T", .type = "type" });
            }
            continue :outer;
        }
        const arg_type = if (arg.type == .fd)
            "std.os.linux.fd_t"
        else
            try argTypeString(arena, arg, prefix, map);
        try pairs.append(arena, .{ .name = snakeCase(arg.name), .type = arg_type });
    }

    return pairs.toOwnedSlice(arena);
}

fn generateArgs(arena: mem.Allocator, interface: []const u8, args: std.ArrayList(Arg), prefix: []const u8, map: std.StringHashMap([]const u8)) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;

    try list.print(arena, "{s}: *{s}", .{ snakeCase(interface), try pascalCase(arena, interface) });
    outer: for (args.items) |arg| {
        if (arg.type == .new_id) {
            if (arg.interface == null) {
                try list.appendSlice(arena, ", comptime T: type");
            }
            continue :outer;
        }
        const arg_type = if (arg.type == .fd)
            "std.os.linux.fd_t"
        else
            try argTypeString(arena, arg, prefix, map);
        try list.print(arena, ", {s}: {s}", .{ arg.name, arg_type });
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
