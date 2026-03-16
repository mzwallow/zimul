# Wayland Protocol XML → Zig Translation Guide

## Quick Reference

| XML Element | Zig Type | Example |
|------------|----------|--------|
| `<interface>` | `opaque {}` | `pub const wl_display = opaque {};` |
| `<request>` | `fn` wrapper | `pub fn wl_display_get_registry(...) ?*wl_registry` |
| `<event>` | `struct` listener | `pub const wl_registry_listener = extern struct { ... };` |
| `<enum>` | `enum(u32)` | `pub const WlShmFormat = enum(u32) { xrgb8888 = 1 };` |
| `<arg type="new_id">` | Return `?*Type` | `?*wl_registry` |
| `<arg type="int">` | `i32` | `width: i32` |
| `<arg type="string">` | `[*:0]const u8` | `title: [*:0]const u8` |

## Core Pattern

Wayland protocol requests are **always** implemented as:

```zig
pub fn wl_<interface>_<request>(obj: *<Interface>, args...) ?*<ReturnType> {
    return @ptrCast(wl_proxy_marshal_flags(
        @ptrCast(obj),
        OPCODE,                    // From XML (0-indexed order)
        &<Return>_interface,         // Interface const for new_id returns
        wl_proxy_get_version(@ptrCast(obj)),
        0,                          // Flags (0 for normal requests)
        null,                        // New ID (null for auto-generated)
        ...args,                     // Arguments in XML order
    ));
}
```

## Step-by-Step Translation

### 1. Translate Interface → Opaque Type

**XML:**
```xml
<interface name="wl_display" version="1">
  ...
</interface>
```

**Zig:**
```zig
pub const wl_display = opaque {};
pub extern const wl_display_interface: wl_interface;  // From libwayland-client.so
```

---

### 2. Translate Request → Wrapper Function

**XML:**
```xml
<interface name="wl_display" version="1">
  <request name="get_registry" since="1">
    <arg name="registry" type="new_id" interface="wl_registry"/>
  </request>
</interface>
```

**Zig:**
```zig
// Opcode is implicit: first request = 0, second = 1, etc.
pub const WL_DISPLAY_GET_REGISTRY: u32 = 0;

pub extern const wl_registry_interface: wl_interface;

pub fn wl_display_get_registry(display: *wl_display) ?*wl_registry {
    return @ptrCast(wl_proxy_marshal_flags(
        @ptrCast(display),
        WL_DISPLAY_GET_REGISTRY,
        &wl_registry_interface,
        wl_proxy_get_version(@ptrCast(display)),
        0,
        null,
    ));
}
```

---

### 3. Translate Event → Listener Struct

**XML:**
```xml
<interface name="wl_registry" version="1">
  <event name="global">
    <arg name="name" type="uint"/>
    <arg name="interface" type="string"/>
    <arg name="version" type="uint"/>
  </event>
  <event name="global_remove">
    <arg name="name" type="uint"/>
  </event>
</interface>
```

**Zig:**
```zig
pub const wl_registry_listener = extern struct {
    global: *const fn (
        data: ?*anyopaque,
        registry: ?*wl_registry,
        name: u32,
        interface: [*:0]const u8,
        version: u32,
    ) callconv(.c) void,

    global_remove: *const fn (
        data: ?*anyopaque,
        registry: ?*wl_registry,
        name: u32,
    ) callconv(.c) void,
};
```

---

### 4. Translate Enum → Zig Enum

**XML:**
```xml
<interface name="wl_shm" version="1">
  <enum name="format">
    <entry name="xrgb8888" value="1"/>
  </enum>
</interface>
```

**Zig:**
```zig
pub const WlShmFormat = enum(u16) { xrgb8888 = 1 };
```

---

## Argument Type Mapping

| XML Type | Zig Type | Notes |
|----------|----------|-------|
| `int` | `i32` | Signed 32-bit |
| `uint` | `u32` | Unsigned 32-bit |
| `fixed` | `i32` | 24.8 fixed point |
| `string` | `[*:0]const u8` | Null-terminated C string |
| `object` | `*Interface` | Existing object reference |
| `new_id` | `?*Interface` | Returned by request (nullable) |
| `fd` | `i32` | File descriptor |
| `array` | `*wl_array` | See below |

**Array Example:**

**XML:**
```xml
<arg name="states" type="array"/>
```

**Zig:**
```zig
pub const wl_array = extern struct {
    size: usize,
    alloc: usize,
    data: ?*anyopaque,
};
```

---

## Complete Example: wl_surface

**XML:**
```xml
<interface name="wl_surface" version="4">
  <request name="attach" since="1">
    <arg name="buffer" type="object" interface="wl_buffer" allow-null="true"/>
    <arg name="x" type="int"/>
    <arg name="y" type="int"/>
  </request>

  <request name="commit" since="1">
  </request>
</interface>
```

**Zig:**
```zig
pub const wl_surface = opaque {};
pub extern const wl_surface_interface: wl_interface;
pub const wl_buffer = opaque {};

// Opcodes: attach = 0, commit = 6 (based on XML order)
pub const WL_SURFACE_ATTACH: u32 = 0;
pub const WL_SURFACE_COMMIT: u32 = 6;

pub fn wl_surface_attach(surface: *wl_surface, buffer: ?*wl_buffer, x: i32, y: i32) void {
    _ = wl_proxy_marshal_flags(
        @ptrCast(surface),
        WL_SURFACE_ATTACH,
        null,
        wl_proxy_get_version(@ptrCast(surface)),
        0,
        buffer,
        x,
        y,
    );
}

pub fn wl_surface_commit(surface: *wl_surface) void {
    _ = wl_proxy_marshal_flags(
        @ptrCast(surface),
        WL_SURFACE_COMMIT,
        null,
        wl_proxy_get_version(@ptrCast(surface)),
        0,
    );
}
```

---

## Finding Opcodes

**Method 1: Count in XML**

```xml
<interface name="wl_display">
  <request name="sync"/>      <!-- opcode 0 -->
  <request name="get_registry"/> <!-- opcode 1 -->
</interface>
```

**Method 2: Check Generated Headers**

```c
// From wayland-client-protocol.h
#define WL_DISPLAY_SYNC 0
#define WL_DISPLAY_GET_REGISTRY 1
```

---

## Common Pitfalls

### 1. Forgetting `callconv(.c)`

❌ Wrong:
```zig
global: fn (data: ?*anyopaque, ...) void,
```

✅ Correct:
```zig
global: *const fn (data: ?*anyopaque, ...) callconv(.c) void,
```

### 2. Using `*const` instead of `*` for nullable pointers

❌ Wrong:
```zig
buffer: *const wl_buffer,  // Can't be null
```

✅ Correct:
```zig
buffer: ?*wl_buffer,  // Nullable
```

### 3. Missing `@ptrCast` when passing to C functions

❌ Wrong:
```zig
wl_proxy_marshal_flags(display, ...)
```

✅ Correct:
```zig
wl_proxy_marshal_flags(@ptrCast(display), ...)
```

### 4. Not checking `allow-null` in XML

**XML:**
```xml
<arg name="buffer" type="object" allow-null="true"/>
```

If `allow-null="true"`, use `?*Type`. Otherwise, use `*Type`.

---

## Quick Template

Copy this for new interfaces:

```zig
// XML: <interface name="NAME" version="V">
pub const NAME = opaque {};
pub extern const NAME_interface: wl_interface;

// Opcodes (count requests in order)
pub const NAME_REQUEST_1: u32 = 0;
pub const NAME_REQUEST_2: u32 = 1;

// Request wrapper
pub fn NAME_request(obj: *NAME, arg1: Type1) ?*ReturnType {
    return @ptrCast(wl_proxy_marshal_flags(
        @ptrCast(obj),
        NAME_REQUEST_1,
        &RETURN_TYPE_interface,
        wl_proxy_get_version(@ptrCast(obj)),
        0,
        null,
        arg1,
    ));
}

// Listener struct
pub const NAME_listener = extern struct {
    event1: *const fn (
        data: ?*anyopaque,
        obj: ?*NAME,
        arg1: u32,
    ) callconv(.c) void,
};
```

---

## Resources

- **Protocol XML**: `/usr/share/wayland/wayland.xml`
- **Generated headers**: Use as reference for opcodes
- **Library symbols**: `nm -D /usr/lib/libwayland-client.so`
- **Core functions**: Always `wl_proxy_*`, never protocol-specific functions
