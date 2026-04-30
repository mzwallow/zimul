// const std = @import("std");
// const testing = std.testing;
// const linux = std.os.linux;

// const wayland = @import("wayland");
// const wl = wayland.client.wl;
// const xdg = wayland.client.xdg;

const window = @import("window");

// const State = struct {
//     window: *window.State,

//     // Globals
//     compositor: *wl.Compositor,
//     shm: *wl.Shm,
//     wm_base: *xdg.WmBase,

//     // Objects
//     surface: *wl.Surface,
//     xdg_surface: *xdg.Surface,

//     // States
//     configured: bool = false,
//     running: bool = true,
// };

// fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, state: *State) void {
//     switch (event) {
//         .global => |params| {
//             if (std.mem.orderZ(u8, params.interface, wl.Compositor.interface.name) == .eq) {
//                 std.log.debug("Binding wl_compositor", .{});
//                 state.compositor = registry.bind(params.name, wl.Compositor, params.version) catch @panic("Failed to bind wl_compositor");
//             } else if (std.mem.orderZ(u8, params.interface, wl.Shm.interface.name) == .eq) {
//                 std.log.debug("Binding wl_shm", .{});
//                 state.shm = registry.bind(params.name, wl.Shm, params.version) catch @panic("Failed to bind wl_shm");
//             } else if (std.mem.orderZ(u8, params.interface, xdg.WmBase.interface.name) == .eq) {
//                 std.log.debug("Binding xdg_wm_base", .{});
//                 state.wm_base = registry.bind(params.name, xdg.WmBase, params.version) catch @panic("Failed to bind xdg_wm_base");
//             }
//         },
//         .global_remove => |params| {
//             std.log.debug("Removing {d}", .{params.name});
//         },
//     }
// }

// fn xdgSurfaceListener(xdg_surface: *xdg.Surface, event: xdg.Surface.Event, state: *State) void {
//     switch (event) {
//         .configure => |params| {
//             xdg_surface.ackConfigure(params.serial);
//             state.surface.commit();
//             state.configured = true;
//         },
//     }
// }

// fn xdgToplevelListener(_: *xdg.Toplevel, event: xdg.Toplevel.Event, state: *State) void {
//     switch (event) {
//         .configure => |params| {
//             state.window.width = @intCast(params.width);
//             state.window.height = @intCast(params.height);
//             state.configured = false;

//             for (params.states.slice(xdg.Toplevel.State)) |s| {
//                 std.log.debug("xdg_toplevel state: {any}", .{s});
//             }
//         },
//         .close => state.running = false,
//     }
// }

// pub fn run(window_state: *window.State) !void {
//     var state: State = State{
//         .window = window_state,
//         .compositor = undefined,
//         .shm = undefined,
//         .surface = undefined,
//         .wm_base = undefined,
//         .xdg_surface = undefined,
//     };

//     const display = try wayland.client.wl.Display.connect(null);
//     defer display.disconnect();

//     const registry = try display.getRegistry();
//     defer registry.destroy();
//     registry.setListener(*State, registryListener, &state);
//     if (display.roundtrip() != .SUCCESS) return error.round_trip;

//     state.surface = try state.compositor.createSurface();
//     defer state.surface.destroy();

//     state.xdg_surface = try state.wm_base.getXdgSurface(state.surface);
//     defer state.xdg_surface.destroy();
//     state.xdg_surface.setListener(*State, xdgSurfaceListener, &state);

//     const xdg_toplevel = try state.xdg_surface.getToplevel();
//     defer xdg_toplevel.destroy();
//     xdg_toplevel.setListener(*State, xdgToplevelListener, &state);
//     xdg_toplevel.setTitle(window_state.title);

//     const buffer = blk: {
//         const fd = linux.memfd_create("zimul", 0);
//         if (linux.errno(linux.ftruncate(@intCast(fd), window_state.size())) != .SUCCESS) {
//             return error.ftruncate;
//         }
//         if (linux.errno(linux.mmap(null, window_state.size(), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(fd), 0)) != .SUCCESS) {
//             return error.mmap;
//         }

//         const shm_pool = try state.shm.createPool(@intCast(fd), @intCast(window_state.size()));
//         defer shm_pool.destroy();

//         break :blk try shm_pool.createBuffer(0, @intCast(window_state.width), @intCast(window_state.height), @intCast(window_state.stride()), wl.Shm.Format.xrgb8888);
//     };
//     defer buffer.destroy();

//     state.surface.commit();
//     while (!state.configured) {
//         if (display.dispatch() != .SUCCESS) return error.dispatch;
//     }

//     state.surface.attach(buffer, 0, 0);
//     state.surface.commit();

//     while (state.running) {
//         if (display.dispatch() != .SUCCESS) return error.dispatch;
//     }
// }

pub fn run(_: *window.State) !void {}
