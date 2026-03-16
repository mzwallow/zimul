const std = @import("std");
const log = std.log;

pub const DisplayError = error{connection};

pub const WlShmFormat = enum(u16) {
    /// 32-bit RGB format, [31:0] x:R:G:B 8:8:8:8 little endian
    xrgb8888 = 1,
};

// ========== Core ==========
const wl_argument = opaque {};
const wl_array = opaque {};

//
// wl_display
//
pub const wl_display = opaque {};

// wl_display | Protocol

const WlDisplayOpcode = enum(u32) {
    sync = 0,
    getRegistry = 1,
};

pub fn wl_display_get_registry(display: ?*wl_display) *wl_registry {
    const registry = wl_proxy_marshal_flags(
        @ptrCast(@alignCast(display)),
        @intFromEnum(WlDisplayOpcode.getRegistry),
        @constCast(&wl_registry_interface),
        wl_proxy_get_version(@ptrCast(@alignCast(display))),
        0,
        @as(?*anyopaque, null),
    );

    return @ptrCast(@alignCast(registry));
}

// wl_display | API
//wl_display_create_queue
//wl_display_create_queue_with_name
//wl_display_connect_to_fd
pub extern "c" fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
pub extern "c" fn wl_display_disconnect(display: *wl_display) void;
//wl_display_get_fd
//wl_display_roundtrip_queue
pub extern "c" fn wl_display_roundtrip(display: *wl_display) c_int;
//wl_display_read_events
//wl_display_prepare_read_queue
//wl_display_prepare_read
//wl_display_cancel_read
//wl_display_dispatch_queue_timeout
//wl_display_dispatch_queue
//wl_display_dispatch_queue_pending
pub extern "c" fn wl_display_dispatch(display: *wl_display) c_int;
//wl_display_dispatch_pending
pub extern "c" fn wl_display_get_error(display: ?*wl_display) c_int;
pub extern "c" fn wl_display_get_protocol_error(display: ?*wl_display, wl_interface: ?**wl_interface, id: ?*u32) u32;
//wl_display_flush
//wl_display_set_max_buffer_size

const wl_event_queue = opaque {};
const wl_interface = extern struct {
    name: [*:0]const u8,
    version: c_int,
    method_count: c_int,
    methods: [*]const wl_message,
    event_count: c_int,
    events: [*]const wl_message,
};
const wl_list = opaque {};
const wl_message = extern struct {
    name: [*:0]const u8,
    signature: [*:0]const u8,
    types: [*]*const wl_interface,
};
const wl_object = opaque {};

//
// wl_proxy
//
const wl_proxy = opaque {};
// API
pub extern "c" fn wl_proxy_marshal_flags(proxy: *wl_proxy, opcode: u32, interface: *const wl_interface, version: u32, flags: u32, ...) *wl_proxy;
pub extern "c" fn wl_proxy_get_version(proxy: ?*wl_proxy) u32;
pub extern "c" fn wl_proxy_add_listener(proxy: *anyopaque, implementation: [*c]?*const fn () callconv(.c) void, data: ?*anyopaque) c_int;

//
// wl_registry
//
pub const wl_registry = opaque {};
pub extern "c" const wl_registry_interface: wl_interface;

// wl_registry | Protocol

const WlRegistryOpcode = enum(u32) {
    bind = 0,
};

pub fn wl_registry_bind(
    registry: *wl_registry,
    name: u32,
    interface: *const wl_interface,
    version: u32,
) ?*anyopaque {
    const id = wl_proxy_marshal_flags(
        @ptrCast(@alignCast(registry)),
        @intFromEnum(WlRegistryOpcode.bind),
        interface,
        version,
        0,
        name,
        interface.*.name,
        version,
        @as(?*anyopaque, null),
    );

    return id;
}

pub const wl_registry_listener = extern struct {
    global: *const fn (data: ?*anyopaque, wl_registry: *wl_registry, name: u32, interface: [*:0]const u8, version: u32) callconv(.c) void,
    global_remove: *const fn (data: ?*anyopaque, wl_registry: *wl_registry, name: u32) callconv(.c) void,
};

pub fn wl_registry_add_listener(
    registry: *wl_registry,
    listener: *const wl_registry_listener,
    data: ?*anyopaque,
) c_int {
    return wl_proxy_add_listener(
        @ptrCast(@alignCast(registry)),
        @ptrCast(@alignCast(@constCast(listener))),
        data,
    );
}

//
// wl_compositor
//
pub const wl_compositor = opaque {};
pub extern "c" const wl_compositor_interface: wl_interface;

// wl_compositor | Protocol

const WlCompositorOpcode = enum(u32) {
    createSurface = 0,
    createRegion = 1,
};

pub fn wl_compositor_create_surface(compositor: *wl_compositor) *wl_surface {
    const surface = wl_proxy_marshal_flags(
        @ptrCast(@alignCast(compositor)),
        @intFromEnum(WlCompositorOpcode.createSurface),
        &wl_surface_interface,
        wl_proxy_get_version(@ptrCast(@alignCast(compositor))),
        0,
        @as(?*anyopaque, null),
    );

    return @ptrCast(@alignCast(surface));
}

//
// wl_shm_pool
//
const wl_shm_pool = opaque {};
pub extern "c" const wl_shm_pool_interface: wl_interface;

//
// wl_shm
//
pub const wl_shm = opaque {};
pub extern "c" const wl_shm_interface: wl_interface;

// wl_shm | Protocol

const WlShmOpcode = enum(u32) {
    createPool = 0,
    release = 1,
};

pub fn wl_shm_create_pool(shm: *wl_shm, fd: i32, size: i32) *wl_shm_pool {
    const shmPool = wl_proxy_marshal_flags(
        @ptrCast(@alignCast(shm)),
        @intFromEnum(WlShmOpcode.createPool),
        &wl_shm_pool_interface,
        wl_proxy_get_version(@ptrCast(@alignCast(shm))),
        0,
        @as(?*anyopaque, null),
        fd,
        size,
    );

    return @ptrCast(@alignCast(shmPool));
}

//
// wl_buffer
//
const wl_buffer = opaque {};
pub extern "c" const wl_buffer_interface: wl_interface;

//
// wl_surface
//
pub const wl_surface = opaque {};
pub extern "c" const wl_surface_interface: wl_interface;
