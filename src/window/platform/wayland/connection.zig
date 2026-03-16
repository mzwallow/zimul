const std = @import("std");
const mem = std.mem;

const client = @import("bindings.zig");

const log = std.log.scoped(.wayland);

const AppState = struct {
    // Globals
    display: *client.wl_display = undefined,
    registry: *client.wl_registry = undefined,
    compositor: *client.wl_compositor = undefined,
    shm: *client.wl_shm = undefined,
    // Objects
    surface: *client.wl_surface = undefined,
};

fn registryGlobalHandler(
    data: ?*anyopaque,
    registry: *client.wl_registry,
    name: u32,
    interface: [*:0]const u8,
    version: u32,
) callconv(.c) void {
    const state: *AppState = @ptrCast(@alignCast(data));

    if (mem.eql(u8, mem.span(interface), mem.span(client.wl_compositor_interface.name))) {
        const compositor = client.wl_registry_bind(
            registry,
            name,
            &client.wl_compositor_interface,
            version,
        );

        state.compositor = @ptrCast(@alignCast(compositor));
    } else if (mem.eql(u8, mem.span(interface), mem.span(client.wl_shm_interface.name))) {
        const shm = client.wl_registry_bind(
            registry,
            name,
            &client.wl_shm_interface,
            version,
        );

        state.shm = @ptrCast(@alignCast(shm));
    }

    log.debug("interface: '{s}', name: {d},  version: {d}", .{
        interface,
        name,
        version,
    });
}

fn registryGlobalRemoveHandler(
    data: ?*anyopaque,
    wl_registry: *client.wl_registry,
    name: u32,
) callconv(.c) void {
    _ = data; // autofix
    _ = wl_registry; // autofix
    log.debug("wl_registry_global_remove_handler: name:{d}", .{
        name,
    });
}

pub fn main(init: std.process.Init) !void {
    _ = init; // autofix

    var state: AppState = .{};

    const display = client.wl_display_connect(null) orelse {
        return error.Connection;
    };
    defer client.wl_display_disconnect(display);

    const registry = client.wl_display_get_registry(display);
    const registry_listener = client.wl_registry_listener{
        .global = registryGlobalHandler,
        .global_remove = registryGlobalRemoveHandler,
    };

    state.display = display;
    state.registry = registry;

    _ = client.wl_registry_add_listener(registry, &registry_listener, &state);

    _ = client.wl_display_roundtrip(display);

    const surface = client.wl_compositor_create_surface(state.compositor);
    state.surface = surface;

    const width: u32 = 200;
    const height: u32 = 200;
    const stride: u32 = width * 4;
    const size: u32 = stride * height;

    const fd = try std.posix.memfd_create("buffer", 0);
    _ = std.os.linux.ftruncate(fd, size);

    _ = std.os.linux.mmap(
        null,
        size,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .SHARED },
        fd,
        0,
    );

    const pool = client.wl_shm_create_pool(state.shm, fd, size);

    while (true) {
        _ = client.wl_display_dispatch(display);
    }
}
