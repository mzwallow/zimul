# Wayland Window Implementation: Next Steps

This document outlines the prioritized roadmap for completing the Wayland window implementation (`src/window/linux/wayland.zig`).

## 1. Seat & Input (Mouse/Keyboard)
- **Goal:** Receive input events from the user.
- **Tasks:**
  - Bind the `wl_seat` global in the `wl_registry` listener.
  - Listen to `wl_seat` capabilities to detect pointer/keyboard.
  - Call `get_pointer` and `get_keyboard` on the seat.
  - Implement listeners for `wl_pointer` (motion, button, axis) and `wl_keyboard` (key, modifiers).

## 2. Frame Callbacks (Render Loop)
- **Goal:** Synchronize rendering with the monitor's refresh rate to avoid tearing and high CPU usage.
- **Tasks:**
  - Call `wl_surface.frame()` before `commit()`.
  - Implement the `wl_callback` listener.
  - Trigger the next render and request a new frame callback within the listener.

## 3. Handle Toplevel State (TODO)
- **Goal:** Properly respond to window manager state changes (maximize, focus, resize).
- **Tasks:**
  - Implement the `TODO` in `xdgToplevelListener` to parse the `params.states` array.
  - Handle `wl_array` reading in Zig (translate C array of enums to Zig slice).
  - Update internal window state based on `activated`, `maximized`, `resizing`, etc.

## 4. Dynamic Resizing
- **Goal:** Allow the window to be resized by the user or compositor.
- **Tasks:**
  - Update the `xdg_toplevel` `.configure` event to detect dimension changes.
  - Destroy the old `wl_buffer` and `wl_shm_pool`.
  - Reallocate the `memfd` (using `ftruncate` and `mmap`) to the new size.
  - Create a new pool and buffer, attach, and commit.

## 5. Draw Pixels
- **Goal:** Actually show content inside the window instead of uninitialized memory.
- **Tasks:**
  - Cast the `mmap` pointer to `[*]u32` (assuming `xrgb8888`).
  - Write a simple test pattern (e.g., a solid color or gradient) to the buffer before attaching.
