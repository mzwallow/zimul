const std = @import("std");
const mem = std.mem;
const io = std.Io;
const testing = std.testing;

const xml = @import("xml");

const protocol = @import("protocol.zig");
const wayland_scanner = @import("root.zig");

pub fn parse(gpa: mem.Allocator, input_reader: *io.Reader) !protocol.Protocol {
    var streaming_reader = xml.Reader.Streaming.init(gpa, input_reader, .{});
    defer streaming_reader.deinit();

    const reader = &streaming_reader.interface;

    var proto: protocol.Protocol = .empty;

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => break,
            .xml_declaration => continue,
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "protocol")) {
                    proto = try parseProtocol(gpa, reader);
                } else {
                    return error.UnexpectedRootElement;
                }
            },
            .element_end => continue,
            else => continue,
        }
    }

    return proto;
}

fn read(reader: *xml.Reader) !xml.Reader.Node {
    return reader.read() catch |err| switch (err) {
        error.MalformedXml => {
            const loc = reader.errorLocation();
            std.log.err(
                "{d}:{d}: {any}",
                .{ loc.line, loc.column, reader.errorCode() },
            );
            return error.MalformedXml;
        },
        else => |other| return other,
    };
}

fn attr(arena: mem.Allocator, reader: *xml.Reader, name: []const u8) ![]const u8 {
    const i = reader.attributeIndex(name) orelse return error.AttributeNotFound;
    return try arena.dupe(u8, try reader.attributeValue(i));
}

fn attrOpt(arena: mem.Allocator, reader: *xml.Reader, name: []const u8) !?[]const u8 {
    const i = reader.attributeIndex(name) orelse return null;
    return try arena.dupe(u8, try reader.attributeValue(i));
}

fn attrBool(reader: *xml.Reader, name: []const u8) bool {
    if (reader.attributeIndex(name)) |i| {
        if (reader.attributeValue(i)) |val| {
            return mem.eql(u8, val, "true");
        } else |_| {}
    }
    return false;
}

fn skipElement(reader: *xml.Reader) !void {
    var depth: u16 = 1;
    while (depth > 0) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => depth += 1,
            .element_end => depth -= 1,
            else => continue,
        }
    }
}

fn parseProtocol(arena: mem.Allocator, reader: *xml.Reader) !protocol.Protocol {
    var proto: protocol.Protocol = .empty;

    proto.name = try attr(arena, reader, "name");
    std.log.debug("Parsing protocol: {s}", .{proto.name});

    while (true) {
        const node = try read(reader);
        std.log.debug("Protocol node={any}", .{node});
        switch (node) {
            .element_start => {
                const el = reader.elementName();
                std.log.debug("  Protocol element: <{s}>", .{el});
                if (mem.eql(u8, el, "copyright")) {
                    try skipElement(reader);
                } else if (mem.eql(u8, el, "interface")) {
                    std.log.debug("  Found interface!", .{});
                    try proto.interfaces.append(arena, try parseInterface(arena, reader));
                } else {
                    return error.UnexpectedElementInProtocol;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "protocol")) {
                std.log.debug("Protocol done: {d} interfaces", .{proto.interfaces.items.len});
                return proto;
            },
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }
}

fn parseInterface(arena: mem.Allocator, reader: *xml.Reader) !protocol.Interface {
    var interface: protocol.Interface = .empty;
    interface.name = try attr(arena, reader, "name");
    interface.version = try std.fmt.parseInt(u16, (try attr(arena, reader, "version")), 10);
    std.log.debug("  Parsing interface: {s} v{d}", .{ interface.name, interface.version });

    while (true) {
        const node = try read(reader);
        std.log.debug("    Interface node={any}", .{node});
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => {
                const el = reader.elementName();
                if (mem.eql(u8, el, "description")) {
                    interface.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, el, "request")) {
                    try interface.requests.append(arena, try parseMessage(arena, reader, .request));
                } else if (mem.eql(u8, el, "event")) {
                    try interface.events.append(arena, try parseMessage(arena, reader, .event));
                } else if (mem.eql(u8, el, "enum")) {
                    try interface.enums.append(arena, try parseEnum(arena, reader));
                } else {
                    return error.UnexpectedElementInInterface;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "interface")) {
                std.log.debug("    Interface done: {d} requests, {d} events, {d} enums", .{ interface.requests.items.len, interface.events.items.len, interface.enums.items.len });
                return interface;
            },
            else => continue,
        }
    }
}

fn parseDescription(arena: mem.Allocator, reader: *xml.Reader) !protocol.Description {
    var description: protocol.Description = .{
        .summary = try attrOpt(arena, reader, "summary"),
        .description = null,
    };

    while (true) {
        const node = try read(reader);
        switch (node) {
            .text => description.description = try arena.dupe(u8, try reader.text()),
            .element_start => return error.UnexpectedChildElement,
            .element_end => if (mem.eql(u8, reader.elementName(), "description")) return description,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }
}

const MessageKind = enum { request, event };

fn parseMessage(arena: mem.Allocator, reader: *xml.Reader, kind: MessageKind) !protocol.Message {
    var message: protocol.Message = .empty;

    message.name = try attr(arena, reader, "name");
    if (try attrOpt(arena, reader, "type")) |type_str| {
        message.type = try protocol.MessageType.parse(type_str);
    }
    if (try attrOpt(arena, reader, "since")) |since_str| {
        message.since = try std.fmt.parseInt(u16, since_str, 10);
    }

    const end_tag = switch (kind) {
        .request => "request",
        .event => "event",
    };

    while (true) {
        const node = try read(reader);
        switch (node) {
            .element_start => {
                const el = reader.elementName();
                if (mem.eql(u8, el, "description")) {
                    message.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, el, "arg")) {
                    try message.args.append(arena, try parseArg(arena, reader));
                } else {
                    return switch (kind) {
                        .request => error.UnexpectedElementInRequest,
                        .event => error.UnexpectedElementInEvent,
                    };
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), end_tag)) return message,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }
}

fn parseArg(arena: mem.Allocator, reader: *xml.Reader) !protocol.Arg {
    const arg: protocol.Arg = .{
        .name = try attr(arena, reader, "name"),
        .type = try protocol.ArgType.parse(try reader.attributeValue(reader.attributeIndex("type") orelse return error.ArgTypeNotFound)),
        .@"enum" = try attrOpt(arena, reader, "enum"),
        .interface = try attrOpt(arena, reader, "interface"),
        .summary = try attrOpt(arena, reader, "summary"),
        .nullable = attrBool(reader, "allow-null"),
    };

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => return error.UnexpectedChildElement,
            .element_end => return arg,
            else => continue,
        }
    }
}

fn parseEnum(arena: mem.Allocator, reader: *xml.Reader) !protocol.Enum {
    var @"enum": protocol.Enum = .empty;

    @"enum".name = try attr(arena, reader, "name");
    @"enum".bitfield = attrBool(reader, "bitfield");
    if (try attrOpt(arena, reader, "since")) |since_str| {
        @"enum".since = try std.fmt.parseInt(u16, since_str, 10);
    }

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => {
                const el = reader.elementName();
                if (mem.eql(u8, el, "description")) {
                    @"enum".description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, el, "entry")) {
                    try @"enum".entries.append(arena, try parseEntry(arena, reader));
                } else {
                    return error.UnexpectedElementInEnum;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "enum")) return @"enum",
            else => continue,
        }
    }
}

fn parseEntry(arena: mem.Allocator, reader: *xml.Reader) !protocol.Entry {
    const name = std.zig.fmtId(try attr(arena, reader, "name"));

    var entry: protocol.Entry = .{
        .name = try std.fmt.allocPrint(arena, "{f}", .{name}),
        .value = try std.fmt.parseInt(u32, (try attr(arena, reader, "value")), 0),
        .since = if (try attrOpt(arena, reader, "since")) |s| try std.fmt.parseInt(u16, s, 10) else 1,
        .summary = try attrOpt(arena, reader, "summary"),
        .description = null,
    };

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "description")) {
                    entry.description = try parseDescription(arena, reader);
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "entry")) return entry,
            else => continue,
        }
    }
}

test "parse" {
    testing.log_level = .info;

    const file = try std.Io.Dir.openFileAbsolute(testing.io, "/usr/share/wayland/wayland.xml", .{ .mode = .read_only });
    defer file.close(testing.io);

    var buf: [4096]u8 = undefined;
    var input_reader = file.reader(testing.io, &buf);

    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const proto = try parse(allocator, &input_reader.interface);

    std.log.info("Parsed protocol: {s}", .{proto.name});
    std.log.info("Total interfaces: {d}", .{proto.interfaces.items.len});
    for (proto.interfaces.items, 0..) |iface, i| {
        std.log.info("  [{d}] {s} v{d}: {d} requests, {d} events, {d} enums", .{
            i,
            iface.name,
            iface.version,
            iface.requests.items.len,
            iface.events.items.len,
            iface.enums.items.len,
        });
    }
}
