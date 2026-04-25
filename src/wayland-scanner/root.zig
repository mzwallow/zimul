const std = @import("std");
const testing = std.testing;

pub const xml = @import("xml");

const wayland_scanner = @This();
comptime {
    _ = @import("parser.zig");
    _ = @import("generator.zig");
    _ = @import("common.zig");
}
