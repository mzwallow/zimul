const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zimul",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
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

    const xml_dep = b.dependency("xml", .{
        .target = target,
        .optimize = optimize,
    });

    const wayland_scanner = b.createModule(.{
        .root_source_file = b.path("src/wayland-scanner/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "xml", .module = xml_dep.module("xml") },
        },
    });

    const scanner = Scanner.create(b, .{});
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.generate("wl_compositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("xdg_wm_base", 1);

    const wayland = b.createModule(.{
        .root_source_file = scanner.result,
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.linkSystemLibrary("wayland-client", .{});
    exe.root_module.addImport("wayland", wayland);

    const linux_wayland_mod = b.createModule(.{
        .root_source_file = b.path("src/window/linux/wayland.zig"),
        .target = target,
        .optimize = optimize,
    });
    linux_wayland_mod.addImport("wayland", wayland);

    const window_mod = b.createModule(.{
        .root_source_file = b.path("src/window/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    window_mod.addImport("linux_wayland", linux_wayland_mod);
    linux_wayland_mod.addImport("window", window_mod);

    exe.root_module.addImport("window", window_mod);

    // Tests
    const test_step = b.step("test", "Run tests");

    const linux_wayland_tests = b.addTest(.{ .root_module = linux_wayland_mod });
    const run_linux_wayland_tests = b.addRunArtifact(linux_wayland_tests);
    test_step.dependOn(&run_linux_wayland_tests.step);

    const wayland_scanner_tests = b.addTest(.{ .root_module = wayland_scanner });
    const run_wayland_scanner_tests = b.addRunArtifact(wayland_scanner_tests);
    test_step.dependOn(&run_wayland_scanner_tests.step);

    // Check
    const exe_check = b.addExecutable(.{
        .name = "zimul",
        .root_module = exe.root_module,
    });
    const check_step = b.step("check", "Check");
    check_step.dependOn(&exe_check.step);
}
