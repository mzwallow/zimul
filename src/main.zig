const std = @import("std");
const window = @import("window");

pub fn main(init: std.process.Init) !void {
    _ = init; // autofix

    try window.run();
}
