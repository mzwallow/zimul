# Pure Zig Wayland Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert the hybrid C/Zig Wayland client to a "Pure Zig" implementation by hand-writing bindings and dropping C header imports and generated C protocol files.

**Architecture:** A new `bindings.zig` file will hold all the raw `extern "c"` declarations, opaque types, and `wl_proxy_marshal_flags` wrappers for Wayland protocols. The main `connection.zig` file will import this and use `std.os.linux` for POSIX operations to fully drop the `libc` dependency.

**Tech Stack:** Zig 0.16.0, `libwayland-client.so`, Linux syscalls (`std.os.linux`).

---

### Task 1: Create bindings.zig and define Core Types

**Files:**
- Create: `src/window/platform/wayland/bindings.zig`

**Step 1: Write bindings skeleton**

```zig
const std = @import("std");

pub const wl_display = opaque {};
pub const wl_registry = opaque {};
pub const wl_compositor = opaque {};
pub const wl_surface = opaque {};
pub const wl_buffer = opaque {};
pub const wl_shm = opaque {};
pub const wl_shm_pool = opaque {};

pub const xdg_wm_base = opaque {};
pub const xdg_surface = opaque {};
pub const xdg_toplevel = opaque {};

// Constants
pub const WL_SHM_FORMAT_XRGB8888 = 1;
```

**Step 2: Commit**

```bash
git add src/window/platform/wayland/bindings.zig
git commit -m "feat: add basic Wayland opaque types"
```

---

### Task 2: Define Core Extern Functions

**Files:**
- Modify: `src/window/platform/wayland/bindings.zig`

**Step 1: Add core externs**

```zig
pub extern "c" fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
pub extern "c" fn wl_display_disconnect(display: *wl_display) void;
pub extern "c" fn wl_display_get_registry(display: *wl_display) ?*wl_registry;
pub extern "c" fn wl_display_roundtrip(display: *wl_display) c_int;
pub extern "c" fn wl_display_dispatch(display: *wl_display) c_int;

// Interfaces (we need these to bind globals)
pub const wl_interface = extern struct {
    name: [*:0]const u8,
    version: c_int,
    method_count: c_int,
    methods: *const anyopaque,
    event_count: c_int,
    events: *const anyopaque,
};

pub extern const wl_compositor_interface: wl_interface;
pub extern const wl_shm_interface: wl_interface;
pub extern const xdg_wm_base_interface: wl_interface;

pub extern "c" fn wl_registry_bind(registry: *wl_registry, name: u32, interface: *const wl_interface, version: u32) ?*anyopaque;
```

**Step 2: Commit**

```bash
git add src/window/platform/wayland/bindings.zig
git commit -m "feat: add core Wayland extern functions and interfaces"
```

---

### Task 3: Define Listeners and Add_Listener wrappers

**Files:**
- Modify: `src/window/platform/wayland/bindings.zig`

**Step 1: Add listeners**

```zig
// wl_registry
pub const wl_registry_listener = extern struct {
    global: *const fn (data: ?*anyopaque, registry: ?*wl_registry, name: u32, interface: [*:0]const u8, version: u32) callconv(.c) void,
    global_remove: *const fn (data: ?*anyopaque, registry: ?*wl_registry, name: u32) callconv(.c) void,
};
pub extern "c" fn wl_registry_add_listener(registry: *wl_registry, listener: *const wl_registry_listener, data: ?*anyopaque) c_int;

// wl_buffer
pub const wl_buffer_listener = extern struct {
    release: *const fn (data: ?*anyopaque, buffer: ?*wl_buffer) callconv(.c) void,
};
pub extern "c" fn wl_buffer_add_listener(buffer: *wl_buffer, listener: *const wl_buffer_listener, data: ?*anyopaque) c_int;
pub extern "c" fn wl_buffer_destroy(buffer: *wl_buffer) void;

// xdg_wm_base
pub const xdg_wm_base_listener = extern struct {
    ping: *const fn (data: ?*anyopaque, xdg_wm_base: ?*xdg_wm_base, serial: u32) callconv(.c) void,
};
pub extern "c" fn xdg_wm_base_add_listener(wm_base: *xdg_wm_base, listener: *const xdg_wm_base_listener, data: ?*anyopaque) c_int;

// xdg_surface
pub const xdg_surface_listener = extern struct {
    configure: *const fn (data: ?*anyopaque, xdg_surface: ?*xdg_surface, serial: u32) callconv(.c) void,
};
pub extern "c" fn xdg_surface_add_listener(surface: *xdg_surface, listener: *const xdg_surface_listener, data: ?*anyopaque) c_int;

// xdg_toplevel
pub const wl_array = extern struct {
    size: usize,
    alloc: usize,
    data: ?*anyopaque,
};

pub const xdg_toplevel_listener = extern struct {
    configure: *const fn (data: ?*anyopaque, toplevel: ?*xdg_toplevel, width: i32, height: i32, states: ?*wl_array) callconv(.c) void,
    close: *const fn (data: ?*anyopaque, toplevel: ?*xdg_toplevel) callconv(.c) void,
};
pub extern "c" fn xdg_toplevel_add_listener(toplevel: *xdg_toplevel, listener: *const xdg_toplevel_listener, data: ?*anyopaque) c_int;
```

**Step 2: Commit**

```bash
git add src/window/platform/wayland/bindings.zig
git commit -m "feat: add Wayland listener structs"
```

---

### Task 4: Implement Protocol Wrappers using wl_proxy_marshal_flags

**Files:**
- Modify: `src/window/platform/wayland/bindings.zig`

**Step 1: Write proxy wrappers**

```zig
pub extern "c" fn wl_proxy_marshal_flags(proxy: *anyopaque, opcode: u32, interface: ?*const wl_interface, version: u32, flags: u32, ...) ?*anyopaque;
pub extern "c" fn wl_proxy_get_version(proxy: *anyopaque) u32;

pub fn wl_compositor_create_surface(compositor: *wl_compositor) ?*wl_surface {
    return @ptrCast(wl_proxy_marshal_flags(@ptrCast(compositor), 0, null, wl_proxy_get_version(@ptrCast(compositor)), 0, null));
}

pub fn wl_shm_create_pool(shm: *wl_shm, fd: i32, size: i32) ?*wl_shm_pool {
    return @ptrCast(wl_proxy_marshal_flags(@ptrCast(shm), 0, null, wl_proxy_get_version(@ptrCast(shm)), 0, null, fd, size));
}

pub fn wl_shm_pool_create_buffer(pool: *wl_shm_pool, offset: i32, width: i32, height: i32, stride: i32, format: u32) ?*wl_buffer {
    return @ptrCast(wl_proxy_marshal_flags(@ptrCast(pool), 0, null, wl_proxy_get_version(@ptrCast(pool)), 0, null, offset, width, height, stride, format));
}

pub fn wl_shm_pool_destroy(pool: *wl_shm_pool) void {
    _ = wl_proxy_marshal_flags(@ptrCast(pool), 1, null, wl_proxy_get_version(@ptrCast(pool)), 1);
}

pub fn wl_surface_attach(surface: *wl_surface, buffer: ?*wl_buffer, x: i32, y: i32) void {
    _ = wl_proxy_marshal_flags(@ptrCast(surface), 1, null, wl_proxy_get_version(@ptrCast(surface)), 0, buffer, x, y);
}

pub fn wl_surface_commit(surface: *wl_surface) void {
    _ = wl_proxy_marshal_flags(@ptrCast(surface), 6, null, wl_proxy_get_version(@ptrCast(surface)), 0);
}

pub extern const xdg_surface_interface: wl_interface;
pub fn xdg_wm_base_get_xdg_surface(wm_base: *xdg_wm_base, surface: *wl_surface) ?*xdg_surface {
    return @ptrCast(wl_proxy_marshal_flags(@ptrCast(wm_base), 2, &xdg_surface_interface, wl_proxy_get_version(@ptrCast(wm_base)), 0, null, surface));
}

pub fn xdg_wm_base_pong(wm_base: *xdg_wm_base, serial: u32) void {
    _ = wl_proxy_marshal_flags(@ptrCast(wm_base), 3, null, wl_proxy_get_version(@ptrCast(wm_base)), 0, serial);
}

pub extern const xdg_toplevel_interface: wl_interface;
pub fn xdg_surface_get_toplevel(surface: *xdg_surface) ?*xdg_toplevel {
    return @ptrCast(wl_proxy_marshal_flags(@ptrCast(surface), 1, &xdg_toplevel_interface, wl_proxy_get_version(@ptrCast(surface)), 0, null));
}

pub fn xdg_surface_ack_configure(surface: *xdg_surface, serial: u32) void {
    _ = wl_proxy_marshal_flags(@ptrCast(surface), 4, null, wl_proxy_get_version(@ptrCast(surface)), 0, serial);
}

pub fn xdg_toplevel_set_title(toplevel: *xdg_toplevel, title: [*:0]const u8) void {
    _ = wl_proxy_marshal_flags(@ptrCast(toplevel), 2, null, wl_proxy_get_version(@ptrCast(toplevel)), 0, title);
}
```

**Step 2: Commit**

```bash
git add src/window/platform/wayland/bindings.zig
git commit -m "feat: add proxy wrappers for protocol requests"
```

---

### Task 5: Convert connection.zig to use bindings.zig and Drop libc

**Files:**
- Modify: `src/window/platform/wayland/connection.zig`

**Step 1: Replace cImport and std.c**

- Remove `const c = @cImport(...)`, `const wl = ...`, `const xdg = ...`
- Add `const wl = @import("bindings.zig");`
- Rename `xdg_...` calls to use `wl.xdg_...`
- Change `std.c.close` to `std.os.linux.close`
- Change `std.c.ftruncate` to `std.os.linux.ftruncate`
- Change `std.c.munmap` to `std.os.linux.munmap`
- Change `std.c.mmap` to `std.os.linux.mmap` (handle error union with `catch return null`)
- Change `shm_open` to `std.os.linux.shm_open`
- Change `std.c.shm_unlink` to `std.os.linux.shm_unlink`
- Change `c.strcmp` to `std.mem.eql`
- Re-map all callback signatures to match the new strict listener structs.

**Step 2: Remove libc from build.zig**

- Remove `addCSourceFile("...xdg-shell-protocol.c")`
- Remove `link_libc = true` (keep `linkSystemLibrary("wayland-client")`)

**Step 3: Run and verify**

```bash
zig build wayland
```
Ensure the app still displays the window.

**Step 4: Commit**

```bash
git add build.zig src/window/platform/wayland/connection.zig
git commit -m "refactor: complete pure Zig transition"
```
