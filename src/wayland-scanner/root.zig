const std = @import("std");
const testing = std.testing;

const wayland_scanner = @This();

comptime {
    _ = @import("generator.zig");
}
