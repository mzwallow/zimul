---
name: zig-developer
description: Use this agent for all tasks in this repository. It provides critical context for Zig 0.16.0, Wayland interop, and build commands.
model: inherit
---

# AGENTS.md - Agent Guidelines for zimul

## Project Overview

**zimul** is a low-level Wayland windowing implementation in Zig (v0.16.0+). It provides infrastructure for creating Wayland clients and managing windows without relying on thick abstraction layers.

### Key Components
- **Wayland Scanner (`src/wayland-scanner/`):** Custom tool that parses Wayland protocol XML files and generates type-safe Zig bindings.
- **Window Management (`src/window/`):** Abstractions for creating surfaces, handling events (via listeners), and managing buffers.
- **Platform Implementation (`src/window/linux/wayland.zig`):** Direct implementation of the Wayland client lifecycle.

---

## Build, Lint, and Test Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the project |
| `zig build run` | Build and run the example window |
| `zig build test` | Run all tests |
| `zig build check` | Compile-check without running |

---

## Code Style Guidelines

- **Zig 0.16.0 IO:** Use `std.Io` for type-erased interfaces (`AnyReader`, `AnyWriter`) instead of old `std.io` patterns.
- **Naming:** `PascalCase` for types/structs/enums, `lowerCamelCase` for functions, `snake_case` for variables.
- **Imports:** `const std = @import("std");` followed by local modules.
- **Memory Management:** All allocations and system resource cleanup (via `defer`) must be explicit.
- **Wayland Interop:** Use `extern struct` for listeners and `opaque {}` for Wayland object handles to match C-style ABIs.

---

## Notes for Agents

1. **Always run `zig build` or `zig build check`** after making changes.
2. **Run `zig build test`** when modifying code with tests.
3. **Use `zig fmt`** on all modified files.
4. **Memory Management: Streaming Readers** - Use `arena.dupe()` if you need to persist data beyond the reader's lifecycle.
5. **C Interop: Double Pointers** - `T **` (C) -> `[*]*const T` (Zig) for arrays of pointers.
6. **Local Scanner:** `src/wayland-scanner/` is an internal tool. Note that `build.zig.zon` also includes an external `wayland` dependency.
