const std = @import("std");

const linux = @import("linux_wayland");

const BYTES_PER_PIXEL: u32 = 4;

pub const State = struct {
    const Self = @This();

    title: [*:0]const u8 = undefined,
    width: u32 = undefined,
    height: u32 = undefined,

    pub fn stride(self: Self) u32 {
        return self.width * BYTES_PER_PIXEL;
    }

    pub fn size(self: Self) u32 {
        return self.stride() * self.height;
    }
};

pub fn run() !void {
    var state = State{
        .title = "HAHA",
        .width = 640,
        .height = 480,
    };

    try linux.run(&state);
}
