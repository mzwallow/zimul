const std = @import("std");

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
    exe.use_llvm = true;
    exe.root_module.linkSystemLibrary("wayland-client", .{ .needed = true });

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

    const linux_wayland_mod = b.createModule(.{
        .root_source_file = b.path("src/window/linux/wayland.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "wayland", .module = wayland(b, .{ .target = target, .optimize = optimize }) },
        },
    });

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

    const wayland_scanner_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/wayland-scanner/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "xml", .module = xml_dep.module("xml") },
        },
    }) });
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

const WaylandOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

fn wayland(b: *std.Build, options: WaylandOptions) *std.Build.Module {
    const xml_dep = b.dependency("xml", .{
        .target = options.target,
        .optimize = options.optimize,
    });

    const scanner_exe = b.addExecutable(.{
        .name = "wayland-scanner",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wayland-scanner/generator.zig"),
            .target = b.graph.host,
            .optimize = options.optimize,
            .imports = &.{
                .{ .name = "xml", .module = xml_dep.module("xml") },
            },
        }),
    });

    const scanner_run = b.addRunArtifact(scanner_exe);

    const wayland_client_path = scanner_run.addOutputFileArg("wayland-client.zig");
    scanner_run.addFileArg(.{ .cwd_relative = "/usr/share/wayland/wayland.xml" });
    scanner_run.addFileArg(.{ .cwd_relative = "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml" });

    const wayland_common = b.createModule(.{
        .root_source_file = b.path("src/wayland/common.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    const wayland_client_core = b.createModule(.{
        .root_source_file = b.path("src/wayland/client.zig"),
        .target = options.target,
        .optimize = options.optimize,
        .imports = &.{
            .{ .name = "wayland_common", .module = wayland_common },
        },
    });

    const wayland_protocol_client = b.createModule(.{
        .root_source_file = wayland_client_path,
        .target = options.target,
        .optimize = options.optimize,
        .imports = &.{
            .{ .name = "wayland_common", .module = wayland_common },
            .{ .name = "wayland_client_core", .module = wayland_client_core },
        },
    });

    return b.createModule(
        .{
            .root_source_file = b.path("src/wayland/root.zig"),
            .target = options.target,
            .optimize = options.optimize,
            .imports = &.{
                .{ .name = "wayland_protocol_client", .module = wayland_protocol_client },
            },
        },
    );
}
