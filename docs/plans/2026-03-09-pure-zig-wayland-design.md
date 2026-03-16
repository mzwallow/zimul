# Pure Zig Wayland Implementation Design

## 1. Goal
Convert the existing hybrid C/Zig Wayland client into a "Pure Zig" implementation. 
The goal is to eliminate all C headers (`@cImport`), avoid generated `.c`/`.h` protocol files, and remove the dependency on `libc` for system calls, using this as a deep-dive learning exercise into the C ABI, `extern` linking, and the Wayland proxy architecture.

## 2. Approach: Minimal Inline Bindings
Instead of using massive auto-generated files or importing full C headers, we will manually write `extern` bindings for *only* the specific types and functions we use. 

### 2.1 File Structure
- `src/window/platform/wayland/bindings.zig`: A new file containing all raw Wayland structs, opaque types, and `extern "c"` function definitions.
- `src/window/platform/wayland/connection.zig`: The main application logic, which will import `bindings.zig` instead of using `@cImport`.

## 3. Implementation Details

### 3.1 Core Wayland Types
Wayland handles will be represented as Zig opaque types to maintain ABI stability and prevent accidental field access:
```zig
pub const wl_display = opaque {};
pub const wl_registry = opaque {};
pub const wl_compositor = opaque {};
pub const wl_surface = opaque {};
```

### 3.2 Callbacks (Listeners)
Callback structures (like `wl_registry_listener`) will be defined as strict `extern struct` types containing function pointers using the `callconv(.c)` calling convention, ensuring binary compatibility with `libwayland-client.so`.

### 3.3 Core Function Linking
We will declare `extern "c"` functions mapped directly to the shared library.
```zig
pub extern "c" fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
```
The linker flag `wayland_exe.root_module.linkSystemLibrary("wayland-client", .{})` in `build.zig` will remain, as we are still using the C library's implementation for socket management and event queuing.

### 3.4 Protocol Message Marshalling
We will delete the generated `xdg-shell-protocol.c` file. 
Instead of calling generated C functions to send protocol requests (like `xdg_surface_get_toplevel`), we will manually wrap `wl_proxy_marshal_flags`.
We will extract the required integer opcodes (e.g., `get_registry` is opcode 1) directly from the Wayland XML specifications and write safe Zig wrappers around `wl_proxy_marshal_flags` to send these messages.

### 3.5 Removing `libc` for POSIX/System calls
We will replace all `std.c.*` functions with their direct Linux syscall equivalents:
- `std.c.close` -> `std.os.linux.close`
- `std.c.ftruncate` -> `std.os.linux.ftruncate`
- `std.c.mmap` -> `std.os.linux.mmap` (handling the Zig error union instead of `MAP_FAILED`)
- `std.c.shm_unlink` -> `std.os.linux.shm_unlink`
This allows us to drop the `link_libc = true` flag from the build script for the Wayland backend.

## 4. Execution Steps
1. Create `bindings.zig` and define the opaque types, listener structs, and core `extern "c"` functions.
2. Implement the `wl_proxy_marshal_flags` wrappers for compositor, SHM, and XDG shell operations.
3. Update `connection.zig` to import `bindings.zig` and remove all `@cImport` blocks.
4. Replace all `std.c` POSIX calls in `connection.zig` with `std.os.linux` equivalents.
5. Update `build.zig` to remove `xdg-shell-protocol.c`, the include paths, and `link_libc = true`.
6. Compile, run, and verify the window still renders correctly on Hyprland.
