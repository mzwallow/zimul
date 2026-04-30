const std = @import("std");
const mem = std.mem;
const common = @import("common.zig");

pub const Protocol = struct {
    const Self = @This();

    name: []const u8,
    copyright: ?[]const u8,
    description: ?Description,
    interfaces: std.ArrayList(Interface),

    pub const empty: Self = .{
        .name = undefined,
        .copyright = null,
        .description = null,
        .interfaces = .empty,
    };
};

pub const Interface = struct {
    const This = @This();

    name: []const u8,
    version: u32,
    description: ?Description,
    requests: std.ArrayList(Message),
    events: std.ArrayList(Message),
    enums: std.ArrayList(Enum),

    pub const empty: This = .{
        .name = undefined,
        .version = 1,
        .description = null,
        .requests = .empty,
        .events = .empty,
        .enums = .empty,
    };
};

pub const Message = struct {
    const Self = @This();

    name: []const u8,
    type: ?MessageType,
    since: u16,
    description: ?Description,
    args: std.ArrayList(Arg),

    inner: common.Message,

    pub const empty: Self = .{
        .name = undefined,
        .type = null,
        .since = 1,
        .description = null,
        .args = .empty,
        .inner = undefined,
    };

    pub fn signature(self: Self, allocator: mem.Allocator) ![]const u8 {
        var list: std.ArrayList(u8) = .empty;

        // If the message is newer than version 1, prefix with the version number
        if (self.since > 1) {
            try list.print(allocator, "{d}", .{self.since});
        }

        for (self.args.items) |arg| {
            // Handle nullable prefix
            if (arg.nullable) {
                try list.append(allocator, '?');
            }

            // Handle untyped new_id (which is actually "sun" in libwayland signatures)
            if (arg.type == .new_id and arg.interface == null) {
                try list.appendSlice(allocator, "sun");
            } else {
                try list.append(allocator, arg.type.signatureChar());
            }
        }

        return list.toOwnedSlice(allocator);
    }

    pub fn writeSignature(self: Self, writer: *std.Io.Writer) ![]const u8 {
        // If the message is newer than version 1, prefix with the version number
        if (self.since > 1) {
            try writer.print("{d}", .{self.since});
        }

        for (self.args.items) |arg| {
            // Handle nullable prefix
            if (arg.nullable) {
                try writer.writeByte('?');
            }

            // Handle untyped new_id (which is actually "sun" in libwayland signatures)
            if (arg.type == .new_id and arg.interface == null) {
                try writer.writeAll("sun");
            } else {
                try writer.writeByte(arg.type.signatureChar());
            }
        }
    }
};

pub const MessageType = enum {
    const Self = @This();

    destructor,

    pub fn parse(type_raw: []const u8) !Self {
        if (mem.eql(u8, type_raw, "destructor")) return .destructor;
        return error.UnknownMessageType;
    }
};

pub const Arg = struct {
    name: []const u8,
    type: ArgType,
    @"enum": ?[]const u8,
    interface: ?[]const u8,
    summary: ?[]const u8,
    nullable: bool,
};

pub const Enum = struct {
    const Self = @This();

    name: []const u8,
    bitfield: bool,
    since: ?u16,
    entries: std.ArrayList(Entry),
    description: ?Description,

    pub const empty: Self = .{
        .name = undefined,
        .bitfield = false,
        .since = 1,
        .entries = .empty,
        .description = null,
    };
};

pub const Entry = struct {
    const Self = @This();

    name: []const u8,
    value: u32,
    since: u16,
    summary: ?[]const u8,
    description: ?Description,

    pub const empty: Self = .{
        .name = undefined,
        .value = undefined,
        .since = 1,
        .summary = null,
        .description = null,
    };
};

pub const Description = struct {
    description: ?[]const u8,
    summary: ?[]const u8,

    pub const empty: Description = .{
        .description = null,
        .summary = null,
    };
};

pub const ArgType = enum {
    const Self = @This();

    int,
    uint,
    fixed,
    string,
    object,
    new_id,
    array,
    fd,

    pub fn parse(type_raw: []const u8) !Self {
        if (mem.eql(u8, type_raw, "int")) return .int;
        if (mem.eql(u8, type_raw, "uint")) return .uint;
        if (mem.eql(u8, type_raw, "fixed")) return .fixed;
        if (mem.eql(u8, type_raw, "string")) return .string;
        if (mem.eql(u8, type_raw, "object")) return .object;
        if (mem.eql(u8, type_raw, "new_id")) return .new_id;
        if (mem.eql(u8, type_raw, "array")) return .array;
        if (mem.eql(u8, type_raw, "fd")) return .fd;
        return error.UnknownArgType;
    }

    pub fn nullable(self: Self) bool {
        return switch (self) {
            .string, .object, .array => true,
            else => false,
        };
    }

    pub fn signatureChar(self: Self) u8 {
        return switch (self) {
            .int => 'i',
            .uint => 'u',
            .fixed => 'f',
            .string => 's',
            .object => 'o',
            .new_id => 'n',
            .array => 'a',
            .fd => 'h',
        };
    }
};
