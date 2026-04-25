---
name: zig-developer
description: Use this agent for all tasks in this repository. It provides critical context for Zig 0.16.0, Wayland interop, and build commands.
model: inherit
---

# AGENTS.md - Agent Guidelines for zimul

## Project Overview

**zimul** — low-level Wayland windowing in Zig (v0.16.0+). Infrastructure for Wayland clients + window management. No thick abstractions.

### Key Components
- **Wayland Scanner (`src/wayland-scanner/`):** Parses Wayland protocol XML. Generates type-safe Zig bindings.
- **Window Management (`src/window/`):** Surface creation, event handling (listeners), buffer management.
- **Platform Implementation (`src/window/linux/wayland.zig`):** Direct Wayland client lifecycle.

---

## Build, Lint, Test Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build |
| `zig build run` | Build + run example window |
| `zig build test` | Run tests |
| `zig build check` | Compile-check only |

---

## Code Style

- **Zig 0.16.0 IO:** `std.Io` for type-erased interfaces (`AnyReader`, `AnyWriter`), not old `std.io`.
- **Naming:** `PascalCase` types/structs/enums, `lowerCamelCase` functions, `snake_case` vars.
- **Imports:** `const std = @import("std");` then local modules.
- **Memory:** Explicit allocations + cleanup (`defer`).
- **Wayland Interop:** `extern struct` for listeners, `opaque {}` for Wayland object handles (C ABI).

---

## Agent Notes

1. **Always run** `zig build` or `zig build check` after changes.
2. **Run** `zig build test` when touching tested code.
3. **Use** `zig fmt` on all modified files.
4. **Memory — Streaming Readers:** `arena.dupe()` if data must outlive reader.
5. **C Interop — Double Pointers:** `T **` (C) → `[*]*const T` (Zig) for pointer arrays.
6. **Local Scanner:** `src/wayland-scanner/` internal tool. `build.zig.zon` includes external `wayland` dependency too.
7. **Wayland Marshalling:** `wl_proxy_marshal_flags` needs `null` placeholder for `new_id` (`n`). Signature `niiiiu` → `@as(?*anyopaque, null)` then rest. Untyped `new_id` (e.g. `wl_registry.bind`) → interface name, version, `null`. Essential for ABI.