const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zimul", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zimul",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zimul", .module = mod },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const wayland_exe = b.addExecutable(.{
        .name = "wayland",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/window/platform/wayland/connection.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    wayland_exe.root_module.link_libc = true;
    wayland_exe.root_module.linkSystemLibrary("wayland-client", .{});
    wayland_exe.root_module.addCSourceFile(.{
        .file = b.path("src/window/platform/wayland/xdg-shell-protocol.c"),
    });
    wayland_exe.root_module.addIncludePath(b.path("src/window/platform/wayland"));
    b.installArtifact(wayland_exe);

    const wayland_step = b.step("wayland", "Run Wayland window");
    const wayland_cmd = b.addRunArtifact(wayland_exe);
    wayland_step.dependOn(&wayland_cmd.step);
    wayland_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| wayland_cmd.addArgs(args);

    // Check
    const exe_check = b.addExecutable(.{
        .name = "zimul",
        .root_module = exe.root_module,
    });
    const wayland_exe_check = b.addExecutable(.{
        .name = "wayland",
        .root_module = wayland_exe.root_module,
    });
    const check_step = b.step("check", "Check");
    check_step.dependOn(&exe_check.step);
    check_step.dependOn(&wayland_exe_check.step);
}
