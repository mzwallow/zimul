const std = @import("std");

pub const Object = opaque {};

pub const Message = extern struct {
    name: [*:0]const u8,
    signature: [*:0]const u8,
    types: ?[*]const ?*const Interface,

    pub fn empty() Message {
        return .{
            .name = undefined,
            .signature = undefined,
            .types = null,
        };
    }
};

test "interface size" {
    std.testing.log_level = .debug;

    const ii = extern struct {
        name: [*:0]const u8,
        version: u32,
        method_count: u32,
        methods: ?[*]const Message,
        event_count: u32,
        events: ?[*]const Message,
    };

    std.log.debug(
        \\========================
        \\Interface size:
        \\  size: {d},
        \\  align: {d},
        \\  offset"name": {d},
        \\  offset"version": {d},
        \\  offset"method_count": {d},
        \\  offset"methods": {d},
        \\  offset"event_count": {d},
        \\  offset"events": {d},
        \\========================
        \\
    , .{
        @sizeOf(ii),
        @alignOf(ii),
        @offsetOf(ii, "name"),
        @offsetOf(ii, "version"),
        @offsetOf(ii, "method_count"),
        @offsetOf(ii, "methods"),
        @offsetOf(ii, "event_count"),
        @offsetOf(ii, "events"),
    });

    std.log.debug(
        \\========================
        \\Message size:
        \\  size: {d},
        \\  align: {d},
        \\  offset"name": {d},
        \\  offset"signature": {d},
        \\  offset"types": {d},
        \\  "types": {d},
        \\========================
        \\
    , .{
        @sizeOf(Message),
        @alignOf(Message),
        @offsetOf(Message, "name"),
        @offsetOf(Message, "signature"),
        @offsetOf(Message, "types"),
        @sizeOf([]?*const Interface),
    });

    layout(Message);
}

fn layout(comptime T: type) void {
    std.log.debug("Type:\t{any}", .{T});
    std.log.debug("\tsize:\t{d}", .{@sizeOf(T)});
    std.log.debug("\talign:\t{d}", .{@alignOf(T)});

    const info = @typeInfo(T);
    const t: T = .empty();

    inline for (info.@"struct".fields) |field| {
        std.log.debug("\tField: {s}", .{field.name});
        std.log.debug("\t\tsize:\t{any}", .{@sizeOf(field.type)});
        std.log.debug("\t\toffset:\t{any}", .{@offsetOf(T, field.name)});
        std.log.debug("\t\talign:\t{any}", .{field.alignment});
        std.log.debug("\t\taddr:\t{*}", .{&@field(t, field.name)});
    }
}

pub const Interface = extern struct {
    name: [*:0]const u8,
    version: u32,
    method_count: u32,
    methods: ?[*]const Message,
    event_count: u32,
    events: ?[*]const Message,

    pub const empty: Interface = .{
        .name = undefined,
        .version = 1,
        .method_count = 0,
        .methods = null,
        .event_count = 0,
        .events = null,
    };
};

pub const List = extern struct {
    prev: *List,
    next: *List,

    pub extern fn wl_list_init(list: *List) void;
    pub extern fn wl_list_insert(list: *List, elm: *List) void;
    pub extern fn wl_list_remove(elm: *List) void;
    pub extern fn wl_list_length(list: *List) c_int;
    pub extern fn wl_list_empty(list: *List) bool;
    pub extern fn wl_list_insert_list(list: *List, elm: *List) void;
    pub extern fn wl_list_for_each(pos: *anyopaque, list: *List, member: []const u8) bool;
    pub extern fn wl_list_for_each_safe(pos: *anyopaque, tmp: *anyopaque, list: *List, member: []const u8) bool;
    pub extern fn wl_list_for_each_reverse(pos: *anyopaque, list: *List, member: []const u8) bool;
    pub extern fn wl_list_for_each_reverse_safe(pos: *anyopaque, tmp: *anyopaque, list: *List, member: []const u8) bool;
};

pub const Array = extern struct {
    size: usize,
    alloc: usize,
    data: ?*anyopaque,

    pub extern fn wl_array_init(array: *Array) void;
    pub extern fn wl_array_release(array: *Array) void;
    pub extern fn wl_array_add(array: *Array, size: usize) ?*anyopaque;
    pub extern fn wl_array_copy(array: *Array, source: *Array) c_int;
    pub extern fn wl_array_for_each(pos: *anyopaque, array: *Array) bool;
};

pub const Fixed = i32;
pub const Argument = extern union {
    i: i32,
    u: u32,
    f: Fixed,
    s: [*:0]const u8,
    o: ?*const Object,
    n: u32,
    a: ?*const Array,
    h: std.os.linux.fd_t,

    pub inline fn wl_fixed_to_double(f: Fixed) f64 {
        return @as(f64, @floatFromInt(f)) / 256.0;
    }
    pub inline fn wl_fixed_from_double(d: f64) Fixed {
        return @intCast(d * 256.0);
    }
    pub inline fn wl_fixed_to_int(f: Fixed) c_int {
        return @divTrunc(f, 256);
    }
    pub inline fn wl_fixed_from_int(i: c_int) Fixed {
        return @intCast(i * 256);
    }
};
