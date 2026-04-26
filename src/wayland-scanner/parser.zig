const std = @import("std");
const mem = std.mem;
const io = std.Io;
const testing = std.testing;

const xml = @import("xml");

const protocol = @import("protocol.zig");
const wayland_scanner = @import("root.zig");

pub fn parse(areana: mem.Allocator, input_reader: *io.Reader) !protocol.Protocol {
    var streaming_reader = xml.Reader.Streaming.init(areana, input_reader, .{});
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
                    proto = try parseProtocol(areana, reader);
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

fn parseProtocol(arena: mem.Allocator, reader: *xml.Reader) !protocol.Protocol {
    var proto: protocol.Protocol = .empty;

    proto.name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.ProtocolNameNotFound));
    std.log.debug("Parsing protocol: {s}", .{proto.name});

    while (true) {
        const node = try read(reader);
        std.log.debug("Protocol node={any}", .{node});
        switch (node) {
            .element_start => {
                std.log.debug("  Protocol element: <{s}>", .{reader.elementName()});
                if (mem.eql(u8, reader.elementName(), "copyright")) {
                    // Consume entire copyright element
                    var copy_depth: u16 = 1;
                    while (copy_depth > 0) {
                        const copy_node = try read(reader);
                        switch (copy_node) {
                            .eof => return error.UnexpectedEof,
                            .element_start => copy_depth += 1,
                            .element_end => copy_depth -= 1,
                            else => continue,
                        }
                    }
                } else if (mem.eql(u8, reader.elementName(), "interface")) {
                    std.log.debug("  Found interface!", .{});
                    try proto.interfaces.append(arena, try parseInterface(arena, reader));
                } else {
                    return error.UnexpectedElementInProtocol;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "protocol")) break,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }

    std.log.debug("Protocol done: {d} interfaces", .{proto.interfaces.items.len});
    return proto;
}

fn parseInterface(arena: mem.Allocator, reader: *xml.Reader) !protocol.Interface {
    var interface: protocol.Interface = .empty;
    interface.name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.InterfaceNameNotFound));
    interface.version = try std.fmt.parseInt(
        u16,
        try reader.attributeValue(reader.attributeIndex("version") orelse return error.InterfaceVersionNotFound),
        10,
    );
    std.log.debug("  Parsing interface: {s} v{d}", .{ interface.name, interface.version });

    while (true) {
        const node = try read(reader);
        std.log.debug("    Interface node={any}", .{node});
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "description")) {
                    interface.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, reader.elementName(), "request")) {
                    try interface.requests.append(arena, try parseRequest(arena, reader));
                } else if (mem.eql(u8, reader.elementName(), "event")) {
                    try interface.events.append(arena, try parseEvent(arena, reader));
                } else if (mem.eql(u8, reader.elementName(), "enum")) {
                    try interface.enums.append(arena, try parseEnum(arena, reader));
                } else {
                    return error.UnexpectedElementInInterface;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "interface")) break,
            else => continue,
        }
    }

    std.log.debug("    Interface done: {d} requests, {d} events, {d} enums", .{ interface.requests.items.len, interface.events.items.len, interface.enums.items.len });
    return interface;
}

fn parseDescription(arena: mem.Allocator, reader: *xml.Reader) !protocol.Description {
    var description: protocol.Description = .empty;
    description.summary = if (reader.attributeIndex("summary")) |i| try arena.dupe(u8, try reader.attributeValue(i)) else null;

    while (true) {
        const node = try read(reader);
        switch (node) {
            .text => description.description = try arena.dupe(u8, try reader.text()),
            .element_start => return error.UnexpectedChildElement,
            .element_end => if (mem.eql(u8, reader.elementName(), "description")) break,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }

    return description;
}

fn parseRequest(arena: mem.Allocator, reader: *xml.Reader) !protocol.Message {
    var request: protocol.Message = .empty;

    request.name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.RequestNameNotFound));
    if (reader.attributeIndex("type")) |i| {
        request.type = try protocol.MessageType.parse(try reader.attributeValue(i));
    }
    if (reader.attributeIndex("since")) |i| {
        request.since = try std.fmt.parseInt(u16, try reader.attributeValue(i), 10);
    }

    while (true) {
        const node = try read(reader);
        switch (node) {
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "description")) {
                    request.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, reader.elementName(), "arg")) {
                    try request.args.append(arena, try parseArg(arena, reader));
                } else {
                    return error.UnexpectedElementInRequest;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "request")) break,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }

    return request;
}

fn parseEvent(arena: mem.Allocator, reader: *xml.Reader) !protocol.Message {
    var message: protocol.Message = .empty;

    message.name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.EventNameNotFound));
    if (reader.attributeIndex("type")) |i| {
        message.type = try protocol.MessageType.parse(try reader.attributeValue(i));
    }
    if (reader.attributeIndex("since")) |i| {
        message.since = try std.fmt.parseInt(u16, try reader.attributeValue(i), 10);
    }

    while (true) {
        const node = try read(reader);
        switch (node) {
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "description")) {
                    message.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, reader.elementName(), "arg")) {
                    try message.args.append(arena, try parseArg(arena, reader));
                } else {
                    return error.UnexpectedElementInEvent;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "event")) break,
            .eof => return error.UnexpectedEof,
            else => continue,
        }
    }

    return message;
}

fn parseArg(arena: mem.Allocator, reader: *xml.Reader) !protocol.Arg {
    const type_: protocol.ArgType = try .parse(try reader.attributeValue(reader.attributeIndex("type") orelse return error.ArgTypeNotFound));
    const nullable: bool = if (reader.attributeIndex("allow-null")) |i|
        if (mem.eql(u8, try reader.attributeValue(i), "true")) true else false
    else
        false;

    const arg: protocol.Arg = .{
        .name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.ArgNameNotFound)),
        .type = type_,
        .enum_ = if (reader.attributeIndex("enum")) |i| try arena.dupe(u8, try reader.attributeValue(i)) else null,
        .interface = if (reader.attributeIndex("interface")) |i| try arena.dupe(u8, try reader.attributeValue(i)) else null,
        .summary = if (reader.attributeIndex("summary")) |i| try arena.dupe(u8, try reader.attributeValue(i)) else null,
        .nullable = nullable,
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
    var enum_: protocol.Enum = .empty;

    enum_.name = try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.EnumNameNotFound));
    if (reader.attributeIndex("bitfield")) |i| {
        if (mem.eql(u8, try reader.attributeValue(i), "true")) {
            enum_.bitfield = true;
        }
    }
    if (reader.attributeIndex("since")) |i| {
        enum_.since = try std.fmt.parseInt(u16, try reader.attributeValue(i), 10);
    }

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => {
                if (mem.eql(u8, reader.elementName(), "description")) {
                    enum_.description = try parseDescription(arena, reader);
                } else if (mem.eql(u8, reader.elementName(), "entry")) {
                    try enum_.entries.append(arena, try parseEntry(arena, reader));
                } else {
                    return error.UnexpectedElementInEnum;
                }
            },
            .element_end => if (mem.eql(u8, reader.elementName(), "enum")) break,
            else => continue,
        }
    }

    return enum_;
}

fn parseEntry(arena: mem.Allocator, reader: *xml.Reader) !protocol.Entry {
    const name = std.zig.fmtId(try arena.dupe(u8, try reader.attributeValue(reader.attributeIndex("name") orelse return error.AttrNameNotFound)));

    const entry: protocol.Entry = .{
        .name = try std.fmt.allocPrint(arena, "{f}", .{name}),
        .value = try std.fmt.parseInt(
            u32,
            try reader.attributeValue(reader.attributeIndex("value") orelse return error.AttrValueNotFound),
            0,
        ),
        .since = if (reader.attributeIndex("since")) |i| try std.fmt.parseInt(u16, try reader.attributeValue(i), 10) else 1,
        .summary = if (reader.attributeIndex("summary")) |i| try arena.dupe(u8, try reader.attributeValue(i)) else null,
    };

    while (true) {
        const node = try read(reader);
        switch (node) {
            .eof => return error.UnexpectedEof,
            .element_start => return error.UnexpectedChildElement,
            .element_end => return entry,
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
