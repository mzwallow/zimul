---
name: zig-developer
description: Use this agent for all tasks in this repository. It provides critical context for Zig 0.16.0, C interop, and build commands. Always use this when writing, refactoring, or debugging Zig code here.
model: inherit
---

# AGENTS.md - Agent Guidelines for zimul

This document provides guidelines for agentic coding agents working in this repository.

## Project Overview

**zimul** is a Zig project (v0.16.0-dev.2682+) that uses [raylib](https://github.com/raysan5/raylib) for graphics. The project follows standard Zig conventions.

---

## Build, Lint, and Test Commands

| Command | Description |
|---------|-------------|
| `zig build` | Build the project |
| `zig build run` | Build and run the application |
| `zig build test` | Run all tests (module + executable tests) |
| `zig build check` | Compile-check the executable without running |

### Running a Single Test

```bash
zig build test --test-filter "test_name"
# or
zig test src/root.zig
```

### Debugging & Release

```bash
zig build run -Doptimize=Debug
zig build -Doptimize=ReleaseSafe
```

---

## Code Style Guidelines

### General Principles

- Follow Zig's philosophy: explicit, simple, and performant
- Prefer readability over cleverness
- Use Zig's built-in safety features (optionals, error unions)

### Imports

```zig
const std = @import("std");
const zimul = @import("zimul");
const rl = @cImport(@cInclude("raylib.h"));
```

- Use `const` for all imports
- Group: std lib → local → external C imports

### Formatting

- Run `zig fmt` before committing
- Use 4-space indentation

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Functions | lowerCamelCase | `printAnotherMessage` |
| Types/Structs | PascalCase | `MyStruct` |
| Constants | PascalCase | `MaxBufferSize` |
| Variables | lowerCamelCase | `counter` |
| Enums | PascalCase | `.active` |

### Type Annotations

- Always specify types for parameters and return values
- Prefer `[]const u8` for string literals

```zig
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

### Error Handling

- Use error unions (`!T`) for functions that can fail
- Use `try` for propagating, `catch` for defaults

```zig
pub fn openFile(path: []const u8) !std.fs.File {
    return std.fs.cwd().openFile(path, .{});
}
const file = try openFile("data.txt");
defer file.close();
```

### Optional Types

- Use `?T` for nullable values
- Use `orelse` or `if (value) |v|` to unwrap

### Documentation

- Use `///` for public functions, `//!` for file-level
- Document purpose, parameters, return values

### Unused Parameters

```zig
pub fn main(init: std.process.Init) !void {
    _ = init; // autofix pattern
}
```

### Memory Management

- Use allocators explicitly (`std.mem.Allocator`)
- Use `defer` for cleanup

### Testing

- Place tests in the same file using `test` keyword
- Use `std.testing` for assertions

```zig
test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
```

### Project Structure

```
zimul/
├── build.zig          # Build configuration
├── build.zig.zon      # Package manifest
├── src/
│   ├── root.zig       # Library root
│   └── main.zig       # Application entry
└── zig-pkg/           # Dependencies (raylib)
```

### Common Patterns

**C Interop with raylib:**
```zig
const rl = @cImport(@cInclude("raylib.h"));
```

**Window Management:**
```zig
rl.InitWindow(800, 400, "zimul");
defer rl.CloseWindow();
while (!rl.WindowShouldClose()) {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    // rendering
}
```

---

## Notes for Agents

1. **Always run `zig build` or `zig build check`** after making changes
2. **Run `zig build test`** when modifying code with tests
3. **Use `zig fmt`** on all modified files before finishing
4. **Do not commit secrets** - keep API keys/tokens out of the codebase
5. **Always use ZLS** to look up function signatures, types, and completions. Use `zls-mcp_zig_hover`, `zls-mcp_zig_complete`, and `zls-mcp_zig_goto_definition` tools. Never guess signatures or use `grep`/`mgrep` on std library source — always verify with ZLS first.
6. **Always use `mgrep`** for searching local files semantically. Never use `grep` or `find` directly — use `mgrep` instead for all local file content searches.
7. **C Interop: Double Pointers in Zig** - When translating C double pointers (`T **`) to Zig, count the asterisks:
   - `T *` (single pointer) → `[*]T` or `*T` (for single object)
   - `T **` (double pointer) → `[*]*T` (array of pointers), NOT `[*]T` (array of structs)
   - Example: `const struct wl_interface **types` → `types: [*]*const wl_interface`
   - Remember: each level of `*` adds a `*` to the Zig element type
