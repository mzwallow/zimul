const std = @import("std");

const Argument = @import("common.zig").Argument;
const Array = @import("common.zig").Array;
const Interface = @import("common.zig").Interface;

pub const wl_event_queue = opaque {
    pub extern fn wl_event_queue_destroy(queue: *wl_event_queue) void;
    // wl_event_queue_get_name
};

pub const wl_display = opaque {
    // wl_display_create_queue
    // wl_display_create_queue_with_name
    // wl_display_connect_to_fd
    pub extern fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
    pub extern fn wl_display_disconnect(display: *wl_display) void;
    // wl_display_get_fd
    // wl_display_roundtrip_queue
    pub extern fn wl_display_roundtrip(display: *wl_display) c_int;
    // wl_display_read_events
    // wl_display_prepare_read_queue
    // wl_display_prepare_read
    // wl_display_cancel_read
    // wl_display_dispatch_queue_timeout
    // wl_display_dispatch_queue
    // wl_display_dispatch_queue_pending
    // wl_display_dispatch_queue_pending_single
    // wl_display_dispatch
    // wl_display_dispatch_pending
    // wl_display_dispatch_pending_single
    // wl_display_get_error
    // wl_display_get_protocol_error
    // wl_display_flush
    // wl_display_set_max_buffer_size
};

pub const wl_proxy = opaque {
    pub extern fn wl_proxy_create(factory: *wl_proxy, *const Interface) ?*wl_proxy;
    pub extern fn wl_proxy_destroy(proxy: *wl_proxy) void;
    pub extern fn wl_proxy_add_listener(proxy: *wl_proxy, implementation: [*]?*const fn () callconv(.c) void, data: ?*anyopaque) c_int;
    // wl_proxy_get_listener
    // wl_proxy_add_dispatcher
    // wl_proxy_marshal_array_constructor
    // wl_proxy_marshal_array_constructor_versioned
    pub extern fn wl_proxy_marshal_flags(proxy: *wl_proxy, opcode: u32, interface: *const Interface, version: u32, flags: u32, ...) ?*wl_proxy;
    // wl_proxy_marshal_array_flags
    // wl_proxy_marshal
    // wl_proxy_marshal_constructor
    // wl_proxy_marshal_constructor_versioned
    // wl_proxy_marshal_array
    // wl_proxy_set_user_data
    // wl_proxy_get_user_data
    pub extern fn wl_proxy_get_version(proxy: *wl_proxy) u32;
    // wl_proxy_get_id
    // wl_proxy_set_tag
    // wl_proxy_get_tag
    // wl_proxy_get_class
    // wl_proxy_get_interface
    // wl_proxy_get_display
    // wl_proxy_set_queue
    // wl_proxy_create_wrapper
    // wl_proxy_wrapper_destroy
};
