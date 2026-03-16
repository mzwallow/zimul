# Zig build run black screen window issue

**Session ID:** ses_33658a2b7ffeJVzrLAke2ZjZLE
**Created:** 3/8/2026, 1:55:14 AM
**Updated:** 3/8/2026, 5:18:23 PM

---

## Assistant (Build · claude-sonnet-4-6 · 7.0s)

GLFW is using GLX (not EGL) for the context — and `glXSwapBuffers` is the swap call. The `unsetenv` should fix the GLX vendor. But it's still black even when running with `__GLX_VENDOR_LIBRARY_NAME=` from the shell too.

Let me check what `glxgears` is actually doing differently — it uses direct rendering:

**Tool: bash**

**Input:**
```json
{
  "command": "glxinfo 2>/dev/null | grep -i \"direct\\|render\\|vendor\\|server glx\\|client glx\" | head -15",
  "description": "Check GLX rendering mode and vendor info"
}
```

**Output:**
```
direct rendering: Yes
server glx vendor string: SGI
server glx version string: 1.4
server glx extensions:
client glx vendor string: NVIDIA Corporation
client glx version string: 1.4
client glx extensions:
OpenGL vendor string: NVIDIA Corporation
OpenGL renderer string: NVIDIA GeForce RTX 4070/PCIe/SSE2
    GL_AMD_multi_draw_indirect, GL_AMD_seamless_cubemap_per_texture, 
    GL_ARB_conditional_render_inverted, GL_ARB_conservative_depth, 
    GL_ARB_direct_state_access, GL_ARB_draw_buffers, 
    GL_ARB_draw_indirect, GL_ARB_draw_instanced, GL_ARB_enhanced_layouts, 
    GL_ARB_indirect_parameters, GL_ARB_instanced_arrays, 
    GL_ARB_map_buffer_range, GL_ARB_multi_bind, GL_ARB_multi_draw_indirect, 

```

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"GLFW_CONTEXT_CREATION_API\\|EGL\\|egl\\|osmesa\\|NATIVE_CONTEXT\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/external/glfw/src/x11_window.c 2>/dev/null | head -20",
  "description": "Check what context API GLFW uses on X11"
}
```

**Output:**
```
1843:// Inspired by fghGetWindowProperty from freeglut
1970:        if (ctxconfig->source == GLFW_NATIVE_CONTEXT_API)
1977:        else if (ctxconfig->source == GLFW_EGL_CONTEXT_API)
1979:            if (!_glfwInitEGL())
1981:            if (!_glfwChooseVisualEGL(wndconfig, ctxconfig, fbconfig, &visual, &depth))
2002:        if (ctxconfig->source == GLFW_NATIVE_CONTEXT_API)
2007:        else if (ctxconfig->source == GLFW_EGL_CONTEXT_API)
2009:            if (!_glfwCreateContextEGL(window, ctxconfig, fbconfig))
3088:EGLenum _glfwGetEGLPlatformX11(EGLint** attribs)
3090:    if (_glfw.egl.ANGLE_platform_angle)
3094:        if (_glfw.egl.ANGLE_platform_angle_opengl)
3097:                type = EGL_PLATFORM_ANGLE_TYPE_OPENGL_ANGLE;
3100:        if (_glfw.egl.ANGLE_platform_angle_vulkan)
3103:                type = EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE;
3108:            *attribs = _glfw_calloc(5, sizeof(EGLint));
3109:            (*attribs)[0] = EGL_PLATFORM_ANGLE_TYPE_ANGLE;
3111:            (*attribs)[2] = EGL_PLATFORM_ANGLE_NATIVE_PLATFORM_TYPE_ANGLE;
3112:            (*attribs)[3] = EGL_PLATFORM_X11_EXT;
3113:            (*attribs)[4] = EGL_NONE;
3114:            return EGL_PLATFORM_ANGLE_ANGLE;

```

---

## Assistant (Build · claude-sonnet-4-6 · 7.9s)

Key finding: **`client glx vendor string: NVIDIA Corporation`** — XWayland is using the NVIDIA GLX client even though we unset `__GLX_VENDOR_LIBRARY_NAME`. This means the NVIDIA GLX ICD is being loaded via a different mechanism (likely `GLVND` dispatch). And `server glx vendor string: SGI` — the XWayland X server side is SGI (Mesa), but the client is NVIDIA.

This mismatch — NVIDIA client GLX talking to a Mesa/SGI XWayland server — is exactly the root cause of the black screen. The NVIDIA GLX client can't present frames to XWayland's software compositor.

The real fix: force GLFW to use **EGL** instead of GLX for context creation on X11. EGL on XWayland works correctly because it goes through the DRM/KMS path. Let me check how to set this in raylib:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"GLFW_CONTEXT_CREATION_API\\|EGL_CONTEXT_API\\|glfwWindowHint\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/rcore.c 2>/dev/null | head -20",
  "description": "Check how raylib sets GLFW context API hints"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 4.3s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -rn \"GLFW_CONTEXT_CREATION_API\\|EGL_CONTEXT_API\\|glfwWindowHint\\|WindowHint\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/ 2>/dev/null | grep -v \"external\" | head -20",
  "description": "Check raylib rglfw.c for window hints"
}
```

**Output:**
```
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1208:    glfwDefaultWindowHints(); // Set default windows hints
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1209:    // glfwWindowHint(GLFW_RED_BITS, 8);             // Framebuffer red color component bits
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1210:    // glfwWindowHint(GLFW_GREEN_BITS, 8);           // Framebuffer green color component bits
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1211:    // glfwWindowHint(GLFW_BLUE_BITS, 8);            // Framebuffer blue color component bits
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1212:    // glfwWindowHint(GLFW_ALPHA_BITS, 8);           // Framebuffer alpha color component bits
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1213:    // glfwWindowHint(GLFW_DEPTH_BITS, 24);          // Depthbuffer bits
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1214:    // glfwWindowHint(GLFW_REFRESH_RATE, 0);         // Refresh rate for fullscreen window
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1215:    // glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API); // OpenGL API to use. Alternative: GLFW_OPENGL_ES_API
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1216:    // glfwWindowHint(GLFW_AUX_BUFFERS, 0);          // Number of auxiliar buffers
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1219:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_HIDDEN)) glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // Visible window
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1220:    else glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE); // Window initially hidden
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1222:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_UNDECORATED)) glfwWindowHint(GLFW_DECORATED, GLFW_FALSE); // Border and buttons on Window
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1223:    else glfwWindowHint(GLFW_DECORATED, GLFW_TRUE); // Decorated window
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1225:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_RESIZABLE)) glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE); // Resizable window
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1226:    else glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE); // Avoid window being resizable
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1234:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_UNFOCUSED)) glfwWindowHint(GLFW_FOCUSED, GLFW_FALSE);
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1235:    else glfwWindowHint(GLFW_FOCUSED, GLFW_TRUE);
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1237:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_TOPMOST)) glfwWindowHint(GLFW_FLOATING, GLFW_TRUE);
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1238:    else glfwWindowHint(GLFW_FLOATING, GLFW_FALSE);
/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_web.c:1245:    //if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_HIGHDPI)) glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);

```

---

## Assistant (Build · claude-sonnet-4-6 · 3.8s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -rn \"GLFW_CONTEXT_CREATION_API\\|EGL_CONTEXT_API\\|glfwWindowHint\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c 2>/dev/null | head -20",
  "description": "Check desktop GLFW platform for context hints"
}
```

**Output:**
```
1461:    //glfwWindowHint(GLFW_RED_BITS, 8);             // Framebuffer red color component bits
1462:    //glfwWindowHint(GLFW_GREEN_BITS, 8);           // Framebuffer green color component bits
1463:    //glfwWindowHint(GLFW_BLUE_BITS, 8);            // Framebuffer blue color component bits
1464:    //glfwWindowHint(GLFW_ALPHA_BITS, 8);           // Framebuffer alpha color component bits
1465:    //glfwWindowHint(GLFW_DEPTH_BITS, 24);          // Depthbuffer bits
1466:    //glfwWindowHint(GLFW_REFRESH_RATE, 0);         // Refresh rate for fullscreen window
1467:    //glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API); // OpenGL API to use. Alternative: GLFW_OPENGL_ES_API
1468:    //glfwWindowHint(GLFW_AUX_BUFFERS, 0);          // Number of auxiliar buffers
1473:    glfwWindowHint(GLFW_AUTO_ICONIFY, 0);
1479:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_HIDDEN)) glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // Visible window
1480:    else glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);     // Window initially hidden
1482:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_UNDECORATED)) glfwWindowHint(GLFW_DECORATED, GLFW_FALSE); // Border and buttons on Window
1483:    else glfwWindowHint(GLFW_DECORATED, GLFW_TRUE);   // Decorated window
1485:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_RESIZABLE)) glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE); // Resizable window
1486:    else glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);  // Avoid window being resizable
1494:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_UNFOCUSED)) glfwWindowHint(GLFW_FOCUSED, GLFW_FALSE);
1495:    else glfwWindowHint(GLFW_FOCUSED, GLFW_TRUE);
1497:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_TOPMOST)) glfwWindowHint(GLFW_FLOATING, GLFW_TRUE);
1498:    else glfwWindowHint(GLFW_FLOATING, GLFW_FALSE);
1501:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_TRANSPARENT)) glfwWindowHint(GLFW_TRANSPARENT_FRAMEBUFFER, GLFW_TRUE);     // Transparent framebuffer

```

---

## Assistant (Build · claude-sonnet-4-6 · 8.9s)

Raylib never sets `GLFW_CONTEXT_CREATION_API` — it defaults to `GLFW_NATIVE_CONTEXT_API` which means GLX. We need to force it to `GLFW_EGL_CONTEXT_API`. The cleanest way to do this without patching vendored code is to call `glfwInitHint` / `glfwWindowHint` before `initWindow` via the C FFI, since raylib calls `glfwDefaultWindowHints()` which resets per-window hints but doesn't reset the init hint for context API.

Actually, `GLFW_CONTEXT_CREATION_API` is a **window hint** (set per-window via `glfwWindowHint`), and raylib calls `glfwDefaultWindowHints()` before setting its own hints — so any hint we set beforehand would be wiped. We need to patch raylib's `rcore_desktop_glfw.c` to add this hint, or call it after `glfwDefaultWindowHints` but before `glfwCreateWindow`.

The simplest approach: patch the vendored `rcore_desktop_glfw.c` directly:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"glfwDefaultWindowHints\\|GLFW_CONTEXT_CREATION\\|glfwWindowHint(GLFW_VISIBLE\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c | head -10",
  "description": "Find where to insert the EGL hint in rcore_desktop_glfw.c"
}
```

**Output:**
```
1460:    glfwDefaultWindowHints();                       // Set default windows hints
1479:    if (FLAG_IS_SET(CORE.Window.flags, FLAG_WINDOW_HIDDEN)) glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // Visible window
1480:    else glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);     // Window initially hidden
1580:        glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
1587:        glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);

```

---

## Assistant (Build · claude-sonnet-4-6 · 21.5s)

It already sets `GLFW_EGL_CONTEXT_API` in some cases — let me see what condition triggers it:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c",
  "offset": 1570,
  "limit": 30
}
```

**Output:**
```
<path>/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c</path>
<type>file</type>
<content>1570:         glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE);
1571: #if RLGL_ENABLE_OPENGL_DEBUG_CONTEXT
1572:         glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE);   // Enable OpenGL Debug Context
1573: #endif
1574:     }
1575:     else if (rlGetVersion() == RL_OPENGL_ES_20)                 // Request OpenGL ES 2.0 context
1576:     {
1577:         glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
1578:         glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
1579:         glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
1580:         glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
1581:     }
1582:     else if (rlGetVersion() == RL_OPENGL_ES_30)                 // Request OpenGL ES 3.0 context
1583:     {
1584:         glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
1585:         glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
1586:         glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
1587:         glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);
1588:     }
1589: 
1590:     // NOTE: GLFW 3.4+ defers initialization of the Joystick subsystem on the first call to any Joystick related functions
1591:     // Forcing this initialization here avoids doing it on PollInputEvents() called by EndDrawing() after first frame has been drawn
1592:     // The initialization will still happen and possible delays still occur, but before the window is shown, which is a nicer experience
1593:     // REF: https://github.com/raysan5/raylib/issues/1554
1594:     glfwSetJoystickCallback(NULL);
1595: 
1596:     if ((CORE.Window.screen.width == 0) || (CORE.Window.screen.height == 0)) FLAG_SET(CORE.Window.flags, FLAG_FULLSCREEN_MODE);
1597: 
1598:     // Init window in fullscreen mode if requested
1599:     // NOTE: Keeping original screen size for toggle

(Showing lines 1570-1599 of 2201. Use offset=1600 to continue.)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.0s)

EGL is only used for OpenGL ES. For regular OpenGL 3.3 (what raylib uses by default), it uses GLX. The fix is simple — add `GLFW_CONTEXT_CREATION_API = GLFW_EGL_CONTEXT_API` for the regular OpenGL path too. Let me find that section:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c",
  "offset": 1540,
  "limit": 36
}
```

**Output:**
```
<path>/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c</path>
<type>file</type>
<content>1540:     }
1541: 
1542:     // NOTE: When asking for an OpenGL context version, most drivers provide the highest supported version
1543:     // with backward compatibility to older OpenGL versions
1544:     // For example, if using OpenGL 1.1, driver can provide a 4.3 backwards compatible context
1545: 
1546:     // Check selection OpenGL version
1547:     if (rlGetVersion() == RL_OPENGL_21)
1548:     {
1549:         glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);          // Choose OpenGL major version (just hint)
1550:         glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);          // Choose OpenGL minor version (just hint)
1551:     }
1552:     else if (rlGetVersion() == RL_OPENGL_33)
1553:     {
1554:         glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);          // Choose OpenGL major version (just hint)
1555:         glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)
1556:         glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // Profiles Hint: Only 3.3 and above!
1557:                                                                        // Values: GLFW_OPENGL_CORE_PROFILE, GLFW_OPENGL_ANY_PROFILE, GLFW_OPENGL_COMPAT_PROFILE
1558: #if defined(__APPLE__)
1559:         glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);  // OSX Requires forward compatibility
1560: #else
1561:         glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE); // Forward Compatibility Hint: Only 3.3 and above!
1562: #endif
1563:         //glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE); // Request OpenGL DEBUG context
1564:     }
1565:     else if (rlGetVersion() == RL_OPENGL_43)
1566:     {
1567:         glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);          // Choose OpenGL major version (just hint)
1568:         glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)
1569:         glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
1570:         glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE);
1571: #if RLGL_ENABLE_OPENGL_DEBUG_CONTEXT
1572:         glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE);   // Enable OpenGL Debug Context
1573: #endif
1574:     }
1575:     else if (rlGetVersion() == RL_OPENGL_ES_20)                 // Request OpenGL ES 2.0 context

(Showing lines 1540-1575 of 2201. Use offset=1576 to continue.)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 7.2s)

There it is. I need to add `GLFW_CONTEXT_CREATION_API = GLFW_EGL_CONTEXT_API` for `RL_OPENGL_33` (and 21, 43) on Linux. But rather than patching all the raylib vendored source, there's a much cleaner approach: check if this is also stored in the second vendored copy, and use a compile-time macro.

Actually, the cleanest fix that doesn't touch vendored code: use `GLFW_OPENGL_ES_API` isn't an option. But we can add a C macro definition `_GLFW_USE_EGLCONTEXT` or similar... Let me check:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -rn \"_GLFW_USE_EGL\\|USE_EGL\\|GLFW_USE_EGL\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/external/glfw/ 2>/dev/null | head -10",
  "description": "Check for EGL compile-time macro in GLFW"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 10.4s)

No macro. The only option without touching vendored code is to patch `rcore_desktop_glfw.c`. Since this is a local path dependency (`/home/mzwallow/Development/raylib-zig`), this is your own copy — patching it is fine:

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c",
  "oldString": "    else if (rlGetVersion() == RL_OPENGL_33)\n    {\n        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);          // Choose OpenGL major version (just hint)\n        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)\n        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // Profiles Hint: Only 3.3 and above!\n                                                                       // Values: GLFW_OPENGL_CORE_PROFILE, GLFW_OPENGL_ANY_PROFILE, GLFW_OPENGL_COMPAT_PROFILE\n#if defined(__APPLE__)\n        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);  // OSX Requires forward compatibility\n#else\n        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE); // Forward Compatibility Hint: Only 3.3 and above!\n#endif\n        //glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE); // Request OpenGL DEBUG context\n    }",
  "newString": "    else if (rlGetVersion() == RL_OPENGL_33)\n    {\n        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);          // Choose OpenGL major version (just hint)\n        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);          // Choose OpenGL minor version (just hint)\n        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // Profiles Hint: Only 3.3 and above!\n                                                                       // Values: GLFW_OPENGL_CORE_PROFILE, GLFW_OPENGL_ANY_PROFILE, GLFW_OPENGL_COMPAT_PROFILE\n#if defined(__APPLE__)\n        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);  // OSX Requires forward compatibility\n#else\n        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_FALSE); // Forward Compatibility Hint: Only 3.3 and above!\n#endif\n        //glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GLFW_TRUE); // Request OpenGL DEBUG context\n#if defined(_GLFW_X11)\n        // On XWayland (NVIDIA+Wayland), GLX client/server vendor mismatch causes black windows.\n        // Force EGL context creation to bypass GLX entirely and render correctly.\n        glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);\n#endif\n    }"
}
```

**Output:**
```
Edit applied successfully.

LSP errors detected in this file, please fix:
<diagnostics file="/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c">
ERROR [119:8] Unknown type name 'CoreData'
ERROR [167:1] Unknown type name 'bool'
ERROR [170:17] Use of undeclared identifier 'true'
ERROR [176:10] Call to undeclared function 'FLAG_IS_SET'; ISO C99 and later do not support implicit function declarations
ERROR [176:41] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [184:28] Call to undeclared function 'GetCurrentMonitor'; ISO C99 and later do not support implicit function declarations
ERROR [195:37] Use of undeclared identifier 'Point'
ERROR [199:13] Call to undeclared function 'FLAG_SET'; ISO C99 and later do not support implicit function declarations
ERROR [199:41] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [210:14] Call to undeclared function 'TRACELOG'; ISO C99 and later do not support implicit function declarations
ERROR [210:23] Use of undeclared identifier 'LOG_WARNING'
ERROR [220:9] Call to undeclared function 'FLAG_CLEAR'; ISO C99 and later do not support implicit function declarations
ERROR [220:39] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [225:44] Use of undeclared identifier 'FLAG_WINDOW_HIGHDPI'
ERROR [227:13] Use of undeclared identifier 'Vector2'
ERROR [228:80] Use of undeclared identifier 'scaleDpi'
ERROR [229:82] Use of undeclared identifier 'scaleDpi'
ERROR [247:40] Use of undeclared identifier 'FLAG_VSYNC_HINT'
ERROR [255:9] Call to undeclared function 'FLAG_IS_SET'; ISO C99 and later do not support implicit function declarations
ERROR [1:1] Too many errors emitted, stopping now
</diagnostics>
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.9s)

The LSP errors are just the LSP not having the right include context — the actual build should be fine. Let me verify:

**Tool: bash**

**Input:**
```json
{
  "command": "zig build 2>&1",
  "description": "Build with EGL context hint for X11"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 8.7s)

**Tool: bash**

**Input:**
```json
{
  "command": "timeout 5 /home/mzwallow/Development/zimul/zig-out/bin/zimul 2>&1 | grep -i \"egl\\|glx\\|context\\|error\\|warning\" | head -20",
  "description": "Run and check for EGL context creation messages"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 8.7s)

No errors. Now try `zig build run` — the window should now render correctly. GLFW will use EGL instead of GLX on X11, which works properly with XWayland on NVIDIA+Hyprland.

Also, now that the context API fix is in the vendored code, we can clean up the `unsetenv` workaround from `main.zig` since it wasn't the right fix:

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/src/main.zig",
  "oldString": "const std = @import(\"std\");\nconst Io = std.Io;\n\nconst zimul = @import(\"zimul\");\nconst rl = @import(\"raylib\");\nconst c = @cImport(@cInclude(\"stdlib.h\"));\n\npub fn main() !void {\n    // Unset __GLX_VENDOR_LIBRARY_NAME so XWayland GLX works correctly on NVIDIA+Hyprland.\n    // When set to \"nvidia\", the NVIDIA GLX vendor intercepts XWayland's EGL/GLX path and\n    // produces a black window. Unsetting it lets the system pick the correct vendor.\n    _ = c.unsetenv(\"__GLX_VENDOR_LIBRARY_NAME\");\n\n    rl.setTraceLogLevel(.all);",
  "newString": "const std = @import(\"std\");\nconst Io = std.Io;\n\nconst zimul = @import(\"zimul\");\nconst rl = @import(\"raylib\");\n\npub fn main() !void {\n    rl.setTraceLogLevel(.all);"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.3s)

**Tool: bash**

**Input:**
```json
{
  "command": "zig build 2>&1",
  "description": "Final build check"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 5.2s)

The fix: patched `rcore_desktop_glfw.c` in your local raylib-zig dependency to add `glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API)` inside the `#if defined(_GLFW_X11)` block for the OpenGL 3.3 path. This forces GLFW to use EGL instead of GLX when running on X11/XWayland, bypassing the NVIDIA GLX client/server vendor mismatch that caused the black screen.

---

## User

still got black screen

---

## Assistant (Build · claude-sonnet-4-6 · 10.5s)

Let me check if EGL is actually being used now:

**Tool: bash**

**Input:**
```json
{
  "command": "timeout 5 /home/mzwallow/Development/zimul/zig-out/bin/zimul 2>&1",
  "description": "Run binary with full output"
}
```

**Output:**
```
INFO: Initializing raylib 6.0
INFO: Platform backend: DESKTOP (GLFW)
INFO: Supported raylib modules:
INFO:     > rcore:..... loaded (mandatory)
INFO:     > rlgl:...... loaded (mandatory)
INFO:     > rshapes:... loaded (optional)
INFO:     > rtextures:. loaded (optional)
INFO:     > rtext:..... loaded (optional)
INFO:     > rmodels:... loaded (optional)
INFO:     > raudio:.... loaded (optional)
INFO: DISPLAY: Device initialized successfully 
INFO:     > Display size: 1920 x 1080
INFO:     > Screen size:  800 x 400
INFO:     > Render size:  800 x 400
INFO:     > Viewport offsets: 0, 0
INFO: GLAD: OpenGL extensions loaded successfully
INFO: GL: Supported extensions count: 401
INFO: GL: OpenGL device information:
INFO:     > Vendor:   NVIDIA Corporation
INFO:     > Renderer: NVIDIA GeForce RTX 4070/PCIe/SSE2
INFO:     > Version:  3.3.0 NVIDIA 590.48.01
INFO:     > GLSL:     3.30 NVIDIA via Cg compiler
INFO: GL: VAO extension detected, VAO functions loaded successfully
INFO: GL: NPOT textures extension detected, full NPOT textures supported
INFO: GL: DXT compressed textures supported
INFO: GL: ETC2/EAC compressed textures supported
INFO: PLATFORM: DESKTOP (GLFW - X11): Initialized successfully
DEBUG: TEXTURE: Load mipmap level 0 (1 x 1), size: 4, offset: 0
INFO: TEXTURE: [ID 1] Texture loaded successfully (1x1 | R8G8B8A8 | 1 mipmaps)
INFO: TEXTURE: [ID 1] Default texture loaded successfully
INFO: SHADER: [ID 1] Vertex shader compiled successfully
INFO: SHADER: [ID 2] Fragment shader compiled successfully
INFO: SHADER: [ID 3] Program shader loaded successfully
INFO: SHADER: [ID 3] Default shader loaded successfully
INFO: RLGL: Render batch vertex buffers loaded successfully in RAM (CPU)
INFO: RLGL: Render batch vertex buffers loaded successfully in VRAM (GPU)
INFO: RLGL: Default OpenGL state initialized successfully
DEBUG: TEXTURE: Load mipmap level 0 (128 x 128), size: 32768, offset: 0
INFO: TEXTURE: [ID 2] Texture loaded successfully (128x128 | GRAY_ALPHA | 1 mipmaps)
INFO: FONT: Default font loaded successfully (224 glyphs)
INFO: SYSTEM: Working Directory: /home/mzwallow/Development/zimul
INFO: TIMER: Target time per frame: 6.944 milliseconds

```

---

## Assistant (Build · claude-sonnet-4-6 · 6.6s)

Still using GLX (no EGL message). The `_GLFW_X11` macro isn't defined when compiling via Zig's build system. Let me check:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"_GLFW_X11\\|addCMacro\\|GLFW_X11\\|GLFW_WAYLAND\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig | head -20",
  "description": "Check how _GLFW_X11 macro is defined"
}
```

**Output:**
```
85:        .glfw => raylib.root_module.addCMacro("PLATFORM_DESKTOP_GLFW", ""),
86:        .rgfw => raylib.root_module.addCMacro("PLATFORM_DESKTOP_RGFW", ""),
87:        .sdl => raylib.root_module.addCMacro("PLATFORM_DESKTOP_SDL", ""),
88:        .android => raylib.root_module.addCMacro("PLATFORM_ANDROID", ""),
224:        raylib.root_module.addCMacro(options.opengl_version.toCMacroStr(), "");
245:                    raylib.root_module.addCMacro("GRAPHICS_API_OPENGL_ES2", "");
252:                raylib.root_module.addCMacro("PLATFORM_DRM", "");
253:                raylib.root_module.addCMacro("EGL_NO_X11", "");
254:                raylib.root_module.addCMacro("DEFAULT_BATCH_BUFFER_ELEMENT", "");
304:                    raylib.root_module.addCMacro("GRAPHICS_API_OPENGL_ES2", "");
313:                    raylib.root_module.addCMacro("_GLFW_X11", "");
333:                    raylib.root_module.addCMacro("_GLFW_WAYLAND", "");
391:            raylib.root_module.addCMacro("PLATFORM_WEB", "");
393:                raylib.root_module.addCMacro("GRAPHICS_API_OPENGL_ES3", "");
613:                    exe_mod.addCMacro("PLATFORM_DESKTOP", "");
622:                    exe_mod.addCMacro("PLATFORM_DESKTOP", "");
632:                    exe_mod.addCMacro("PLATFORM_DESKTOP", "");

```

---

## Assistant (Build · claude-sonnet-4-6 · 17.9s)

`_GLFW_X11` is defined at line 313 — but only conditionally. Let me check what condition wraps it:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig",
  "offset": 305,
  "limit": 40
}
```

**Output:**
```
<path>/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig</path>
<type>file</type>
<content>305:                 }
306:                 raylib.root_module.linkSystemLibrary("EGL", .{});
307: 
308:                 setDesktopPlatform(raylib, .android);
309:             } else {
310:                 try c_source_files.append(b.allocator, "src/rglfw.c");
311: 
312:                 if (options.linux_display_backend == .X11 or options.linux_display_backend == .Both) {
313:                     raylib.root_module.addCMacro("_GLFW_X11", "");
314:                     raylib.root_module.linkSystemLibrary("GLX", .{});
315:                     raylib.root_module.linkSystemLibrary("X11", .{});
316:                     raylib.root_module.linkSystemLibrary("Xcursor", .{});
317:                     raylib.root_module.linkSystemLibrary("Xext", .{});
318:                     raylib.root_module.linkSystemLibrary("Xfixes", .{});
319:                     raylib.root_module.linkSystemLibrary("Xi", .{});
320:                     raylib.root_module.linkSystemLibrary("Xinerama", .{});
321:                     raylib.root_module.linkSystemLibrary("Xrandr", .{});
322:                     raylib.root_module.linkSystemLibrary("Xrender", .{});
323:                 }
324: 
325:                 if (options.linux_display_backend == .Wayland or options.linux_display_backend == .Both) {
326:                     _ = b.findProgram(&.{"wayland-scanner"}, &.{}) catch {
327:                         std.log.err(
328:                             \\ `wayland-scanner` may not be installed on the system.
329:                             \\ You can switch to X11 in your `build.zig` by changing `Options.linux_display_backend`
330:                         , .{});
331:                         @panic("`wayland-scanner` not found");
332:                     };
333:                     raylib.root_module.addCMacro("_GLFW_WAYLAND", "");
334:                     raylib.root_module.linkSystemLibrary("EGL", .{});
335:                     raylib.root_module.linkSystemLibrary("wayland-client", .{});
336:                     raylib.root_module.linkSystemLibrary("xkbcommon", .{});
337:                     waylandGenerate(b, raylib, "wayland.xml", "wayland-client-protocol");
338:                     waylandGenerate(b, raylib, "xdg-shell.xml", "xdg-shell-client-protocol");
339:                     waylandGenerate(b, raylib, "xdg-decoration-unstable-v1.xml", "xdg-decoration-unstable-v1-client-protocol");
340:                     waylandGenerate(b, raylib, "viewporter.xml", "viewporter-client-protocol");
341:                     waylandGenerate(b, raylib, "relative-pointer-unstable-v1.xml", "relative-pointer-unstable-v1-client-protocol");
342:                     waylandGenerate(b, raylib, "pointer-constraints-unstable-v1.xml", "pointer-constraints-unstable-v1-client-protocol");
343:                     waylandGenerate(b, raylib, "fractional-scale-v1.xml", "fractional-scale-v1-client-protocol");
344:                     waylandGenerate(b, raylib, "xdg-activation-v1.xml", "xdg-activation-v1-client-protocol");

(Showing lines 305-344 of 691. Use offset=345 to continue.)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 8.0s)

`_GLFW_X11` IS defined (line 313) and `libGLX` is linked (line 314). So our `#if defined(_GLFW_X11)` patch should have taken effect. But the output still says it initialized with GLFW-X11 and the GL vendor is still NVIDIA via GLX.

Let me check if EGL is actually available and if the hint actually switches context creation:

**Tool: bash**

**Input:**
```json
{
  "command": "ls /usr/lib/libEGL* 2>/dev/null && pkg-config --libs egl 2>/dev/null",
  "description": "Check EGL library availability"
}
```

**Output:**
```
/usr/lib/libEGL_mesa.so
/usr/lib/libEGL_mesa.so.0
/usr/lib/libEGL_mesa.so.0.0.0
/usr/lib/libEGL_nvidia.so
/usr/lib/libEGL_nvidia.so.0
/usr/lib/libEGL_nvidia.so.590.48.01
/usr/lib/libEGL.so
/usr/lib/libEGL.so.1
/usr/lib/libEGL.so.1.1.0
-lEGL

```

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"GLFW_EGL_CONTEXT_API\\|egl_context\\|_glfwInitEGL\\|eglCreateContext\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/external/glfw/src/x11_window.c 2>/dev/null | head -10",
  "description": "Check if EGL context API is supported on X11 in GLFW"
}
```

**Output:**
```
1977:        else if (ctxconfig->source == GLFW_EGL_CONTEXT_API)
1979:            if (!_glfwInitEGL())
2007:        else if (ctxconfig->source == GLFW_EGL_CONTEXT_API)

```

---

## Assistant (Build · claude-sonnet-4-6 · 8.1s)

EGL is available. The patch should work — but maybe the `.zig-cache` is stale and our modified `rcore_desktop_glfw.c` isn't being recompiled. Let me force a clean rebuild:

**Tool: bash**

**Input:**
```json
{
  "command": "rm -rf /home/mzwallow/Development/zimul/.zig-cache && zig build 2>&1",
  "description": "Clean cache and rebuild"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 8.6s)

**Tool: bash**

**Input:**
```json
{
  "command": "timeout 5 /home/mzwallow/Development/zimul/zig-out/bin/zimul 2>&1 | grep -i \"egl\\|glx\\|context\\|vendor\\|version\"",
  "description": "Run fresh binary and check context info"
}
```

**Output:**
```
INFO:     > Vendor:   NVIDIA Corporation
INFO:     > Version:  3.3.0 NVIDIA 590.48.01

```

---

## Assistant (Build · claude-sonnet-4-6 · 4.7s)

Still GLX + NVIDIA. Let me verify our patch actually compiled in:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -c \"GLFW_EGL_CONTEXT_API\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c",
  "description": "Verify patch is in source file"
}
```

**Output:**
```
3

```

**Tool: bash**

**Input:**
```json
{
  "command": "strings /home/mzwallow/Development/zimul/zig-out/bin/zimul | grep -i \"egl\\|EGL_CONTEXT\" | head -10",
  "description": "Check if EGL strings are in the binary"
}
```

**Output:**
```
getEGLErrorString
extensionSupportedEGL
chooseEGLConfig
.L__PRETTY_FUNCTION__._glfwCreateContextEGL
makeContextCurrentEGL
swapBuffersEGL
swapIntervalEGL
getProcAddressEGL
destroyContextEGL
getEGLConfigAttrib

```

---

## Assistant (Build · claude-sonnet-4-6 · 4.2s)

EGL code is compiled in. The hint is being set but GLFW is falling back to GLX. The issue is that `GLFW_EGL_CONTEXT_API` on X11 requires `libEGL` to be linked — which it isn't in the X11 path. Let me check:

**Tool: bash**

**Input:**
```json
{
  "command": "ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul | grep -i egl",
  "description": "Check if binary links libEGL"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 4.5s)

No `libEGL` linked — that's why EGL init fails and GLFW silently falls back to GLX. The X11 path in raylib's build only links `libGLX`, not `libEGL`. Fix it in `build.zig` of the raylib dependency:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig",
  "offset": 312,
  "limit": 12
}
```

**Output:**
```
<path>/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig</path>
<type>file</type>
<content>312:                 if (options.linux_display_backend == .X11 or options.linux_display_backend == .Both) {
313:                     raylib.root_module.addCMacro("_GLFW_X11", "");
314:                     raylib.root_module.linkSystemLibrary("GLX", .{});
315:                     raylib.root_module.linkSystemLibrary("X11", .{});
316:                     raylib.root_module.linkSystemLibrary("Xcursor", .{});
317:                     raylib.root_module.linkSystemLibrary("Xext", .{});
318:                     raylib.root_module.linkSystemLibrary("Xfixes", .{});
319:                     raylib.root_module.linkSystemLibrary("Xi", .{});
320:                     raylib.root_module.linkSystemLibrary("Xinerama", .{});
321:                     raylib.root_module.linkSystemLibrary("Xrandr", .{});
322:                     raylib.root_module.linkSystemLibrary("Xrender", .{});
323:                 }

(Showing lines 312-323 of 691. Use offset=324 to continue.)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.4s)

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/build.zig",
  "oldString": "                if (options.linux_display_backend == .X11 or options.linux_display_backend == .Both) {\n                    raylib.root_module.addCMacro(\"_GLFW_X11\", \"\");\n                    raylib.root_module.linkSystemLibrary(\"GLX\", .{});\n                    raylib.root_module.linkSystemLibrary(\"X11\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xcursor\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xext\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xfixes\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xi\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xinerama\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xrandr\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xrender\", .{});\n                }",
  "newString": "                if (options.linux_display_backend == .X11 or options.linux_display_backend == .Both) {\n                    raylib.root_module.addCMacro(\"_GLFW_X11\", \"\");\n                    raylib.root_module.linkSystemLibrary(\"GLX\", .{});\n                    raylib.root_module.linkSystemLibrary(\"EGL\", .{});\n                    raylib.root_module.linkSystemLibrary(\"X11\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xcursor\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xext\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xfixes\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xi\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xinerama\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xrandr\", .{});\n                    raylib.root_module.linkSystemLibrary(\"Xrender\", .{});\n                }"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · claude-sonnet-4-6 · 7.5s)

**Tool: bash**

**Input:**
```json
{
  "command": "rm -rf /home/mzwallow/Development/zimul/.zig-cache && zig build 2>&1",
  "description": "Clean rebuild with EGL linked for X11"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.2s)

**Tool: bash**

**Input:**
```json
{
  "command": "ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul | grep -i \"egl\\|glx\"",
  "description": "Verify EGL is now linked"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.0s)

**Tool: bash**

**Input:**
```json
{
  "command": "ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul",
  "description": "Check all linked libraries"
}
```

**Output:**
```
	linux-vdso.so.1 (0x00007fe901dd3000)
	libm.so.6 => /usr/lib/libm.so.6 (0x00007fe901c6f000)
	libc.so.6 => /usr/lib/libc.so.6 (0x00007fe901a7e000)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x00007fe901dd5000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x00007fe90193c000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x00007fe901911000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x00007fe90190c000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x00007fe901902000)

```

---

## Assistant (Build · claude-sonnet-4-6 · 9.1s)

Still no `libEGL` or `libGLX` in the dynamic deps — they're being statically resolved or dlopen'd at runtime by GLFW. Let me check if EGL init is actually succeeding now:

**Tool: bash**

**Input:**
```json
{
  "command": "timeout 5 /home/mzwallow/Development/zimul/zig-out/bin/zimul 2>&1",
  "description": "Run and check full output for EGL usage"
}
```

**Output:**
```
INFO: Initializing raylib 6.0
INFO: Platform backend: DESKTOP (GLFW)
INFO: Supported raylib modules:
INFO:     > rcore:..... loaded (mandatory)
INFO:     > rlgl:...... loaded (mandatory)
INFO:     > rshapes:... loaded (optional)
INFO:     > rtextures:. loaded (optional)
INFO:     > rtext:..... loaded (optional)
INFO:     > rmodels:... loaded (optional)
INFO:     > raudio:.... loaded (optional)
INFO: DISPLAY: Device initialized successfully 
INFO:     > Display size: 1920 x 1080
INFO:     > Screen size:  800 x 400
INFO:     > Render size:  800 x 400
INFO:     > Viewport offsets: 0, 0
INFO: GLAD: OpenGL extensions loaded successfully
INFO: GL: Supported extensions count: 401
INFO: GL: OpenGL device information:
INFO:     > Vendor:   NVIDIA Corporation
INFO:     > Renderer: NVIDIA GeForce RTX 4070/PCIe/SSE2
INFO:     > Version:  3.3.0 NVIDIA 590.48.01
INFO:     > GLSL:     3.30 NVIDIA via Cg compiler
INFO: GL: VAO extension detected, VAO functions loaded successfully
INFO: GL: NPOT textures extension detected, full NPOT textures supported
INFO: GL: DXT compressed textures supported
INFO: GL: ETC2/EAC compressed textures supported
INFO: PLATFORM: DESKTOP (GLFW - X11): Initialized successfully
DEBUG: TEXTURE: Load mipmap level 0 (1 x 1), size: 4, offset: 0
INFO: TEXTURE: [ID 1] Texture loaded successfully (1x1 | R8G8B8A8 | 1 mipmaps)
INFO: TEXTURE: [ID 1] Default texture loaded successfully
INFO: SHADER: [ID 1] Vertex shader compiled successfully
INFO: SHADER: [ID 2] Fragment shader compiled successfully
INFO: SHADER: [ID 3] Program shader loaded successfully
INFO: SHADER: [ID 3] Default shader loaded successfully
INFO: RLGL: Render batch vertex buffers loaded successfully in RAM (CPU)
INFO: RLGL: Render batch vertex buffers loaded successfully in VRAM (GPU)
INFO: RLGL: Default OpenGL state initialized successfully
DEBUG: TEXTURE: Load mipmap level 0 (128 x 128), size: 32768, offset: 0
INFO: TEXTURE: [ID 2] Texture loaded successfully (128x128 | GRAY_ALPHA | 1 mipmaps)
INFO: FONT: Default font loaded successfully (224 glyphs)
INFO: SYSTEM: Working Directory: /home/mzwallow/Development/zimul
INFO: TIMER: Target time per frame: 6.944 milliseconds

```

---

## Assistant (Build · claude-sonnet-4-6 · 12.9s)

Still NVIDIA via GLX. GLFW's `_glfwInitEGL` is loading `libEGL.so.1` via `dlopen` — not the linker — so our `linkSystemLibrary("EGL")` makes no difference. And it's finding `libEGL_nvidia.so` which maps back to the NVIDIA EGL, same problem.

Let me take a completely different approach and just check what actually works. The real question is: **why does `glxgears` render fine but raylib doesn't?** Let me look at what `glxgears` does differently:

**Tool: bash**

**Input:**
```json
{
  "command": "ldd $(which glxgears) 2>/dev/null | grep -i \"gl\\|egl\"",
  "description": "Check what GL libraries glxgears uses"
}
```

**Output:**
```
	libGL.so.1 => /usr/lib/libGL.so.1 (0x00007f5e3aacf000)
	libGLdispatch.so.0 => /usr/lib/libGLdispatch.so.0 (0x00007f5e3a605000)
	libGLX.so.0 => /usr/lib/libGLX.so.0 (0x00007f5e3a5d4000)

```

**Tool: bash**

**Input:**
```json
{
  "command": "GLFW_LOG_ERRORS=1 timeout 5 /home/mzwallow/Development/zimul/zig-out/bin/zimul 2>&1 | grep -iv \"texture\\|shader\\|font\\|timer\\|batch\\|vao\\|npot\\|dxt\\|etc\\|glad\\|modules\\|rcore\\|rlgl\\|rshapes\\|rtextures\\|rtext\\|rmodels\\|raudio\\|mandatory\\|optional\"",
  "description": "Run with filtered output showing only key messages"
}
```

**Output:**
```
INFO: Initializing raylib 6.0
INFO: Platform backend: DESKTOP (GLFW)
INFO: DISPLAY: Device initialized successfully 
INFO:     > Display size: 1920 x 1080
INFO:     > Screen size:  800 x 400
INFO:     > Render size:  800 x 400
INFO:     > Viewport offsets: 0, 0
INFO: GL: Supported extensions count: 401
INFO: GL: OpenGL device information:
INFO:     > Vendor:   NVIDIA Corporation
INFO:     > Renderer: NVIDIA GeForce RTX 4070/PCIe/SSE2
INFO:     > Version:  3.3.0 NVIDIA 590.48.01
INFO:     > GLSL:     3.30 NVIDIA via Cg compiler
INFO: PLATFORM: DESKTOP (GLFW - X11): Initialized successfully
INFO: SYSTEM: Working Directory: /home/mzwallow/Development/zimul

```

---

## Assistant (Build · claude-sonnet-4-6 · 8.9s)

`glxgears` links `libGL.so.1` + `libGLX.so.0` + `libGLdispatch.so.0` — the Mesa GLVND stack. Raylib's binary doesn't link any of these. GLFW is using `dlopen` to load GL/GLX at runtime, and it's finding the NVIDIA-specific paths.

Let me check what `libGL.so.1` resolves to and why glxgears works:

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la /usr/lib/libGL.so.1 && ls -la /usr/lib/libGLX.so.0",
  "description": "Check what libGL.so.1 and libGLX point to"
}
```

**Output:**
```
lrwxrwxrwx 1 root root 14 Jun 14  2025 /usr/lib/libGL.so.1 -> libGL.so.1.7.0
lrwxrwxrwx 1 root root 15 Jun 14  2025 /usr/lib/libGLX.so.0 -> libGLX.so.0.0.0

```

**Tool: bash**

**Input:**
```json
{
  "command": "grep -rn \"dlopen\\|libGL\\|libGLX\\|gl.so\" /home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/external/glfw/src/glx_context.c | grep \"dlopen\\|libGL\" | head -10",
  "description": "Check which GL library GLFW opens via dlopen"
}
```

**Output:**
```
231:        // NOTE: glvnd provides GLX 1.4, so this can only happen with libGL
265:        "libGL-1.so",
267:        "libGL.so",
269:        "libGLX.so.0",
270:        "libGL.so.1",
271:        "libGL.so",

```

---

## Assistant (Build · claude-sonnet-4-6 · 6.0s)

GLFW tries to load `libGL.so.1` which resolves to the GLVND dispatch library — that's the same one `glxgears` uses, so the loading isn't the issue. The problem must be in how the framebuffer is **presented**. Let me check if this is actually a `glXSwapBuffers` vs compositor issue by adding a simple test — does raylib's swap actually call into XWayland correctly:

**Tool: bash**

**Input:**
```json
{
  "command": "pacman -Q mesa 2>/dev/null && glxinfo 2>/dev/null | grep \"GLX.*version\\|direct render\"",
  "description": "Check Mesa version and direct rendering status"
}
```

**Output:**
```
mesa 1:26.0.1-1
direct rendering: Yes
GLX version: 1.4

```

---

## Assistant (Build · claude-sonnet-4-6 · 9.7s)

Direct rendering is enabled. Let me take a completely fresh look — let me write a minimal C test that does exactly what raylib does (GLFW + OpenGL 3.3 + clearcolor + swapbuffers) and see if that also shows black:

**Tool: bash**

**Input:**
```json
{
  "command": "cat > /tmp/test_glfw.c << 'EOF'\n#include <GLFW/glfw3.h>\n#include <stdio.h>\nint main() {\n    glfwInit();\n    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);\n    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);\n    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);\n    GLFWwindow* w = glfwCreateWindow(800, 400, \"test\", NULL, NULL);\n    glfwMakeContextCurrent(w);\n    printf(\"Renderer: %s\\n\", glGetString(GL_RENDERER));\n    for (int i = 0; i < 300; i++) {\n        glClearColor(0.0f, 0.0f, 1.0f, 1.0f);\n        glClear(GL_COLOR_BUFFER_BIT);\n        glfwSwapBuffers(w);\n        glfwPollEvents();\n    }\n    glfwDestroyWindow(w);\n    glfwTerminate();\n    return 0;\n}\nEOF\ngcc /tmp/test_glfw.c -o /tmp/test_glfw -lglfw -lGL && timeout 5 /tmp/test_glfw 2>&1",
  "description": "Build and run minimal GLFW blue window test"
}
```

**Output:**
```
Renderer: NVIDIA GeForce RTX 4070/PCIe/SSE2

```

---

## Assistant (Build · claude-sonnet-4-6 · 5.7s)

The minimal GLFW test ran for 5 seconds too. Does it show a blue window? Let me check if the issue is **Hyprland not rendering XWayland windows at all** for your user, rather than a code issue:

**Tool: bash**

**Input:**
```json
{
  "command": "hyprctl clients 2>&1 | grep -E \"class|xwayland|mapped\" | head -30",
  "description": "Check all Hyprland clients and their xwayland status"
}
```

**Output:**
```
	mapped: 1
	class: Emulator
	xwayland: 1
	mapped: 1
	class: Emulator
	xwayland: 1
	mapped: 1
	class: com.mitchellh.ghostty
	xwayland: 0
	mapped: 1
	class: google-chrome
	xwayland: 0
	mapped: 1
	class: google-chrome
	xwayland: 0

```

---

## Assistant (Build · claude-sonnet-4-6 · 17.1s)

You have XWayland apps running (the Android Emulator) — so XWayland itself works. But those Emulator windows presumably render correctly. This means the issue is specific to **OpenGL rendering via GLFW on XWayland**, not XWayland itself.

Let me check if the Android Emulator windows also show black, and also test whether the simple C GLFW test above actually showed a blue window on screen (we can't know from the terminal). Let me also check if `glxgears` actually shows on screen from your terminal vs being another black window:

**Tool: question**

**Input:**
```json
{
  "questions": [
    {
      "question": "When glxgears ran earlier, did you actually see the spinning gears on screen?",
      "header": "glxgears visibility",
      "options": [
        {
          "label": "Yes, saw spinning gears (Recommended)",
          "description": "The gears window appeared and showed 3D gears"
        },
        {
          "label": "No, also black screen",
          "description": "glxgears also showed a black window"
        },
        {
          "label": "Window didn't appear",
          "description": "No window appeared at all"
        }
      ]
    }
  ]
}
```

**Output:**
```
User has answered your questions: "When glxgears ran earlier, did you actually see the spinning gears on screen?"="Yes, saw spinning gears (Recommended)". You can now continue with the user's answers in mind.
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.6s)

So `glxgears` shows fine but raylib doesn't. Let me check the exact difference — `glxgears` links `libGL.so.1` directly at link time, while GLFW loads it via `dlopen`. Let me also check if `glxgears` renders in a window matching the same XWayland path:

**Tool: bash**

**Input:**
```json
{
  "command": "\n# Check if glxgears is XWayland or native Wayland\nhyprctl clients 2>&1 | grep -B5 -A10 \"glxgears\\|gears\" || echo \"not running\"\n# Also check what glxgears actually links at runtime vs our binary\nldd $(which glxgears) 2>/dev/null",
  "description": "Check glxgears linking and Hyprland status"
}
```

**Output:**
```
not running
	linux-vdso.so.1 (0x00007fed5732d000)
	libGL.so.1 => /usr/lib/libGL.so.1 (0x00007fed5726d000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x00007fed5712b000)
	libm.so.6 => /usr/lib/libm.so.6 (0x00007fed5700d000)
	libc.so.6 => /usr/lib/libc.so.6 (0x00007fed56e1c000)
	libGLdispatch.so.0 => /usr/lib/libGLdispatch.so.0 (0x00007fed56da3000)
	libGLX.so.0 => /usr/lib/libGLX.so.0 (0x00007fed56d72000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x00007fed56d45000)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x00007fed5732f000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x00007fed56d40000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x00007fed56d38000)

```

---

## Assistant (Build · claude-sonnet-4-6 · 6.2s)

The key difference: `glxgears` links `libGL.so.1` **at link time** (it's in `DT_NEEDED`), while raylib's binary doesn't — GLFW loads it via `dlopen` at runtime. When `libGL.so.1` is in `DT_NEEDED`, the dynamic linker initializes it with the correct GLVND dispatch setup including XWayland hooks. When loaded via `dlopen`, something in the initialization path is different.

The fix: link `libGL` directly at build time so it ends up in `DT_NEEDED`:

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/build.zig</path>
<type>file</type>
<content>1: const std = @import("std");
2: 
3: pub fn build(b: *std.Build) void {
4:     const target = b.standardTargetOptions(.{});
5:     const optimize = b.standardOptimizeOption(.{});
6: 
7:     const mod = b.addModule("zimul", .{
8:         .root_source_file = b.path("src/root.zig"),
9:         .target = target,
10:         .optimize = optimize,
11:     });
12: 
13:     const exe = b.addExecutable(.{
14:         .name = "zimul",
15:         .root_module = b.createModule(.{
16:             .root_source_file = b.path("src/main.zig"),
17:             .target = target,
18:             .optimize = optimize,
19:             .imports = &.{
20:                 .{ .name = "zimul", .module = mod },
21:             },
22:         }),
23:     });
24: 
25:     // Raylib
26:     const raylib_dep = b.dependency("raylib_zig", .{
27:         .target = target,
28:         .optimize = optimize,
29:         .linux_display_backend = @as(@import("raylib_zig").LinuxDisplayBackend, .X11),
30:     });
31:     const raylib_artifact = raylib_dep.artifact("raylib");
32:     exe.root_module.linkLibrary(raylib_artifact);
33:     exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
34:     exe.root_module.addImport("raygui", raylib_dep.module("raygui"));
35: 
36:     b.installArtifact(exe);
37: 
38:     const run_step = b.step("run", "Run the app");
39: 
40:     const run_cmd = b.addRunArtifact(exe);
41:     run_step.dependOn(&run_cmd.step);
42: 
43:     run_cmd.step.dependOn(b.getInstallStep());
44: 
45:     if (b.args) |args| {
46:         run_cmd.addArgs(args);
47:     }
48: 
49:     // Check
50:     const exe_check = b.addExecutable(.{
51:         .name = "zimul",
52:         .root_module = exe.root_module,
53:     });
54: 
55:     const check_step = b.step("check", "Check");
56:     check_step.dependOn(&exe_check.step);
57: }

(End of file - total 57 lines)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.6s)

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig",
  "oldString": "    const raylib_artifact = raylib_dep.artifact(\"raylib\");\n    exe.root_module.linkLibrary(raylib_artifact);\n    exe.root_module.addImport(\"raylib\", raylib_dep.module(\"raylib\"));\n    exe.root_module.addImport(\"raygui\", raylib_dep.module(\"raygui\"));",
  "newString": "    const raylib_artifact = raylib_dep.artifact(\"raylib\");\n    exe.root_module.linkLibrary(raylib_artifact);\n    // Link libGL directly so it appears in DT_NEEDED and is initialized by the\n    // dynamic linker before GLFW's dlopen path — this ensures GLVND dispatch works\n    // correctly on XWayland with NVIDIA drivers.\n    exe.root_module.linkSystemLibrary(\"GL\", .{});\n    exe.root_module.addImport(\"raylib\", raylib_dep.module(\"raylib\"));\n    exe.root_module.addImport(\"raygui\", raylib_dep.module(\"raygui\"));"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · claude-sonnet-4-6 · 5.8s)

**Tool: bash**

**Input:**
```json
{
  "command": "zig build 2>&1 && ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul | grep -i \"gl\\b\\|GL\\b\"",
  "description": "Build and verify libGL is in DT_NEEDED"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 2.8s)

**Tool: bash**

**Input:**
```json
{
  "command": "ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul",
  "description": "Check all dynamic dependencies"
}
```

**Output:**
```
	linux-vdso.so.1 (0x00007fbbbbc36000)
	libm.so.6 => /usr/lib/libm.so.6 (0x00007fbbbbad2000)
	libc.so.6 => /usr/lib/libc.so.6 (0x00007fbbbb8e1000)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x00007fbbbbc38000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x00007fbbbb79f000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x00007fbbbb774000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x00007fbbbb76f000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x00007fbbbb765000)

```

---

## Assistant (Build · claude-sonnet-4-6 · 7.3s)

Zig's linker is stripping the `libGL` dependency because no symbols from it are directly referenced (GLFW uses `dlopen`). Zig's linker does dead-symbol elimination by default. We need to force it to keep the dependency:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"linkSystemLibrary\\|linkage\\|whole_archive\\|as_needed\\|no_as_needed\\|link_libc\" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Module.zig | grep -i \"needed\\|whole\\|weak\" | head -10",
  "description": "Check Zig link options for forcing library inclusion"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 4.7s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"LinkSystemLibraryOptions\\|needed\\|weak\\|preferred_link_mode\" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Module.zig | head -20",
  "description": "Check LinkSystemLibraryOptions fields"
}
```

**Output:**
```
62:    needed: bool,
63:    weak: bool,
65:    preferred_link_mode: std.builtin.LinkMode,
202:    needed: bool = false,
203:    /// Marks all referenced symbols from this library as weak, meaning that if
208:    /// When the linker encounters two weak symbols, the chosen one is
211:    weak: bool = false,
344:pub const LinkSystemLibraryOptions = struct {
348:    needed: bool = false,
349:    /// Marks all referenced symbols from this library as weak, meaning that if
354:    /// When the linker encounters two weak symbols, the chosen one is
357:    weak: bool = false,
359:    preferred_link_mode: std.builtin.LinkMode = .dynamic,
366:    options: LinkSystemLibraryOptions,
383:            .needed = options.needed,
384:            .weak = options.weak,
386:            .preferred_link_mode = options.preferred_link_mode,

```

---

## Assistant (Build · claude-sonnet-4-6 · 4.8s)

There's a `needed: bool` option — this maps to `--no-as-needed` / `-Wl,--no-as-needed` which forces the library into `DT_NEEDED` even if no symbols are referenced:

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig",
  "oldString": "    exe.root_module.linkSystemLibrary(\"GL\", .{});",
  "newString": "    exe.root_module.linkSystemLibrary(\"GL\", .{ .needed = true });"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · claude-sonnet-4-6 · 5.0s)

**Tool: bash**

**Input:**
```json
{
  "command": "zig build 2>&1 && ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul",
  "description": "Build and verify libGL is now in DT_NEEDED"
}
```

**Output:**
```
	linux-vdso.so.1 (0x00007f5d9f95b000)
	libm.so.6 => /usr/lib/libm.so.6 (0x00007f5d9f7f7000)
	libc.so.6 => /usr/lib/libc.so.6 (0x00007f5d9f606000)
	/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2 (0x00007f5d9f95d000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x00007f5d9f4c4000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x00007f5d9f499000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x00007f5d9f494000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x00007f5d9f48a000)

```

---

## Assistant (Build · claude-sonnet-4-6 · 11.4s)

Still stripped. Zig's linker is not respecting `needed = true` for system libraries with no referenced symbols. Let me try a different approach — use `addRPath` or force it via linker flags:

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"addLinkerArg\\|addObjectFile\\|link_objects\\|linker_args\" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Module.zig | head -10",
  "description": "Find how to pass raw linker args in Zig build"
}
```

**Output:**
```
18:link_objects: ArrayList(LinkObject),
220:    /// If `null`, it means this module is made up of only `link_objects`.
289:                .link_objects = .{},
380:    m.link_objects.append(b.allocator, .{
428:    m.link_objects.append(allocator, .{ .c_source_files = c_source_files }) catch @panic("OOM");
436:    m.link_objects.append(allocator, .{ .c_source_file = c_source_file }) catch @panic("OOM");
452:    m.link_objects.append(allocator, .{ .win32_resource_file = rc_source_file }) catch @panic("OOM");
457:    m.link_objects.append(b.allocator, .{ .assembly_file = source.dupe(b) }) catch @panic("OOM");
460:pub fn addObjectFile(m: *Module, object: LazyPath) void {
462:    m.link_objects.append(b.allocator, .{ .static_path = object.dupe(b) }) catch @panic("OOM");

```

---

## Assistant (Build · claude-sonnet-4-6 · 3.4s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"addLinkerArg\\|addLinkerArgs\\|linker_script\" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Step/Compile.zig | head -10",
  "description": "Find addLinkerArg on Compile step"
}
```

**Output:**
```
29:linker_script: ?LazyPath = null,
617:    compile.linker_script = source.dupe(b);
1553:    if (compile.linker_script) |linker_script| {
1555:        try zig_args.append(linker_script.getPath2(b, step));

```

---

## Assistant (Build · claude-sonnet-4-6 · 4.2s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"pub fn add.*[Ll]ink\\|addArg\\|addMiscFlag\" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Step/Compile.zig | head -20",
  "description": "Find methods to add linker flags to Compile step"
}
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.7s)

**Tool: bash**

**Input:**
```json
{
  "command": "grep -n \"pub fn \" /home/mzwallow/zig/zig-x86_64-linux-0.16.0-dev.2682+02142a54d/lib/std/Build/Step/Compile.zig | head -40",
  "description": "List public functions on Compile step"
}
```

**Output:**
```
302:    pub fn isTest(kind: Kind) bool {
318:        pub fn dupe(file: File, b: *std.Build) File {
339:            pub fn dupe(opts: Directory.Options, b: *std.Build) Directory.Options {
347:        pub fn dupe(dir: Directory, b: *std.Build) Directory {
356:    pub fn getSource(installation: HeaderInstallation) LazyPath {
362:    pub fn dupe(installation: HeaderInstallation, b: *std.Build) HeaderInstallation {
378:pub fn create(owner: *std.Build, options: Options) *Compile {
520:pub fn installHeader(cs: *Compile, source: LazyPath, dest_rel_path: []const u8) void {
534:pub fn installHeadersDirectory(
554:pub fn installConfigHeader(cs: *Compile, config_header: *Step.ConfigHeader) void {
561:pub fn installLibraryHeaders(cs: *Compile, lib: *Compile) void {
585:pub fn getEmittedIncludeTree(cs: *Compile) LazyPath {
598:pub fn addObjCopy(cs: *Compile, options: Step.ObjCopy.Options) *Step.ObjCopy {
611:pub fn checkObject(compile: *Compile) *Step.CheckObject {
615:pub fn setLinkerScript(compile: *Compile, source: LazyPath) void {
621:pub fn setVersionScript(compile: *Compile, source: LazyPath) void {
627:pub fn forceUndefinedSymbol(compile: *Compile, symbol_name: []const u8) void {
634:pub fn dependsOnSystemLibrary(compile: *Compile, name: []const u8) bool {
664:pub fn isDynamicLibrary(compile: *const Compile) bool {
668:pub fn isStaticLibrary(compile: *const Compile) bool {
672:pub fn isDll(compile: *Compile) bool {
676:pub fn producesPdbFile(compile: *Compile) bool {
694:pub fn producesImplib(compile: *Compile) bool {
811:pub fn setVerboseLink(compile: *Compile, value: bool) void {
815:pub fn setVerboseCC(compile: *Compile, value: bool) void {
819:pub fn setLibCFile(compile: *Compile, libc_file: ?LazyPath) void {
839:pub fn getEmittedBinDirectory(compile: *Compile) LazyPath {
846:pub fn getEmittedBin(compile: *Compile) LazyPath {
852:pub fn getEmittedImplib(compile: *Compile) LazyPath {
859:pub fn getEmittedH(compile: *Compile) LazyPath {
867:pub fn getEmittedPdb(compile: *Compile) LazyPath {
873:pub fn getEmittedDocs(compile: *Compile) LazyPath {
878:pub fn getEmittedAsm(compile: *Compile) LazyPath {
883:pub fn getEmittedLlvmIr(compile: *Compile) LazyPath {
888:pub fn getEmittedLlvmBc(compile: *Compile) LazyPath {
892:pub fn setExecCmd(compile: *Compile, args: []const ?[]const u8) void {
1834:pub fn rebuildInFuzzMode(c: *Compile, gpa: Allocator, progress_node: std.Progress.Node) !Path {
1851:pub fn doAtomicSymLinks(
2049:pub fn rootModuleTarget(c: *Compile) std.Target {
2065:pub fn getCompileDependencies(start: *Compile, chase_dynamic: bool) []const *Compile {

```

---

## Assistant (Build · claude-sonnet-4-6 · 12.5s)

There's no `addLinkerArg` but there's the `run_cmd` approach. Actually, the simplest approach is to just preload `libGL` using `LD_PRELOAD` set in the run command, or use a wrapper script. But actually let me reconsider the whole problem.

`glxgears` works because it links `libGL.so.1` directly. Our GLFW binary uses `dlopen("libGL.so.1")` which should load the same library. The difference might be **`glxgears` uses `glXSwapBuffers` through the GLVND dispatch which properly handles XWayland**, while GLFW's `glXSwapBuffers` call is going through its own dlopen'd handle with a different dispatch path.

Let me just test directly: does the small C GLFW program (`/tmp/test_glfw`) that we compiled with `-lglfw -lGL` also show black?

**Tool: question**

**Input:**
```json
{
  "questions": [
    {
      "question": "Did the /tmp/test_glfw program (compiled earlier) show a blue window?",
      "header": "test_glfw result",
      "options": [
        {
          "label": "Yes, blue window appeared (Recommended)",
          "description": "The small GLFW test showed a blue window"
        },
        {
          "label": "No, also black screen",
          "description": "The test program also showed black"
        },
        {
          "label": "Didn't see it / wasn't watching",
          "description": "I didn't notice whether it appeared"
        }
      ]
    }
  ]
}
```

**Output:**
```
User has answered your questions: "Did the /tmp/test_glfw program (compiled earlier) show a blue window?"="Yes, blue window appeared (Recommended)". You can now continue with the user's answers in mind.
```

---

## Assistant (Build · claude-sonnet-4-6 · 8.1s)

The system GLFW with `-lGL` works. Our raylib binary uses bundled GLFW with `dlopen`. The fix is clear: **link `-lGL` in a way that actually ends up in the binary**. Since Zig strips unused library references, let us force it by referencing a GL symbol directly from a C file.

The cleanest approach: add a tiny C shim that references `glClear` to force `libGL` into `DT_NEEDED`:

**Tool: write**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/src/gl_preload.c",
  "content": "// Force libGL into DT_NEEDED so the dynamic linker initializes GLVND dispatch\n// before GLFW's dlopen call. Without this, GLFW's dlopen(\"libGL.so.1\") on\n// XWayland+NVIDIA produces a black window due to incorrect dispatch setup.\n#include <GL/gl.h>\n__attribute__((used)) static void* _force_libgl_needed = (void*)glClear;\n"
}
```

**Output:**
```
Wrote file successfully.

LSP errors detected in other files:
<diagnostics file="/home/mzwallow/Development/raylib-zig/zig-pkg/raylib-5.6.0-dev-whq8uNSYJwUA6SlXhKDsitkuySZYi6Zn3IlzusX1AIot/src/platforms/rcore_desktop_glfw.c">
ERROR [119:8] Unknown type name 'CoreData'
ERROR [167:1] Unknown type name 'bool'
ERROR [170:17] Use of undeclared identifier 'true'
ERROR [176:10] Call to undeclared function 'FLAG_IS_SET'; ISO C99 and later do not support implicit function declarations
ERROR [176:41] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [184:28] Call to undeclared function 'GetCurrentMonitor'; ISO C99 and later do not support implicit function declarations
ERROR [195:37] Use of undeclared identifier 'Point'
ERROR [199:13] Call to undeclared function 'FLAG_SET'; ISO C99 and later do not support implicit function declarations
ERROR [199:41] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [210:14] Call to undeclared function 'TRACELOG'; ISO C99 and later do not support implicit function declarations
ERROR [210:23] Use of undeclared identifier 'LOG_WARNING'
ERROR [220:9] Call to undeclared function 'FLAG_CLEAR'; ISO C99 and later do not support implicit function declarations
ERROR [220:39] Use of undeclared identifier 'FLAG_FULLSCREEN_MODE'
ERROR [225:44] Use of undeclared identifier 'FLAG_WINDOW_HIGHDPI'
ERROR [227:13] Use of undeclared identifier 'Vector2'
ERROR [228:80] Use of undeclared identifier 'scaleDpi'
ERROR [229:82] Use of undeclared identifier 'scaleDpi'
ERROR [247:40] Use of undeclared identifier 'FLAG_VSYNC_HINT'
ERROR [255:9] Call to undeclared function 'FLAG_IS_SET'; ISO C99 and later do not support implicit function declarations
ERROR [1:1] Too many errors emitted, stopping now
</diagnostics>
```

---

## Assistant (Build · claude-sonnet-4-6 · 3.3s)

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/build.zig</path>
<type>file</type>
<content>1: const std = @import("std");
2: 
3: pub fn build(b: *std.Build) void {
4:     const target = b.standardTargetOptions(.{});
5:     const optimize = b.standardOptimizeOption(.{});
6: 
7:     const mod = b.addModule("zimul", .{
8:         .root_source_file = b.path("src/root.zig"),
9:         .target = target,
10:         .optimize = optimize,
11:     });
12: 
13:     const exe = b.addExecutable(.{
14:         .name = "zimul",
15:         .root_module = b.createModule(.{
16:             .root_source_file = b.path("src/main.zig"),
17:             .target = target,
18:             .optimize = optimize,
19:             .imports = &.{
20:                 .{ .name = "zimul", .module = mod },
21:             },
22:         }),
23:     });
24: 
25:     // Raylib
26:     const raylib_dep = b.dependency("raylib_zig", .{
27:         .target = target,
28:         .optimize = optimize,
29:         .linux_display_backend = @as(@import("raylib_zig").LinuxDisplayBackend, .X11),
30:     });
31:     const raylib_artifact = raylib_dep.artifact("raylib");
32:     exe.root_module.linkLibrary(raylib_artifact);
33:     // Link libGL directly so it appears in DT_NEEDED and is initialized by the
34:     // dynamic linker before GLFW's dlopen path — this ensures GLVND dispatch works
35:     // correctly on XWayland with NVIDIA drivers.
36:     exe.root_module.linkSystemLibrary("GL", .{ .needed = true });
37:     exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
38:     exe.root_module.addImport("raygui", raylib_dep.module("raygui"));
39: 
40:     b.installArtifact(exe);
41: 
42:     const run_step = b.step("run", "Run the app");
43: 
44:     const run_cmd = b.addRunArtifact(exe);
45:     run_step.dependOn(&run_cmd.step);
46: 
47:     run_cmd.step.dependOn(b.getInstallStep());
48: 
49:     if (b.args) |args| {
50:         run_cmd.addArgs(args);
51:     }
52: 
53:     // Check
54:     const exe_check = b.addExecutable(.{
55:         .name = "zimul",
56:         .root_module = exe.root_module,
57:     });
58: 
59:     const check_step = b.step("check", "Check");
60:     check_step.dependOn(&exe_check.step);
61: }

(End of file - total 61 lines)
</content>
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.1s)

**Tool: edit**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig",
  "oldString": "    const raylib_artifact = raylib_dep.artifact(\"raylib\");\n    exe.root_module.linkLibrary(raylib_artifact);\n    // Link libGL directly so it appears in DT_NEEDED and is initialized by the\n    // dynamic linker before GLFW's dlopen path — this ensures GLVND dispatch works\n    // correctly on XWayland with NVIDIA drivers.\n    exe.root_module.linkSystemLibrary(\"GL\", .{ .needed = true });\n    exe.root_module.addImport(\"raylib\", raylib_dep.module(\"raylib\"));\n    exe.root_module.addImport(\"raygui\", raylib_dep.module(\"raygui\"));",
  "newString": "    const raylib_artifact = raylib_dep.artifact(\"raylib\");\n    exe.root_module.linkLibrary(raylib_artifact);\n    // Add a C shim that references glClear to force libGL into DT_NEEDED.\n    // This ensures GLVND dispatch is initialized by the dynamic linker before\n    // GLFW's dlopen call, fixing black windows on XWayland+NVIDIA.\n    exe.root_module.addCSourceFile(.{\n        .file = b.path(\"src/gl_preload.c\"),\n        .flags = &.{},\n    });\n    exe.root_module.linkSystemLibrary(\"GL\", .{});\n    exe.root_module.addImport(\"raylib\", raylib_dep.module(\"raylib\"));\n    exe.root_module.addImport(\"raygui\", raylib_dep.module(\"raygui\"));"
}
```

**Output:**
```
Edit applied successfully.
```

---

## Assistant (Build · claude-sonnet-4-6 · 6.7s)

**Tool: bash**

**Input:**
```json
{
  "command": "zig build 2>&1 && ldd /home/mzwallow/Development/zimul/zig-out/bin/zimul | grep -i \"GL\\b\\|gl\\b\"",
  "description": "Build and check if libGL is in DT_NEEDED"
}
```

**Output:**
```
	libGL.so.1 => /usr/lib/libGL.so.1 (0x00007fa2de480000)

```

---

## Assistant (Build · claude-sonnet-4-6 · 5.2s)

`libGL.so.1` is now in `DT_NEEDED`. Try `zig build run` now — this should match what `glxgears` and the system GLFW test do, fixing the black screen.

---

## User

what about i create webgpu binding by myself?

---

## Assistant (Plan · minimax-m2.5-free · 23.5s)

_Thinking:_

The user is asking about creating a WebGPU binding themselves, rather than continuing to debug the GLFW/OpenGL issues on their Hyprland+NVIDIA setup.

This is a reasonable alternative approach. WebGPU is the modern graphics API that works natively on Wayland without the GLFW/GLX/EGL complexity. Let me think about what this would involve:

1. WebGPU on Linux uses Vulkan as the backend
2. There are existing WebGPU libraries for Zig
3. The user would need to replace raylib with a WebGPU-based solution

Let me explore what WebGPU options are available for Zig and what the plan would look like.

Creating a WebGPU binding is a great alternative — it works natively on Wayland with NVIDIA (via Vulkan backend) and avoids all the GLFW/X11/GLX/EGL complexity we've been debugging.

Let me explore the existing options for Zig + WebGPU:

**Tool: websearch**

**Input:**
```json
{
  "query": "Zig WebGPU binding library 2025"
}
```

**Output:**
```
Title: GitHub - braheezy/zonk: 2D game engine powered by WebGPU
Author: braheezy
Published Date: 2025-04-27T00:00:00.000Z
URL: https://github.com/braheezy/zonk
Text: GitHub - braheezy/zonk: 2D game engine powered by WebGPU
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
braheezy/**zonk**Public
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star1
2D game engine powered by WebGPU
1star0forksBranchesTagsActivity
Star
NotificationsYou must 

Title: webgpu-wasm-zig
Author: seyha
Published Date: 2025-05-16T00:00:00.000Z
URL: https://codeberg.org/seyha/webgpu-wasm-zig
Text: seyha/webgpu-wasm-zig: 🚀A minimal WebGPU example written in Zig, compiled to WebAssembly (wasm). 🛠️Ideal for experimenting and preparing for native development without install dependencies (dawn, wgpu-rs). - Codeberg.org
seyha/webgpu-wasm-zig

Watch1
Star2
Fork
You've already forked webgpu-wasm-zig
0
CodeIssuesPull requestsProjectsReleasesPackagesWikiActivity
🚀A minimal WebGPU example written in Zig, compiled to WebAssembly (wasm).🛠️Ideal for experimenting and preparing for native development without install dependencies (dawn, wgpu-rs).https://seyhajin.itch.io/webgpu-3d-minimal
3d-graphicsemscriptenwasmwebassemblywebgpuzig
**7**commits**1**branch**0**tags**237**KiB
**Zig87.4%
**HTML12.6%
**master**
Find a file
HTTPS
Download ZIPDownload TAR.GZDownload BUNDLEOpen with VS CodeOpen with VSCodiumOpen with Intellij IDEA
Cite this repository
BibTeX
Cancel
|
**seyhajin**1f055a9f5cUpdate readme.md
|2025-05-16 22:26:45 +02:00|
.gitignore|using WGPU\_DEPTH\_SLICE\_UNDEFINED, fixing build issues, ignoring zig-cache|2024-11-28 08:31:09 -08:00|
build.zig|using WGPU\_DEPTH\_SLICE\_UNDEFINED, fixing build iss

Title: GitHub - seyhajin/webgpu-wasm-zig: 🚀 A minimal WebGPU example written in Zig, compiled to WebAssembly (wasm). 🛠️ Ideal for experimenting and preparing for native development without install dependencies (dawn, wgpu-rs).
Author: seyhajin
Published Date: 2024-01-19T00:00:00.000Z
URL: https://github.com/seyhajin/webgpu-wasm-zig
Text: GitHub - seyhajin/webgpu-wasm-zig: 🚀 A minimal WebGPU example written in Zig, compiled to WebAssembly (wasm). 🛠️ Ideal for experimenting and preparing for native development without install dependencies (dawn, wgpu-rs).
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You

Title: GitHub - vkensou/zgpu: Render Hardware Interface for zig
Author: vkensou
Published Date: 2024-12-14T00:00:00.000Z
URL: https://github.com/vkensou/zgpu
Text: GitHub - vkensou/zgpu: Render Hardware Interface for zig
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign upReseting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
vkensou/**zgpu**Public
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star0
Render Hardware Interface for zig
### License
MIT license
0stars0forksBranchesTagsActivity
Star
NotificationsYou must be signed in to cha

Title: GitHub - zig-gamedev/zgpu: Cross-platform graphics lib for Zig built on top of Dawn native WebGPU implementation.
Author: zig-gamedev
Published Date: 2024-11-03T00:00:00.000Z
URL: https://github.com/zig-gamedev/zgpu
Text: GitHub - zig-gamedev/zgpu: Cross-platform graphics lib for Zig built on top of Dawn native WebGPU implementation.
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
zig-gamedev/**zgpu**Public
* NotificationsYou must be signed in to change notific

Title: GitHub - bronter/wgpu_native_zig: Zig bindings for wgpu-native
Author: bronter
Published Date: 2024-07-09T00:00:00.000Z
URL: https://github.com/bronter/wgpu_native_zig
Text: GitHub - bronter/wgpu\_native\_zig: Zig bindings for wgpu-native
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
bronter/**wgpu\_native\_zig**Public
* NotificationsYou must be signed in to change notification settings
* Fork24
* Star103
Zig bindings for wgpu-native
### License
MIT license
1

Title: GitHub - hexops/mach-gpu: mach/gpu: truly cross-platform WebGPU graphics for Zig
Author: hexops
Published Date: 2022-09-11T00:00:00.000Z
URL: https://github.com/hexops/mach-gpu
Text: GitHub - hexops/mach-gpu: mach/gpu: truly cross-platform WebGPU graphics for Zig
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

hexops

/
**
mach-gpu
**
Public
*
* Notifications
 You must be signed in to change notification settings
* Fork
20

*

Star
187

*
mach/gpu: truly cross-platform WebGPU graphics for Zig
m

Title: Perfecting WebGPU/Dawn native graphics for Zig | Hexops' devlog
Author: 
Published Date: 2022-09-11T00:00:00.000Z
URL: https://devlog.hexops.com/2022/perfecting-webgpu-native/
Text: Perfecting WebGPU/Dawn native graphics for Zig | Hexops' devlog

We’ve just finished a complete rewrite of`mach/gpu`(WebGPU/Dawn bindings for Zig), with 700+ commits, ~7.4k LOC, and 100% API coverage.

WebGPU (not to be confused with WebGL) is a modern graphics API, acting as a unified API to the underlying Vulkan/Metal/DirectX APIs. Despite it’s name, it is also designed for use in native applications via its C API.

Dawn is the C++ implementation of WebGPU by Google, used in Chrome, planned to be shipped to millions of browsers in the not too distant future.

## mach/gpu: WebGPU for Zig

6 months ago we released Mach v0.1 which enabled the creation of native applications using WebGPU graphics in Zig:

It all Just Works™ out of the box in under ~60s - all you need is`zig`,`git`, and`curl`:

```
git clone https://github.com/hexops/mach
cd mach/
zig build run-example-boids

```

(requires Zig v0.10+, see known issues.)

We do all the heavy-lifting behind the scenes for you: building Dawn using Zig as a C++ compiler, rewriting build scripts in Z


```

---

## Assistant (Plan · minimax-m2.5-free · 11.6s)

_Thinking:_

There are several good WebGPU options for Zig:

1. **zig-gamedev/zgpu** - The most actively maintained, built on Dawn (Google's native WebGPU implementation)
2. **hexops/mach-gpu** - Also popular, from the Mach game engine project
3. **vkensou/zgpu** - Another option
4. **bronter/wgpu_native_zig** - Bindings for wgpu-native

The most popular and well-maintained is **zig-gamedev/zgpu** which wraps Dawn (the same implementation Chrome uses).

Let me check what dependencies it has and how it works on Linux/Wayland:

**Tool: webfetch**

**Input:**
```json
{
  "url": "https://github.com/zig-gamedev/zgpu",
  "format": "markdown"
}
```

**Output:**
```
                        GitHub - zig-gamedev/zgpu: Cross-platform graphics lib for Zig built on top of Dawn native WebGPU implementation. · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fzig-gamedev%2Fzgpu)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fzig-gamedev%2Fzgpu)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=zig-gamedev%2Fzgpu)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[zig-gamedev](/zig-gamedev) / **[zgpu](/zig-gamedev/zgpu)** Public

-   [Notifications](/login?return_to=%2Fzig-gamedev%2Fzgpu) You must be signed in to change notification settings
-   [Fork 25](/login?return_to=%2Fzig-gamedev%2Fzgpu)
-   [Star 59](/login?return_to=%2Fzig-gamedev%2Fzgpu)
    

-   [Code](/zig-gamedev/zgpu)
-   [Issues 8](/zig-gamedev/zgpu/issues)
-   [Pull requests 2](/zig-gamedev/zgpu/pulls)
-   [Actions](/zig-gamedev/zgpu/actions)
-   [Projects](/zig-gamedev/zgpu/projects)
-   [Security 0](/zig-gamedev/zgpu/security)
-   [Insights](/zig-gamedev/zgpu/pulse)

Additional navigation options

-   [Code](/zig-gamedev/zgpu)
-   [Issues](/zig-gamedev/zgpu/issues)
-   [Pull requests](/zig-gamedev/zgpu/pulls)
-   [Actions](/zig-gamedev/zgpu/actions)
-   [Projects](/zig-gamedev/zgpu/projects)
-   [Security](/zig-gamedev/zgpu/security)
-   [Insights](/zig-gamedev/zgpu/pulse)

 [](/zig-gamedev/zgpu)

# zig-gamedev/zgpu

 main

[Branches](/zig-gamedev/zgpu/branches)[Tags](/zig-gamedev/zgpu/tags)

[](/zig-gamedev/zgpu/branches)[](/zig-gamedev/zgpu/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[23 Commits](/zig-gamedev/zgpu/commits/main/)

[](/zig-gamedev/zgpu/commits/main/)23 Commits

[.github/workflows](/zig-gamedev/zgpu/tree/main/.github/workflows "This path skips through empty directories")

[.github/workflows](/zig-gamedev/zgpu/tree/main/.github/workflows "This path skips through empty directories")

[libs/dawn/include](/zig-gamedev/zgpu/tree/main/libs/dawn/include "This path skips through empty directories")

[libs/dawn/include](/zig-gamedev/zgpu/tree/main/libs/dawn/include "This path skips through empty directories")

[src](/zig-gamedev/zgpu/tree/main/src "src")

[src](/zig-gamedev/zgpu/tree/main/src "src")

[.gitignore](/zig-gamedev/zgpu/blob/main/.gitignore ".gitignore")

[.gitignore](/zig-gamedev/zgpu/blob/main/.gitignore ".gitignore")

[LICENSE](/zig-gamedev/zgpu/blob/main/LICENSE "LICENSE")

[LICENSE](/zig-gamedev/zgpu/blob/main/LICENSE "LICENSE")

[README.md](/zig-gamedev/zgpu/blob/main/README.md "README.md")

[README.md](/zig-gamedev/zgpu/blob/main/README.md "README.md")

[build.zig](/zig-gamedev/zgpu/blob/main/build.zig "build.zig")

[build.zig](/zig-gamedev/zgpu/blob/main/build.zig "build.zig")

[build.zig.zon](/zig-gamedev/zgpu/blob/main/build.zig.zon "build.zig.zon")

[build.zig.zon](/zig-gamedev/zgpu/blob/main/build.zig.zon "build.zig.zon")

View all files

## Repository files navigation

-   [README](#)
-   [MIT license](#)

# [zgpu](https://github.com/zig-gamedev/zgpu)

[](#zgpu)

Cross-platform graphics lib for Zig built on top of [Dawn](https://github.com/zig-gamedev/dawn) native WebGPU implementation.

Supports Windows 10+ (DirectX 12), macOS 12+ (Metal) and Linux (Vulkan).

## Features

[](#features)

-   Zero-overhead wgpu API bindings ([source code](https://github.com/zig-gamedev/zgpu/blob/main/src/wgpu.zig))
-   Uniform buffer pool for fast CPU->GPU transfers
-   Resource pools and handle-based GPU resources
-   Async shader compilation
-   GPU mipmap generator

## Getting started

[](#getting-started)

Example `build.zig`:

pub fn build(b: \*std.Build) void {
    const exe \= b.addExecutable(.{ ... });

    @import("zgpu").addLibraryPathsTo(exe);

    const zgpu \= b.dependency("zgpu", .{});
    exe.root\_module.addImport("zgpu", zgpu.module("root"));

    if (target.result.os.tag != .emscripten) {
      exe.linkLibrary(zgpu.artifact("zdawn"));
    }
}

## Sample applications

[](#sample-applications)

-   [gui test (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/gui_test_wgpu)
-   [physically based rendering (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/physically_based_rendering_wgpu)
-   [bullet physics test (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/bullet_physics_test_wgpu)
-   [procedural mesh (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/procedural_mesh_wgpu)
-   [textured quad (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/textured_quad_wgpu)
-   [triangle (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/triangle_wgpu)

## Library overview

[](#library-overview)

Below you can find an overview of main `zgpu` features.

### Compile-time options

[](#compile-time-options)

You can override default options in your `build.zig`:

pub fn build(b: \*std.Build) void {
    ...

    const zgpu \= @import("zgpu").package(b, target, optimize, .{
        .options \= .{
            .uniforms\_buffer\_size \= 4 \* 1024 \* 1024,
            .dawn\_skip\_validation \= false,
            .buffer\_pool\_size \= 256,
            .texture\_pool\_size \= 256,
            .texture\_view\_pool\_size \= 256,
            .sampler\_pool\_size \= 16,
            .render\_pipeline\_pool\_size \= 128,
            .compute\_pipeline\_pool\_size \= 128,
            .bind\_group\_pool\_size \= 32,
            .bind\_group\_layout\_pool\_size \= 32,
            .pipeline\_layout\_pool\_size \= 32,
        },
    });

    zgpu.link(exe);

    ...
}

### Graphics Context

[](#graphics-context)

Create a `GraphicsContext` using a `WindowProvider`. For example, using [zglfw](https://github.com/zig-gamedev/zglfw):

const gctx \= try zgpu.GraphicsContext.create(
    allocator,
    .{
        .window \= window,
        .fn\_getTime \= @ptrCast(&zglfw.getTime),
        .fn\_getFramebufferSize \= @ptrCast(&zglfw.Window.getFramebufferSize),

        // optional fields
        .fn\_getWin32Window \= @ptrCast(&zglfw.getWin32Window),
        .fn\_getX11Display \= @ptrCast(&zglfw.getX11Display),
        .fn\_getX11Window \= @ptrCast(&zglfw.getX11Window),
        .fn\_getWaylandDisplay \= @ptrCast(&zglfw.getWaylandDisplay),
        .fn\_getWaylandSurface \= @ptrCast(&zglfw.getWaylandWindow),
        .fn\_getCocoaWindow \= @ptrCast(&zglfw.getCocoaWindow),
    },
    .{}, // default context creation options
);

### Uniforms

[](#uniforms)

-   Implemented as a uniform buffer pool
-   Easy to use
-   Efficient - only one copy operation per frame

struct DrawUniforms \= extern struct {
    object\_to\_world: zm.Mat,
};
const mem \= gctx.uniformsAllocate(DrawUniforms, 1);
mem.slice\[0\] \= .{ .object\_to\_world \= zm.transpose(zm.translation(...)) };

pass.setBindGroup(0, bind\_group, &.{mem.offset});
pass.drawIndexed(...);

// When you are done encoding all commands for a frame:
gctx.submit(...); // Injects \*one\* copy operation to transfer \*all\* allocated uniforms

### Resource pools

[](#resource-pools)

-   Every GPU resource is identified by 32-bit integer handle
-   All resources are stored in one system
-   We keep basic info about each resource (size of the buffer, format of the texture, etc.)
-   You can always check if resource is valid (very useful for async operations)
-   System keeps basic info about resource dependencies, for example, `TextureViewHandle` knows about its parent texture and becomes invalid when parent texture becomes invalid; `BindGroupHandle` knows about all resources it binds so it becomes invalid if any of those resources become invalid

const buffer\_handle \= gctx.createBuffer(...);

if (gctx.isResourceValid(buffer\_handle)) {
    const buffer \= gctx.lookupResource(buffer\_handle).?;  // Returns \`wgpu.Buffer\`

    const buffer\_info \= gctx.lookupResourceInfo(buffer\_handle).?; // Returns \`zgpu.BufferInfo\`
    std.debug.print("Buffer size is: {d}", .{buffer\_info.size});
}

// If you want to destroy a resource before shutting down graphics context:
gctx.destroyResource(buffer\_handle);

### Async shader compilation

[](#async-shader-compilation)

-   Thanks to resource pools and resources identified by handles we can easily async compile all our shaders

const DemoState \= struct {
    pipeline\_handle: zgpu.PipelineLayoutHandle \= .{},
    ...
};
const demo \= try allocator.create(DemoState);

// Below call schedules pipeline compilation and returns immediately. When compilation is complete
// valid pipeline handle will be stored in \`demo.pipeline\_handle\`.
gctx.createRenderPipelineAsync(allocator, pipeline\_layout, pipeline\_descriptor, &demo.pipeline\_handle);

// Pass using our pipeline will be skipped until compilation is ready
pass: {
    const pipeline \= gctx.lookupResource(demo.pipeline\_handle) orelse break :pass;
    ...

    pass.setPipeline(pipeline);
    pass.drawIndexed(...);
}

### Mipmap generation on the GPU

[](#mipmap-generation-on-the-gpu)

-   wgpu API does not provide mipmap generator
-   zgpu provides decent mipmap generator implemented in a compute shader
-   It supports 2D textures, array textures and cubemap textures of any format (`rgba8_unorm`, `rg16_float`, `rgba32_float`, etc.)
-   Currently it requires that: `texture_width == texture_height and isPowerOfTwo(texture_width)`
-   It takes ~260 microsec to generate all mips for 1024x1024 `rgba8_unorm` texture on GTX 1660

// Usage:
gctx.generateMipmaps(arena, command\_encoder, texture\_handle);

## About

Cross-platform graphics lib for Zig built on top of Dawn native WebGPU implementation.

### Topics

[gamedev](/topics/gamedev "Topic: gamedev") [cross-platform](/topics/cross-platform "Topic: cross-platform") [native](/topics/native "Topic: native") [graphics](/topics/graphics "Topic: graphics") [zig](/topics/zig "Topic: zig") [dawn](/topics/dawn "Topic: dawn") [webgpu](/topics/webgpu "Topic: webgpu")

### Resources

[Readme](#readme-ov-file)

### License

[MIT license](#MIT-1-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/zig-gamedev/zgpu/activity)

[Custom properties](/zig-gamedev/zgpu/custom-properties)

### Stars

[**59** stars](/zig-gamedev/zgpu/stargazers)

### Watchers

[**4** watching](/zig-gamedev/zgpu/watchers)

### Forks

[**25** forks](/zig-gamedev/zgpu/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fzig-gamedev%2Fzgpu&report=zig-gamedev+%28user%29)

## [Releases](/zig-gamedev/zgpu/releases)

No releases published

## [Packages 0](/orgs/zig-gamedev/packages?repo_name=zgpu)

### Uh oh!

There was an error while loading. Please reload this page.

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors 7](/zig-gamedev/zgpu/graphs/contributors)

-   [![@hazeycode](https://avatars.githubusercontent.com/u/22148308?s=64&v=4)](https://github.com/hazeycode)
-   [![@kcbanner](https://avatars.githubusercontent.com/u/74892?s=64&v=4)](https://github.com/kcbanner)
-   [![@Copper280z](https://avatars.githubusercontent.com/u/6063379?s=64&v=4)](https://github.com/Copper280z)
-   [![@OndraVoves](https://avatars.githubusercontent.com/u/3593591?s=64&v=4)](https://github.com/OndraVoves)
-   [![@CoffeeImpliesCode](https://avatars.githubusercontent.com/u/36673499?s=64&v=4)](https://github.com/CoffeeImpliesCode)
-   [![@ckrowland](https://avatars.githubusercontent.com/u/95145274?s=64&v=4)](https://github.com/ckrowland)
-   [![@Logickin-Lambda](https://avatars.githubusercontent.com/u/118601127?s=64&v=4)](https://github.com/Logickin-Lambda)

## Languages

-   [C++ 35.5%](/zig-gamedev/zgpu/search?l=c%2B%2B)
-   [Zig 33.2%](/zig-gamedev/zgpu/search?l=zig)
-   [C 30.7%](/zig-gamedev/zgpu/search?l=c)
-   [Objective-C 0.6%](/zig-gamedev/zgpu/search?l=objective-c)

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```

---

## Assistant (Plan · minimax-m2.5-free · 31.2s)

_Thinking:_

This is great. `zgpu` (zig-gamedev) is the most comprehensive option. It uses Dawn (Google's WebGPU implementation) and supports Linux via Vulkan.

Key points:
1. It builds on top of `zglfw` (Zig bindings for GLFW) for window creation
2. On Linux it uses Vulkan backend for WebGPU
3. The example shows creating a GraphicsContext with window provider

This is a solid option. Let me also check what zglfw provides for windowing:

**Tool: websearch**

**Input:**
```json
{
  "query": "zglfw Zig GLFW binding Linux Wayland 2025"
}
```

**Output:**
```
Title: GitHub - Batres3/zlfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Author: Batres3
Published Date: 2025-03-09T00:00:00.000Z
URL: https://github.com/batres3/zlfw
Text: # Repository: Batres3/zlfw

Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.

- Stars: 13
- Forks: 4
- Watchers: 13
- Open issues: 0
- Primary language: Zig
- Languages: Zig
- License: MIT License (MIT)
- Default branch: main
- Created: 2025-03-09T23:42:46Z
- Last push: 2026-02-16T15:15:55Z
- Contributors: 4 (top: Batres3, siniarskimar, FalsePattern, RespiteFromReality)
- Archived: true

---

This repo is no longer actively maintaned, I created this mostly as a learning tool for zig, and no longer have any interest in maintining/developing a glfw clone in zig, I will leave this archived in case anyone else would like to make their own version of it.

# zlfw

This package is meant to be entirely equivalent to using the C code direcly in terms of performance, while keeping a nice ziggified API.

The advantages it offers over C are pretty clear:
 * __Enums__, unlike GLFW, you always know what a function can accept, for example `window.getKey(.a)` instead

Title: GitHub - Informa-Tiger/glfw-zig
Author: Informa-Tiger
Published Date: 2025-03-12T15:00:36.000Z
URL: https://github.com/informa-tiger/glfw-zig
Text: GitHub - Informa-Tiger/glfw-zig
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
Informa-Tiger/**glfw-zig**Public
* NotificationsYou must be signed in to change notification settings
* Fork1
* Star0
0stars1forkBranchesTagsActivity
Star
NotificationsYou must be signed in to change notification settings
# Informa-Tiger

Title: GitHub - AshishBhattarai/mach-glfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Author: AshishBhattarai
Published Date: 2024-05-22T00:00:00.000Z
URL: https://github.com/ashishbhattarai/mach-glfw
Text: # Repository: AshishBhattarai/mach-glfw

Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.

- Stars: 4
- Forks: 1
- Watchers: 4
- Open issues: 0
- Primary language: Zig
- Languages: Zig
- License: Other (NOASSERTION)
- Default branch: main
- Created: 2024-05-22T03:25:10Z
- Last push: 2025-09-25T19:35:21Z
- Contributors: 40 (top: InKryption, alichraghi, wrench-bot, castholm, AshishBhattarai, iddev5, leecannon, Avokadoen, PiergiorgioZagaria, BratishkaErik)

---

# GLFW binding for zig

This repository is a fork of the now-discontinued mach-glfw.

## Features

- Zero-fuss installation, cross-compilation at the flip of a switch, and broad platform support.
- 100% API coverage. Every function, type, constant, etc. has been exposed in a ziggified API.

## What does a ziggified GLFW API offer?

- **Enums**, always know what value a GLFW function can accept as everything is strictly typed. And use the nice Zig syntax to access

Title: GitHub - RickGraveyard/PlugInZ.GLFW: GLFW with zig build
Author: RickGraveyard
Published Date: 2024-11-16T00:00:00.000Z
URL: https://github.com/rickgraveyard/pluginz.glfw
Text: # Repository: RickGraveyard/PlugInZ.GLFW

GLFW with zig build

- Stars: 1
- Forks: 0
- Watchers: 1
- Open issues: 0
- Primary language: Zig
- Languages: Zig
- License: zlib License (Zlib)
- Default branch: main
- Archived: true

Title: GitHub - IridescenceTech/zglfw: A thin, idiomatic wrapper for GLFW. Written in Zig, for Zig!
Author: IridescenceTech
Published Date: 2020-09-17T00:00:00.000Z
URL: https://github.com/IridescenceTech/zglfw
Text: GitHub - IridescenceTech/zglfw: A thin, idiomatic wrapper for GLFW. Written in Zig, for Zig!
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

IridescenceTech

/
**
zglfw
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
11

*

Star
76

*
A thin, idioma

Title: GitHub - hexops/glfw: A fork of GLFW packaged for the Zig build system
Author: hexops
Published Date: 2023-04-05T00:00:00.000Z
URL: https://github.com/hexops/glfw
Text: GitHub - hexops/glfw: A fork of GLFW packaged for the Zig build system
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

hexops

/
**
glfw
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
25

*

Star
13

*
A fork of GLFW packaged for the Zig build system
### License

Zlib license


13
stars
 

Title: Search code, repositories, users, issues, pull requests...
Author: FalsePattern
Published Date: 2023-06-17T00:00:00.000Z
URL: https://github.com/FalsePattern/zig-glfw
Text: # Repository: FalsePattern/zig-glfw (fork of Avokadoen/mach-glfw)

Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.

- Stars: 9
- Forks: 1
- Watchers: 9
- Open issues: 3
- Primary language: Zig
- Languages: Zig (99.7%), Nix (0.2%), Shell
- License: Other (NOASSERTION)
- Topics: gamedev, glfw, zig, zig-package, ziglang
- Default branch: main
- Created: 2023-06-17T17:10:45Z
- Last push: 2025-03-21T10:18:39Z
- Contributors: 40 (top: InKryption, alichraghi, wrench-bot, FalsePattern, terraquad, castholm, iddev5, leecannon, Avokadoen, PiergiorgioZagaria)

---

# zig-glfw

Perfected GLFW bindings for Zig, with 100% API coverage, zero-fuss installation, cross compilation, and more.

## Features

- Zero-fuss installation, cross-compilation at the flip of a switch, and broad platform support.
- 100% API coverage. Every function, type, constant, etc. has been exposed in a ziggified API.

## Community maintained

The Mach engine project no longer uses GLFW, and so this project is now community-maintained. Pull re

Title: GLFW window not appearing using vs code (im in arch ...
Author: Spicy Shallots
URL: https://stackoverflow.com/questions/79611184/glfw-window-not-appearing-using-vs-code-im-in-arch-linux-using-plasma-wayland
Text: # GLFW window not appearing using vs code (im in arch linux using plasma wayland)

- Tags: c++, vulkan, glfw, glm-math, wayland
- Score: -1
- Views: 234
- Answers: 1
- Asked by: Spicy Shallots (1 rep)
- Asked on: May 7, 2025
- Last active: May 25, 2025
- License: CC BY-SA 4.0

---

## Question

I can see an icon in my dock (icons-only task manager) but i can't see it i can hover it and yes it's the Vulkan window.

```
#include <vulkan/vulkan.h>
#include <GLFW/glfw3.h>
#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include <glm/glm.hpp>
#include <iostream>
#include <vector>

int main() {
    glfwInit();

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow* window = glfwCreateWindow(800, 600, "Vulkan window", nullptr, nullptr);

    uint32_t extensionCount = 0;
    vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, nullptr);

    std::cout << extensionCount << " extensions supported\n";

    glm::mat4 matrix;
    glm::vec4 vec;
    auto test = matrix * vec;

    while(!glf


```

---

## Assistant (Plan · minimax-m2.5-free · 12.8s)

_Thinking:_

Good. So the options are:

1. **zig-gamedev/zgpu** - WebGPU via Dawn (Vulkan on Linux) - this is the main option
2. **IridescenceTech/zglfw** - Zig GLFW bindings (for window management)
3. **mach-gpu** - Another WebGPU option from the Mach engine
4. **AshishBhattarai/mach-glfw** - Community-maintained GLFW bindings

The stack would be:
- **zglfw** (or similar) for window creation
- **zgpu** (or **mach-gpu**) for WebGPU rendering
- **Dawn** (built into zgpu) provides the Vulkan backend on Linux

This should work natively on Wayland without the GLFW/X11/GLX issues!

Let me check what system dependencies are needed for Dawn/Vulkan on Linux:

**Tool: webfetch**

**Input:**
```json
{
  "format": "markdown",
  "url": "https://github.com/zig-gamedev/zgpu/blob/main/README.md"
}
```

**Output:**
```
                        zgpu/README.md at main · zig-gamedev/zgpu · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fzig-gamedev%2Fzgpu%2Fblob%2Fmain%2FREADME.md)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fzig-gamedev%2Fzgpu%2Fblob%2Fmain%2FREADME.md)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E%2Fblob%2Fshow&source=header-repo&source_repo=zig-gamedev%2Fzgpu)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[zig-gamedev](/zig-gamedev) / **[zgpu](/zig-gamedev/zgpu)** Public

-   [Notifications](/login?return_to=%2Fzig-gamedev%2Fzgpu) You must be signed in to change notification settings
-   [Fork 25](/login?return_to=%2Fzig-gamedev%2Fzgpu)
-   [Star 59](/login?return_to=%2Fzig-gamedev%2Fzgpu)
    

-   [Code](/zig-gamedev/zgpu)
-   [Issues 8](/zig-gamedev/zgpu/issues)
-   [Pull requests 2](/zig-gamedev/zgpu/pulls)
-   [Actions](/zig-gamedev/zgpu/actions)
-   [Projects](/zig-gamedev/zgpu/projects)
-   [Security 0](/zig-gamedev/zgpu/security)
-   [Insights](/zig-gamedev/zgpu/pulse)

Additional navigation options

-   [Code](/zig-gamedev/zgpu)
-   [Issues](/zig-gamedev/zgpu/issues)
-   [Pull requests](/zig-gamedev/zgpu/pulls)
-   [Actions](/zig-gamedev/zgpu/actions)
-   [Projects](/zig-gamedev/zgpu/projects)
-   [Security](/zig-gamedev/zgpu/security)
-   [Insights](/zig-gamedev/zgpu/pulse)

 [](/zig-gamedev/zgpu)

## FilesExpand file tree

 main

## Breadcrumbs

1.  [zgpu](/zig-gamedev/zgpu/tree/main)

/

# README.md

Copy path

BlameMore file actions

BlameMore file actions

## Latest commit

## History

[History](/zig-gamedev/zgpu/commits/main/README.md)

[](/zig-gamedev/zgpu/commits/main/README.md)History

183 lines (138 loc) · 6.04 KB

 main

## Breadcrumbs

1.  [zgpu](/zig-gamedev/zgpu/tree/main)

/

# README.md

Top

## File metadata and controls

-   Preview
    
-   Code
    
-   Blame
    

183 lines (138 loc) · 6.04 KB

[Raw](https://github.com/zig-gamedev/zgpu/raw/refs/heads/main/README.md)

Copy raw file

Download raw file

Outline

Edit and raw actions

# [zgpu](https://github.com/zig-gamedev/zgpu)

[](#zgpu)

Cross-platform graphics lib for Zig built on top of [Dawn](https://github.com/zig-gamedev/dawn) native WebGPU implementation.

Supports Windows 10+ (DirectX 12), macOS 12+ (Metal) and Linux (Vulkan).

## Features

[](#features)

-   Zero-overhead wgpu API bindings ([source code](https://github.com/zig-gamedev/zgpu/blob/main/src/wgpu.zig))
-   Uniform buffer pool for fast CPU->GPU transfers
-   Resource pools and handle-based GPU resources
-   Async shader compilation
-   GPU mipmap generator

## Getting started

[](#getting-started)

Example `build.zig`:

pub fn build(b: \*std.Build) void {
    const exe \= b.addExecutable(.{ ... });

    @import("zgpu").addLibraryPathsTo(exe);

    const zgpu \= b.dependency("zgpu", .{});
    exe.root\_module.addImport("zgpu", zgpu.module("root"));

    if (target.result.os.tag != .emscripten) {
      exe.linkLibrary(zgpu.artifact("zdawn"));
    }
}

## Sample applications

[](#sample-applications)

-   [gui test (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/gui_test_wgpu)
-   [physically based rendering (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/physically_based_rendering_wgpu)
-   [bullet physics test (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/bullet_physics_test_wgpu)
-   [procedural mesh (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/procedural_mesh_wgpu)
-   [textured quad (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/textured_quad_wgpu)
-   [triangle (wgpu)](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples/triangle_wgpu)

## Library overview

[](#library-overview)

Below you can find an overview of main `zgpu` features.

### Compile-time options

[](#compile-time-options)

You can override default options in your `build.zig`:

pub fn build(b: \*std.Build) void {
    ...

    const zgpu \= @import("zgpu").package(b, target, optimize, .{
        .options \= .{
            .uniforms\_buffer\_size \= 4 \* 1024 \* 1024,
            .dawn\_skip\_validation \= false,
            .buffer\_pool\_size \= 256,
            .texture\_pool\_size \= 256,
            .texture\_view\_pool\_size \= 256,
            .sampler\_pool\_size \= 16,
            .render\_pipeline\_pool\_size \= 128,
            .compute\_pipeline\_pool\_size \= 128,
            .bind\_group\_pool\_size \= 32,
            .bind\_group\_layout\_pool\_size \= 32,
            .pipeline\_layout\_pool\_size \= 32,
        },
    });

    zgpu.link(exe);

    ...
}

### Graphics Context

[](#graphics-context)

Create a `GraphicsContext` using a `WindowProvider`. For example, using [zglfw](https://github.com/zig-gamedev/zglfw):

const gctx \= try zgpu.GraphicsContext.create(
    allocator,
    .{
        .window \= window,
        .fn\_getTime \= @ptrCast(&zglfw.getTime),
        .fn\_getFramebufferSize \= @ptrCast(&zglfw.Window.getFramebufferSize),

        // optional fields
        .fn\_getWin32Window \= @ptrCast(&zglfw.getWin32Window),
        .fn\_getX11Display \= @ptrCast(&zglfw.getX11Display),
        .fn\_getX11Window \= @ptrCast(&zglfw.getX11Window),
        .fn\_getWaylandDisplay \= @ptrCast(&zglfw.getWaylandDisplay),
        .fn\_getWaylandSurface \= @ptrCast(&zglfw.getWaylandWindow),
        .fn\_getCocoaWindow \= @ptrCast(&zglfw.getCocoaWindow),
    },
    .{}, // default context creation options
);

### Uniforms

[](#uniforms)

-   Implemented as a uniform buffer pool
-   Easy to use
-   Efficient - only one copy operation per frame

struct DrawUniforms \= extern struct {
    object\_to\_world: zm.Mat,
};
const mem \= gctx.uniformsAllocate(DrawUniforms, 1);
mem.slice\[0\] \= .{ .object\_to\_world \= zm.transpose(zm.translation(...)) };

pass.setBindGroup(0, bind\_group, &.{mem.offset});
pass.drawIndexed(...);

// When you are done encoding all commands for a frame:
gctx.submit(...); // Injects \*one\* copy operation to transfer \*all\* allocated uniforms

### Resource pools

[](#resource-pools)

-   Every GPU resource is identified by 32-bit integer handle
-   All resources are stored in one system
-   We keep basic info about each resource (size of the buffer, format of the texture, etc.)
-   You can always check if resource is valid (very useful for async operations)
-   System keeps basic info about resource dependencies, for example, `TextureViewHandle` knows about its parent texture and becomes invalid when parent texture becomes invalid; `BindGroupHandle` knows about all resources it binds so it becomes invalid if any of those resources become invalid

const buffer\_handle \= gctx.createBuffer(...);

if (gctx.isResourceValid(buffer\_handle)) {
    const buffer \= gctx.lookupResource(buffer\_handle).?;  // Returns \`wgpu.Buffer\`

    const buffer\_info \= gctx.lookupResourceInfo(buffer\_handle).?; // Returns \`zgpu.BufferInfo\`
    std.debug.print("Buffer size is: {d}", .{buffer\_info.size});
}

// If you want to destroy a resource before shutting down graphics context:
gctx.destroyResource(buffer\_handle);

### Async shader compilation

[](#async-shader-compilation)

-   Thanks to resource pools and resources identified by handles we can easily async compile all our shaders

const DemoState \= struct {
    pipeline\_handle: zgpu.PipelineLayoutHandle \= .{},
    ...
};
const demo \= try allocator.create(DemoState);

// Below call schedules pipeline compilation and returns immediately. When compilation is complete
// valid pipeline handle will be stored in \`demo.pipeline\_handle\`.
gctx.createRenderPipelineAsync(allocator, pipeline\_layout, pipeline\_descriptor, &demo.pipeline\_handle);

// Pass using our pipeline will be skipped until compilation is ready
pass: {
    const pipeline \= gctx.lookupResource(demo.pipeline\_handle) orelse break :pass;
    ...

    pass.setPipeline(pipeline);
    pass.drawIndexed(...);
}

### Mipmap generation on the GPU

[](#mipmap-generation-on-the-gpu)

-   wgpu API does not provide mipmap generator
-   zgpu provides decent mipmap generator implemented in a compute shader
-   It supports 2D textures, array textures and cubemap textures of any format (`rgba8_unorm`, `rg16_float`, `rgba32_float`, etc.)
-   Currently it requires that: `texture_width == texture_height and isPowerOfTwo(texture_width)`
-   It takes ~260 microsec to generate all mips for 1024x1024 `rgba8_unorm` texture on GTX 1660

// Usage:
gctx.generateMipmaps(arena, command\_encoder, texture\_handle);

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```

---

## Assistant (Plan · minimax-m2.5-free · 20.3s)

_Thinking:_

Now I have a good picture. Let me put together a plan for the user. The key insight is:

1. **zgpu** provides WebGPU bindings via Dawn
2. On Linux, Dawn uses **Vulkan** as the backend
3. It works with **zglfw** for window creation
4. This avoids all the GLFW/GLX/EGL issues we've been debugging

The setup would be:
- **zglfw** - for window creation (supports Wayland natively)
- **zgpu** - for WebGPU rendering (uses Vulkan on Linux)
- **dawn** - the WebGPU implementation (bundled with zgpu)

On your system with NVIDIA + Vulkan, this should just work because:
- Vulkan works natively on Wayland
- NVIDIA has excellent Vulkan driver support
- No X11/XWayland/GLX/EGL complexity

Let me provide a plan for this approach.

Based on my research, here's a plan for creating WebGPU bindings:

## WebGPU Binding Plan

### Recommended Stack
| Component | Purpose | Repository |
|-----------|---------|------------|
| **zglfw** | Window creation (supports Wayland natively) | `IridescenceTech/zglfw` |
| **zgpu** | WebGPU rendering via Dawn | `zig-gamedev/zgpu` |
| **Dawn** | WebGPU implementation (Vulkan backend on Linux) | bundled with zgpu |

### Why This Works on Your Setup
- **WebGPU → Vulkan** on Linux (no GLX/EGL)
- **Vulkan** works natively on Wayland
- **NVIDIA** has excellent Vulkan driver support
- No X11/XWayland → no compositor rendering issues

### Steps to Implement
1. **Add dependencies** to `build.zig.zon`:
   - `zglfw` (window management)
   - `zgpu` (WebGPU)

2. **Update `build.zig`** to link the artifacts:
   - Add `zglfw` import for window creation
   - Add `zgpu` dependency + link `zdawn` artifact

3. **Rewrite `main.zig`** to use WebGPU:
   - Create window with `zglfw`
   - Create `GraphicsContext` with `zgpu`
   - Render using WebGPU pipeline (shaders, render passes, etc.)

### System Dependencies (already installed)
- Vulkan: `pacman -Q vulkan-icd-loader` (you have this)
- NVIDIA Vulkan: `pacman -Q vulkan-nvidia` (you have this)

### Example Structure
```zig
const zglfw = @import("zglfw");
const zgpu = @import("zgpu");

// Create window
const window = try zglfw.Window.create(...)
defer window.destroy();

// Create graphics context  
const gctx = try zgpu.GraphicsContext.create(allocator, .{ .window = window, ... });

// Render loop
while (!window.shouldClose()) {
    // WebGPU render pass
    gctx.submit(...);
}
```

This should bypass all the GLFW/GLX/XWayland issues entirely. Want me to proceed with implementing this?

---

## User

what about wgpu_native_zig?

---

## Assistant (Plan · minimax-m2.5-free · 10.8s)

_Thinking:_

The user is asking about `wgpu_native_zig` - let me search for information about this repository to compare it with the other options.

**Tool: webfetch**

**Input:**
```json
{
  "format": "markdown",
  "url": "https://github.com/bronter/wgpu_native_zig"
}
```

**Output:**
```
                        GitHub - bronter/wgpu\_native\_zig: Zig bindings for wgpu-native · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fbronter%2Fwgpu_native_zig)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fbronter%2Fwgpu_native_zig)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=bronter%2Fwgpu_native_zig)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[bronter](/bronter) / **[wgpu\_native\_zig](/bronter/wgpu_native_zig)** Public

-   [Notifications](/login?return_to=%2Fbronter%2Fwgpu_native_zig) You must be signed in to change notification settings
-   [Fork 24](/login?return_to=%2Fbronter%2Fwgpu_native_zig)
-   [Star 110](/login?return_to=%2Fbronter%2Fwgpu_native_zig)
    

-   [Code](/bronter/wgpu_native_zig)
-   [Issues 5](/bronter/wgpu_native_zig/issues)
-   [Pull requests 7](/bronter/wgpu_native_zig/pulls)
-   [Discussions](/bronter/wgpu_native_zig/discussions)
-   [Actions](/bronter/wgpu_native_zig/actions)
-   [Projects](/bronter/wgpu_native_zig/projects)
-   [Security 0](/bronter/wgpu_native_zig/security)
-   [Insights](/bronter/wgpu_native_zig/pulse)

Additional navigation options

-   [Code](/bronter/wgpu_native_zig)
-   [Issues](/bronter/wgpu_native_zig/issues)
-   [Pull requests](/bronter/wgpu_native_zig/pulls)
-   [Discussions](/bronter/wgpu_native_zig/discussions)
-   [Actions](/bronter/wgpu_native_zig/actions)
-   [Projects](/bronter/wgpu_native_zig/projects)
-   [Security](/bronter/wgpu_native_zig/security)
-   [Insights](/bronter/wgpu_native_zig/pulse)

 [](/bronter/wgpu_native_zig)

# bronter/wgpu\_native\_zig

 main

[Branches](/bronter/wgpu_native_zig/branches)[Tags](/bronter/wgpu_native_zig/tags)

[](/bronter/wgpu_native_zig/branches)[](/bronter/wgpu_native_zig/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[165 Commits](/bronter/wgpu_native_zig/commits/main/)

[](/bronter/wgpu_native_zig/commits/main/)165 Commits

[examples](/bronter/wgpu_native_zig/tree/main/examples "examples")

[examples](/bronter/wgpu_native_zig/tree/main/examples "examples")

[src](/bronter/wgpu_native_zig/tree/main/src "src")

[src](/bronter/wgpu_native_zig/tree/main/src "src")

[tests](/bronter/wgpu_native_zig/tree/main/tests "tests")

[tests](/bronter/wgpu_native_zig/tree/main/tests "tests")

[.gitignore](/bronter/wgpu_native_zig/blob/main/.gitignore ".gitignore")

[.gitignore](/bronter/wgpu_native_zig/blob/main/.gitignore ".gitignore")

[LICENSE](/bronter/wgpu_native_zig/blob/main/LICENSE "LICENSE")

[LICENSE](/bronter/wgpu_native_zig/blob/main/LICENSE "LICENSE")

[README.md](/bronter/wgpu_native_zig/blob/main/README.md "README.md")

[README.md](/bronter/wgpu_native_zig/blob/main/README.md "README.md")

[build.zig](/bronter/wgpu_native_zig/blob/main/build.zig "build.zig")

[build.zig](/bronter/wgpu_native_zig/blob/main/build.zig "build.zig")

[build.zig.zon](/bronter/wgpu_native_zig/blob/main/build.zig.zon "build.zig.zon")

[build.zig.zon](/bronter/wgpu_native_zig/blob/main/build.zig.zon "build.zig.zon")

[test-all](/bronter/wgpu_native_zig/blob/main/test-all "test-all")

[test-all](/bronter/wgpu_native_zig/blob/main/test-all "test-all")

View all files

## Repository files navigation

-   [README](#)
-   [MIT license](#)

# wgpu\_native\_zig

[](#wgpu_native_zig)

Zig bindings for [wgpu-native](https://github.com/gfx-rs/wgpu-native)

This package exposes two modules: `wgpu-c` and `wgpu`.

`wgpu-c` is just `wgpu.h` (and by extension `webgpu.h`) run through `translate-c`, so as close to wgpu-native's original C API as is possible in Zig.

`wgpu` is a module full of pure Zig bindings for `libwgpu_native`, it does not import any C code and instead relies on `extern fn` declarations to hook up to `wgpu-native`.

## Adding this package to your build

[](#adding-this-package-to-your-build)

Add the package to your dependencies, either with:

zig fetch --save https://github.com/bronter/wgpu\_native\_zig/archive/refs/tags/v6.5.0.tar.gz

or by manually adding to your `build.zig.zon`:

.{
    // ...other stuff
    .dependencies \= .{
        // ...other dependencies
        .wgpu\_native\_zig \= .{
            // You can either use a commit hash:
            .url\="https://github.com/bronter/wgpu\_native\_zig/archive/<commit\_hash>.tar.gz",
            // or a tagged release:
            // .url = "https://github.com/bronter/wgpu\_native\_zig/archive/refs/tags/v6.5.0.tar.gz\`
            .hash\="<dependency hash>"
        }
    }
}

Then, in `build.zig` add:

    const wgpu\_native\_dep \= b.dependency("wgpu\_native\_zig", .{});

    // Add module to your exe (wgpu-c can also be added like this, just pass in "wgpu-c" instead)
    exe.root\_module.addImport("wgpu", wgpu\_native\_dep.module("wgpu"));
    // Or, add to your lib similarly:
    lib.root\_module.addImport("wgpu", wgpu\_native\_dep.module("wgpu"));

### Building on Windows

[](#building-on-windows)

Windows x86\_64 has two options for ABI: GNU and MSVC. For i686 and aarch64, only the MSVC option is available. If you need to specify the build target, you can do that with:

const target \= b.standardTargetOptions(.{
    .default\_target \= .{
        // If not specified, defaults to the GNU abi
        .abi \= .msvc,
    }
});

Or, specify it with your build command. For example, the triangle example in this repository can be run like so:

zig build run-triangle-example -Dtarget=x86\_64-windows-msvc

Either way, pass the resolved target to the dependency like so:

const wgpu\_native\_dep \= b.dependency("wgpu\_native\_zig", .{
  .target \= target
});

When using static linking with MSVC, you might encounter duplicate symbol errors. If so, try

if (target.result.abi \== .msvc) {
  // "exe" here is the \*std.Build.Step.Compile from b.addExecutable() (or b.addTest())
  exe.bundle\_compiler\_rt \= false;
  exe.bundle\_ubsan\_rt \= false;
}

An example of using `wgpu-native-zig` with static linking on Windows can be found at [wgpu-native-zig-windows-test](https://github.com/bronter/wgpu-native-zig-windows-test).

### Dynamic linking

[](#dynamic-linking)

Dynamic linking can be made to work, though it is a bit messy to use. When you initialize your `wgpu_native_dep`, add the option for dynamic linking like so:

const wgpu\_native\_dep \= b.dependency("wgpu\_native\_zig", .{
  // Defaults to .static if you don't specify
  .link\_mode \= .dynamic
});

Then add the following with your install step dependencies:

const lib\_dir \= wgpu\_native\_dep.namedWriteFiles("lib").getDirectory();

// This would also work with .so files on linux
const dll\_path \= lib\_dir.join(b.allocator, "wgpu\_native.dll") catch return;

// addInstallBinFile puts the dll in the same directory as your executable
const install\_dll \= b.addInstallBinFile(dll\_path, "wgpu\_native.dll");

// Make sure that the dll is installed when the install step is run
b.getInstallStep().dependOn(&install\_dll.step);

## How the `wgpu` module differs from `wgpu-c`

[](#how-the-wgpu-module-differs-from-wgpu-c)

-   Names are shortened to remove redundancy.
    -   For example `wgpu.WGPUSurfaceDescriptor` becomes `wgpu.SurfaceDescriptor`
-   C pointers (`[*c]`) are replaced with more specific pointer types.
    -   For example `[*c]const u8` is replaced with `?[*:0]const u8`.
-   Pointers to opaque structs are made explicit (and only optional when they need to be).
    -   For example `wgpu.WGPUAdapter` from `webgpu.h` would instead be expressed as `*wgpu.Adapter` or `?*wgpu.Adapter`, depending on the context.
-   Methods are expressed as decls inside of structs
    -   For example
        
        wgpu.wgpuInstanceCreateSurface(instance: WGPUInstance, descriptor: \[\*c\]const WGPUSurfaceDescriptor) WGPUSurface
        
        becomes
        
        Instance.createSurface(self: \*Instance, descriptor: \*const SurfaceDescriptor) ?\*Surface
        
-   Certain asynchronous methods such as requestAdapter and requestDevice are provided with wrapper methods.
    -   For example, requesting an adapter with a callback looks something like
        
        fn handleRequestAdapter(
            status: RequestAdapterStatus,
            adapter: ?\*Adapter,
            message: StringView,
            userdata1: ?\*anyopaque,
            userdata2: ?\*anyopaque
        ) callconv(.C) void {
            switch(status) {
                .success \=\> {
                    const ud\_adapter: \*\*Adapter \= @ptrCast(@alignCast(userdata1));
                    ud\_adapter.\* \= adapter.?;
                },
                else \=\> {
                  std.log.err("{s}\\n", .{message.toSlice()});
                }
            }
            const completed: \*bool \= @ptrCast(@alignCast(userdata2));
            completed.\* \= true;
        }
        var adapter\_ptr: ?\*Adapter \= null;
        var completed \= false;
        const request\_adapter\_info \= RequestAdapterInfo {
            .callback \= handleRequestAdapter,
            .userdata1 \= @ptrCast(&adapter\_ptr),
            .userdata2 \= @ptrCast(&completed),
        }
        const ra\_future \= instance.requestAdapter(null, request\_adapter\_info);
        
        // There is currently no way to use a \`Future\`,
        // it's supposed to be passed into \`Instance.waitAny()\`,
        // which is unimplemented as of \`wgpu\_native\` v24.0.3.1.
        \_ \= ra\_future; 
        
        instance.processEvents();
        while(!completed) {
          std.Thread.sleep(200\_000\_000);
          instance.processEvents();
        }
        
        whereas the non-callback version looks like
        
        // The wrapper methods use polling, so 200\_000\_000 is the polling interval in nanoseconds.
        const response \= instance.requestAdapterSync(null, 200\_000\_000);
        
        const adapter\_ptr: ?\*Adapter \= switch (response.status) {
            .success \=\> response.adapter,
            else \=\> blk: {
                std.log.err("{s}\\n", .{response.message});
                break :blk null;
            }
        };
        
-   Chained structs are provided with inline functions for constructing them, which come in two forms depending on whether or not the chained struct is likely to always be required.
    -   For required chained structs, you can either write them explicitely:
        
        SurfaceDescriptor{
            .next\_in\_chain \= @ptrCast(&SurfaceDescriptorFromXlibWindow {
                .chain \= ChainedStruct {
                    .s\_type \= SType.surface\_descriptor\_from\_xlib\_window,
                },
                .display \= display,
                .window \= window,
            }),
            .label \= "xlib\_surface\_descriptor",
        };
        
        or use a function to construct them:
        
        // Here the descriptors from SurfaceDescriptor and SurfaceDescriptorFromXlibWindow have been merged,
        // so just pass in an anonymous struct with the things that you need; default values will take care of the rest.
        surfaceDescriptorFromXlibWindow(.{
            .label \= "xlib\_surface\_descriptor",
            .display \= display,
            .window \= window
        });
        
    -   For optional chained structs, you can either write them explicitely like in the example above, or you can use a method of the parent struct instance to add them, for example:
        
        &(SurfaceConfiguration {
          .device \= device,
          // other stuff
        }).withDesiredMaxFrameLatency(2);
        
-   `WGPUBool` is replaced with `bool` whenever possible.
    -   This pretty much means, it is replaced with `bool` in the parameters and return values of methods, but not in structs or the parameters/return values of procs (which are supposed to be function pointers to things returned by `wgpuGetProcAddress`).

## TODO

[](#todo)

-   Test this on other machines with different OS/CPU. Currently only tested on x86\_64-linux-gnu and x86\_64-windows (msvc and gnu); zig version 0.14.0.
-   Cleanup/organization:
    -   If types are only tied to a specific opaque struct, they should be decls inside that struct.
    -   The associated Procs struct should probably be a decl of the opaque struct as well.
    -   There are many things that seem to be in the wrong file.
        -   For example a lot of what is in `pipeline.zig` is actually only used by `Device`, and should probably be in `device.zig` instead.
    -   Since pointers to opaque structs are made explicit, it would be more consistent if pointers to callback functions are explicit as well.
-   Port [wgpu-native-examples](https://github.com/samdauwe/webgpu-native-examples) using wrapper code, as a basic form of documentation.
-   Custom-build `wgpu-native`; provided all the necessary tools/dependencies are present.
-   Bindgen using [the webgpu-headers yaml](https://github.com/webgpu-native/webgpu-headers/blob/main/webgpu.yml)?
-   The proc definitions are mainly there since they are also present in the webgpu headers and I didn't fully understand what they were for when I started working on this project. However, I know better now and they aren't really used for anything currently. They're supposed to be used with `wgpuGetProcAddress` but it's [unimplemented in `wgpu-native`](https://github.com/gfx-rs/wgpu-native/issues/223). They are a pain to update by hand, so maybe they should be removed for now and made optional once we have a working bindings generator? Like the bindgen could put them in a separate `wgpu-procs` module.

## About

Zig bindings for wgpu-native

### Topics

[zig-package](/topics/zig-package "Topic: zig-package") [wgpu-native](/topics/wgpu-native "Topic: wgpu-native")

### Resources

[Readme](#readme-ov-file)

### License

[MIT license](#MIT-1-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/bronter/wgpu_native_zig/activity)

### Stars

[**110** stars](/bronter/wgpu_native_zig/stargazers)

### Watchers

[**5** watching](/bronter/wgpu_native_zig/watchers)

### Forks

[**24** forks](/bronter/wgpu_native_zig/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fbronter%2Fwgpu_native_zig&report=bronter+%28user%29)

## [Releases 15](/bronter/wgpu_native_zig/releases)

[

v6.5.0 Latest

Jul 17, 2025



](/bronter/wgpu_native_zig/releases/tag/v6.5.0)

[\+ 14 releases](/bronter/wgpu_native_zig/releases)

## [Packages 0](/users/bronter/packages?repo_name=wgpu_native_zig)

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors 4](/bronter/wgpu_native_zig/graphs/contributors)

-    [![@bronter](https://avatars.githubusercontent.com/u/12648711?s=64&v=4)](https://github.com/bronter)[**bronter** Gabriel Charleboix](https://github.com/bronter)
-    [![@hollinwilkins](https://avatars.githubusercontent.com/u/15824835?s=64&v=4)](https://github.com/hollinwilkins)[**hollinwilkins** Hollin Wilkins](https://github.com/hollinwilkins)
-    [![@MrHappines](https://avatars.githubusercontent.com/u/6771149?s=64&v=4)](https://github.com/MrHappines)[**MrHappines**](https://github.com/MrHappines)
-    [![@Batres3](https://avatars.githubusercontent.com/u/81390369?s=64&v=4)](https://github.com/Batres3)[**Batres3** Batres](https://github.com/Batres3)

## Languages

-   [Zig 99.5%](/bronter/wgpu_native_zig/search?l=zig)
-   Other 0.5%

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```

---

## Assistant (Plan · minimax-m2.5-free · 32.2s)

_Thinking:_

This is interesting - `wgpu_native_zig` uses `wgpu-native` (from gfx-rs) instead of Dawn. Let me summarize the differences:

**wgpu_native_zig**:
- Uses `wgpu-native` (gfx-rs) as the backend
- Provides two modules:
  - `wgpu-c`: Direct C bindings to wgpu-native
  - `wgpu`: Pure Zig bindings 
- Supports Windows (MSVC/GNU), Linux, and likely macOS
- Last update: July 2025 (v6.5.0)
- Stars: 110

**zgpu (zig-gamedev)**:
- Uses Dawn (Google) as the backend
- More features: uniform buffer pool, resource pools, async shader compilation, mipmap generator
- Supports Windows (DirectX 12), macOS (Metal), Linux (Vulkan)
- Stars: 59

The key difference is the backend:
- **wgpu-native**: Rust-based, also used by Firefox
- **Dawn**: C++-based, used by Chrome

Both use Vulkan on Linux. The choice between them might come down to:
1. Which one builds easier with Zig
2. Which API you prefer
3. Which one has better support for your specific needs

Let me present this comparison to the user.

Good question! Here's the comparison:

## WebGPU Binding Options Comparison

| Aspect | `wgpu_native_zig` | `zgpu` (Dawn-based) |
|--------|-------------------|---------------------|
| **Backend** | wgpu-native (gfx-rs, Rust) | Dawn (Google, C++) |
| **Stars** | 110 | 59 |
| **Last Release** | v6.5.0 (Jul 2025) | Active development |
| **Modules** | `wgpu-c` (C bindings), `wgpu` (pure Zig) | Single unified module |
| **Linux Backend** | Vulkan | Vulkan |
| **Extra Features** | Basic bindings | Uniform buffer pool, resource pools, async shader compilation, mipmap generator |
| **Window Lib** | Must pair with zglfw | Pairs with zglfw |

## Key Differences

**wgpu-native (wgpu_native_zig):**
- More lightweight bindings
- Closer to the raw C API
- wgpu-native is what Firefox uses for WebGPU

**Dawn (zgpu):**
- More feature-rich (pools, async compilation, mipmaps)
- More batteries-included
- Dawn is what Chrome uses for WebGPU

## For Your Use Case

Both will work on your **NVIDIA + Wayland + Vulkan** setup. The choice comes down to:

1. **If you want minimal overhead** → `wgpu_native_zig`
2. **If you want more helper utilities** → `zgpu`

Both require pairing with **zglfw** for window creation.

---

Which would you prefer? Or would you like me to check if one builds more easily with your Zig version?

---

## User

can i create bindings by myself because i have problew with version for both

---

## Assistant (Plan · minimax-m2.5-free · 18.0s)

_Thinking:_

The user wants to create their own WebGPU bindings from scratch because they're having version compatibility issues with both wgpu_native_zig and zgpu. This is actually a great learning exercise and gives them full control over the binding.

Let me think about what's needed to create WebGPU bindings:

1. **WebGPU Headers** - Need `webgpu.h` and `wgpu.h` headers
2. **wgpu-native** - The actual library (wgpu-native by gfx-rs)
3. **Window creation** - Need something for window management (zglfw or custom)
4. **Vulkan backend** - WebGPU uses Vulkan on Linux

Let me search for what's needed to create bindings from scratch.


Yes! Creating your own bindings is a great approach for full control. Let me research what's needed:

**Tool: websearch**

**Input:**
```json
{
  "query": "wgpu-native library Linux how to build from source 2025"
}
```

**Output:**
```
Title: Getting Started · gfx-rs/wgpu-native Wiki
Author: gfx-rs
URL: https://github.com/gfx-rs/wgpu-native/wiki/Getting-Started
Text: Getting Started · gfx-rs/wgpu-native Wiki · GitHub
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

Appearance settings
Resetting focus
You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

gfx-rs

/
**
wgpu-native
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
142

*

Star
1.2k

# Getting Started
Jump to bottom
Almar Klein edited this page Jan 10, 2023
&middot;
4 r

Title: Releases · gfx-rs/wgpu-native
Author: gfx-rs
Published Date: 2025-03-20T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/releases
Text: Releases ·gfx-rs/wgpu-native ·GitHub
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
gfx-rs/**wgpu-native**Public
* NotificationsYou must be signed in to change notification settings
* Fork134
* Star1.2k
# Releases: gfx-rs/wgpu-native
 
Releases ·gfx-rs/wgpu-native
## v27.0.4.0
23 Dec 09:57
@github-actionsgithub-actions

Title: Building for older versions of linux · Issue #452 · gfx-rs/wgpu-native
Author: hmaarrfk
Published Date: 2025-01-19T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/issues/452
Text: # Issue: gfx-rs/wgpu-native #452

- Repository: gfx-rs/wgpu-native | Native WebGPU implementation based on wgpu-core | 1K stars | Rust

## Building for older versions of linux

- Author: @hmaarrfk
- State: closed (completed)
- Created: 2025-01-19T16:49:30Z
- Updated: 2025-01-20T16:30:43Z
- Closed: 2025-01-20T16:30:43Z
- Closed by: @hmaarrfk

I was asked to open an issue to discuss my successes in building wgpu-native for older GLIBC standards.

I'm mostly here to report the success i've had at conda-forge building wgpu-native for libc 2.17 at conda-forge wgpu-native is just providing binaries that wgpu-py reuses. I don't know that there is any specification for platform support. Also I don't maintain anything over here, just giving you some info.
> 
> Let me clarify: my intention was to be helpful :)

**@hmaarrfk** commented · Jan 19, 2025 at 10:27pm · Author

> Ok well if one uses Ubuntu based images you can apparently get it to work https://github.com/hmaarrfk/wgpu-native/pull/1
> 
> Not sure if this is an acceptable solution, I mostl

Title: WebGPU Engine Development
Author: thorvg
URL: https://github.com/thorvg/thorvg/wiki/WebGPU-Engine-Development
Text: WebGPU Engine Development ·thorvg/thorvg Wiki ·GitHub
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
thorvg/**thorvg**Public
* ### Uh oh!
There was an error while loading.Please reload this page.
* NotificationsYou must be signed in to change notification settings
* Fork181
* Star1.4k
# WebGPU Engine Development
Jump to bottom
Sergii Liebodkin ed

Title: Use manylinux2014 · Pull Request #453 · gfx-rs/wgpu-native
Author: almarklein
Published Date: 2025-01-20T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/pull/453
Text: # Pull Request: gfx-rs/wgpu-native #453

- Repository: gfx-rs/wgpu-native | Native WebGPU implementation based on wgpu-core | 1K stars | Rust

## Use manylinux2014

- Author: @almarklein
- Association: COLLABORATOR
- State: closed
- Draft: true
- Source branch: manylinux2014
- Target branch: trunk
- Mergeable: unstable
- Commits: 1
- Additions: 4
- Deletions: 4
- Changed files: 1
- Created: 2025-01-20T15:05:21Z
- Updated: 2025-02-28T09:30:39Z
- Closed: 2025-02-28T09:30:38Z

This is about the CD build. It fails :)

---

### Timeline

**Almar Klein** pushed commit `98d1553`: Use manylinux2014 · Jan 20, 2025 at 3:04pm

**almarklein** mentioned this in issue #452: Building for older versions of linux · Jan 20, 2025 at 3:50pm

**@hmaarrfk** commented · Jan 20, 2025 at 4:20pm

> I've kinda already debugged this avenue:
> 
> 1. `dnf` replaced `yum` in more recent centos's
> 2. the llvm included in centos7 is simply too old.
> 
> I necro'ed https://github.com/pypa/manylinux/issues/1728#issuecomment-2602817305 asking for newer toolsets, but we'll see.
> 
> 

Title: Pull requests · gfx-rs/wgpu-native
Author: gfx-rs
Published Date: 2025-05-08T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/pulls
Text: Pull requests · gfx-rs/wgpu-native · GitHub
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

Appearance settings
Reseting focus
You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

gfx-rs

/
**
wgpu-native
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
120

*

Star
997

# Pull requests: gfx-rs/wgpu-native
 

New pull request
New


6 Open


295 Closed


6 Open


295 

Title: Update library to latest webgpu-native headers · Pull Request #427 · gfx-rs/wgpu-native
Author: PJB3005
Published Date: 2024-09-19T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/pull/427
Text: # Pull Request: gfx-rs/wgpu-native #427

- Repository: gfx-rs/wgpu-native | Native WebGPU implementation based on wgpu-core | 1K stars | Rust

## Update library to latest webgpu-native headers

- Author: @PJB3005
- Association: CONTRIBUTOR
- State: closed
- Source branch: 24-09-19-update-headers
- Target branch: trunk
- Reviewers: @rajveermalviya
- Mergeable: dirty
- Commits: 19
- Additions: 974
- Deletions: 728
- Changed files: 18
- Created: 2024-09-19T15:50:45Z
- Updated: 2025-02-25T02:16:07Z
- Closed: 2025-02-25T02:16:07Z

This goes up to https://github.com/webgpu-native/webgpu-headers/commit/6f549cc3409663303b06f50483b9ebf9d1cf19dd
Things I *didn't* do:

- I didn't update the library to make sure "instance dropped" callback error codes are guaranteed to happen, like they seem to be in Dawn.

List of changes (roughly in order of header commits):

- Various enum and struct renames
- Updated callbacks to use the new `*CallbackInfo` structs and 2-userdata system. Also updated functions to return `WGPUFuture`, though the `W

Title: Cross-Platform Rust Graphics with wgpu: One API to Rule Vulkan, Metal, D3D12, OpenGL & WebGPU - BrightCoding
Author: 
Published Date: 2025-09-30T00:00:00.000Z
URL: https://www.blog.brightcoding.dev/2025/09/30/cross-platform-rust-graphics-with-wgpu-one-api-to-rule-vulkan-metal-d3d12-opengl-webgpu
Text: Cross-Platform Rust Graphics with wgpu: One API to Rule Vulkan, Metal, D3D12, OpenGL & WebGPU - BrightCoding

0

TL;DR wgpu is a safe, pure-Rust graphics library that exposes a single, WebGPU-inspired API and translates it natively to Vulkan, Metal, Direct3D 12, OpenGL/GLES and, when compiled to WebAssembly, to WebGL2 or the emerging WebGPU standard. Write once, run everywhere from AAA desktop engines to browser demos without`#ifdef` hell.

---

1. Why Another Graphics Abstraction?

---

Modern GPUs expose very similar capabilities, yet the OS vendor APIs could not be more different:

PlatformPrimary APIWindowsDirectX 12macOS / iOSMetalLinux / AndroidVulkan (plus GLES)BrowserWebGPU (or WebGL2 as fallback)Shipping a cross-platform application traditionally means:

1. Swallowing the performance & size cost of a closed-source engine.
2. Writing four separate rendering backends, or

wgpu solves this with a thin, open-source Rust


```

---

## Assistant (Plan · minimax-m2.5-free · 20.9s)

_Thinking:_

Let me also check the webgpu headers and understand what we'd need for building wgpu-native from source.

**Tool: websearch**

**Input:**
```json
{
  "query": "webgpu-native webgpu-headers C library build instructions"
}
```

**Output:**
```
Title: Getting Started · gfx-rs/wgpu-native Wiki - GitHub
Author: gfx-rs
URL: https://github.com/gfx-rs/wgpu-native/wiki/Getting-Started
Text: Getting Started · gfx-rs/wgpu-native Wiki · GitHub
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

gfx-rs

/
**
wgpu-native
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
92

*

Star
777

# Getting Started
Jump to bottom
Almar Klein edited this page Jan 10, 2023
&middot;

4 revisions

Table of Contents:
* Prerequisites
* Generating Rust glue
* Generating static library
* Running an example
## Prerequisites

Before getting started with wgpu, there are some necessary components that have to be ins

Title: GitHub - gfx-rs/wgpu-native: Native WebGPU implementation based on wgpu-core
Author: gfx-rs
Published Date: 2020-04-17T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native
Text: GitHub - gfx-rs/wgpu-native: Native WebGPU implementation based on wgpu-core
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

gfx-rs

/
**
wgpu-native
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
92

*

Star
777

*
Native WebGPU implementation based on wgpu-core
### License
Apache-2.0, MIT licenses found
### Licenses found

Apache-2.0
LICENSE.APACHE
 
MIT
LICENSE.MIT


777
stars
 
92
forks
 
Branches
 
Tags
 
Activity


Star


Notifications
 You mus

Title: Track: webgpu-headers upgrade in wgpu-native · Issue #3 · go-webgpu/webgpu
Author: kolkov
Published Date: 2026-01-29T00:00:00.000Z
URL: https://github.com/go-webgpu/webgpu/issues/3
Text: # Issue: go-webgpu/webgpu #3

- Repository: go-webgpu/webgpu | Zero-CGO WebGPU bindings for Go — GPU-accelerated graphics and compute in pure Go | 24 stars | Go

## Track: webgpu-headers upgrade in wgpu-native

- Author: @kolkov
- Association: CONTRIBUTOR
- State: open
- Created: 2026-01-29T13:10:42Z
- Updated: 2026-01-29T13:10:42Z

## Summary

wgpu-native v27.0.4.0 uses outdated webgpu-headers (commit `bac5208` from Nov 2024), which is **104 commits behind** the current main branch.

This causes enum value mismatches between gputypes (follows current webgpu-headers) and wgpu-native.

Example: `BGRA8Unorm` is 27 in current headers but 23 in wgpu-native.

## Current Workaround

We implemented a conversion layer in `wgpu/convert.go` to translate between gputypes and wgpu-native enum values.

## Upstream Tracking

- **Issue:** https://github.com/gfx-rs/wgpu-native/issues/546
- **Active PR:** https://github.com/gfx-rs/wgpu-native/pull/536
- **Our comment:** https://github.com/gfx-rs/wgpu-native/issues/546#issuecomment-3817587539

## Blocker

PR #536 is blocked by CI issues on Android, iOS, and Windows i686 platforms.

## Resolution

Once wgpu-native merges the header update:

1. Update wgpu-native dependency
2. Remov

Title: GitHub - eliemichel/WebGPU-distribution: CMake files that provide WebGPU for native and web development, easy-to-integrate and unified across implementations.
Author: eliemichel
Published Date: 2023-03-10T00:00:00.000Z
URL: https://github.com/eliemichel/WebGPU-distribution
Text: GitHub - eliemichel/WebGPU-distribution: Distributions of WebGPU for native and web development, easy to integrate and interchangeable.
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

eliemichel

/
**
WebGPU-distribution
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
18

*

Star
115

*
Distributions of WebGPU for native and web development, easy to integ

Title: GitHub - wasi-gfx/wasi-webgpu-headers: wasi-webgpu implementation of webgpu native headers
Author: wasi-gfx
Published Date: 2024-09-26T00:00:00.000Z
URL: https://github.com/wasi-gfx/wasi-webgpu-headers
Text: GitHub - wasi-gfx/wasi-webgpu-headers: wasi-webgpu implementation of webgpu native headers
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
wasi-gfx/**wasi-webgpu-headers**Public
* NotificationsYou must be signed in to change notification settings
* Fork1
* Star5
wasi-webgpu implementation of webgpu native headers
### License
Apache-2.0 license
5stars1forkBranchesTagsActivity
Star
NotificationsYou must be signed in to change notific

Title: Update library to latest webgpu-native headers · Pull Request #427 · gfx-rs/wgpu-native
Author: PJB3005
Published Date: 2024-09-19T00:00:00.000Z
URL: https://github.com/gfx-rs/wgpu-native/pull/427
Text: # Pull Request: gfx-rs/wgpu-native #427

- Repository: gfx-rs/wgpu-native | Native WebGPU implementation based on wgpu-core | 1K stars | Rust

## Update library to latest webgpu-native headers

- Author: @PJB3005
- Association: CONTRIBUTOR
- State: closed
- Source branch: 24-09-19-update-headers
- Target branch: trunk
- Reviewers: @rajveermalviya
- Mergeable: dirty
- Commits: 19
- Additions: 974
- Deletions: 728
- Changed files: 18
- Created: 2024-09-19T15:50:45Z
- Updated: 2025-02-25T02:16:07Z
- Closed: 2025-02-25T02:16:07Z

This goes up to https://github.com/webgpu-native/webgpu-headers/commit/6f549cc3409663303b06f50483b9ebf9d1cf19dd
Things I *didn't* do:

- I didn't update the library to make sure "instance dropped" callback error codes are guaranteed to happen, like they seem to be in Dawn.

List of changes (roughly in order of header commits):

- Various enum and struct renames
- Updated callbacks to use the new `*CallbackInfo` structs and 2-userdata system. Also updated functions to return `WGPUFuture`, though the `WGPUFuture` thing is just stubbed out at the moment as I don't think wgpu-core has the necessary functionality for it. `wgpuInstanceWaitAny` is `unimplemented!()`
- `DepthClipCont

Title: webgpu.h - C version of the JS API, for both native and Wasm. A ... - GitHub
Author: webgpu-native
URL: https://github.com/webgpu-native/webgpu-headers
Text: GitHub - webgpu-native/webgpu-headers
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

webgpu-native

/
**
webgpu-headers
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
37

*

Star
333

*
webgpu-native.github.io/webgpu-headers/
### License

BSD-3-Clause license


333
stars
 
37
forks
 
Branches
 
Tags
 
Activity


Star


Notifications
 You must be signed in to change notification settings
# webgpu-native/webgpu-headers
This commit does not belong to any branch on this reposi


```

---

## Assistant (Plan · minimax-m2.5-free · 8.8s)

_Thinking:_

Now I have a good understanding of what's needed. Let me also check if there's a prebuilt wgpu-native package on Arch Linux to make this easier.

**Tool: bash**

**Input:**
```json
{
  "command": "pacman -Ss wgpu 2>/dev/null | head -20",
  "description": "Search for wgpu packages on Arch"
}
```

---

## Assistant (Plan · minimax-m2.5-free · 18.4s)

_Thinking:_

No wgpu packages available on Arch. Let me check for any prebuilt binaries or other options. I have enough info now to create a plan.

Now I have a complete picture. Here's a plan for creating your own WebGPU bindings:

---

## Plan: Create Custom WebGPU Bindings

### Option 1: Use Prebuilt wgpu-native Binary + Custom Zig Bindings

**Steps:**
1. **Get wgpu-native library**
   - Download prebuilt from: https://github.com/gfx-rs/wgpu-native/releases
   - Latest: v27.0.4.0 (Dec 2025)

2. **Get WebGPU headers**
   - Clone: https://github.com/webgpu-native/webgpu-headers
   - Provides `webgpu.h` and `wgpu.h`

3. **Create Zig bindings**
   - Use `@cImport(@cInclude("wgpu.h"))` to import C headers
   - Create thin Zig wrapper for nicer API
   - Example structure:
   ```zig
   const wgpu = @cImport(@cInclude("wgpu.h"));
   
   pub const Instance = opaque {};
   pub const Device = opaque {};
   pub const Queue = opaque {};
   // ... etc
   ```

4. **Window management**
   - Use existing `zglfw` (IridescenceTech/zglfw) for window creation
   - Get native Wayland/X11 handles for wgpu surface creation

### Option 2: Build wgpu-native from Source

**Build Dependencies:**
- Rust + Cargo
- LLVM/Clang
- Vulkan SDK
-wayland-devel packages

**Build steps:**
```bash
git clone https://github.com/gfx-rs/wgpu-native
cd wgpu-native
cargo build --release
```

### Project Structure
```
zimul/
├── build.zig              # Link wgpu-native + headers
├── src/
│   ├── main.zig          # Your app
│   ├── wgpu.zig         # Your custom bindings
│   └── window.zig       # Window helper (or use zglfw)
└── deps/
    └── wgpu-native/      # wgpu-native binary + headers
```

### Key Files to Create

| File | Purpose |
|------|---------|
| `src/wgpu.zig` | C binding wrapper using `@cImport` |
| `src/graphics.zig` | Graphics context, device, queue setup |
| `src/shader.zig` | Shader compilation helpers |
| `src/pipeline.zig` | Render pipeline setup |

### Key WebGPU Concepts to Bind

1. **Instance** → `wgpuCreateInstance()`
2. **Adapter** → `wgpuInstanceRequestAdapter()`  
3. **Device** → `wgpuAdapterRequestDevice()`
4. **Surface** → `wgpuSurfaceFromWaylandSurface()` (Wayland-specific)
5. **SwapChain** → `wgpuSurfacePresent()`
6. **Buffers/Textures** → GPU memory
7. **Pipeline** → Shader stages + vertex/fragment info

---

**Would you like me to proceed with implementing this?** 

I can start by:
1. Adding wgpu-native as a dependency (fetch binary or build from source)
2. Creating the initial Zig binding wrapper
3. Setting up window + WebGPU integration

---

## User

for window management, show me every ways to handle

---

## Assistant (Plan · minimax-m2.5-free · 13.4s)

_Thinking:_

The user wants to see all possible ways to handle window management for WebGPU in Zig. They're asking for options, not implementation. Let me search for the available window management solutions for Zig.

**Tool: websearch**

**Input:**
```json
{
  "query": "Zig window management library GLFW alternative Wayland 2025"
}
```

**Output:**
```
Title: GitHub - ethanthoma/rgfw
Author: ethanthoma
Published Date: 2025-10-19T00:00:00.000Z
URL: https://github.com/ethanthoma/rgfw
Text: Skip to content

You signed in with another tab or window. Reload to refresh your session.You signed out in another tab or window. Reload to refresh your session.You switched accounts on another tab or window. Reload to refresh your session.Dismiss alert

ethanthoma/ **rgfw** Public

- Notifications You must be signed in to change notification settings
- Fork\
0
- Star\
1


1\
star 0\
forks Branches Tags Activity

Star

Notifications You must be signed in to change notification settings

# ethanthoma/rgfw

main

Branches Tags

Go to file

Code

Open more actions menu

## Folders and files

| Name | Name | Last commit message | Last commit date |
| --- | --- | --- | --- |
| ## Latest commit ## History 1 Commit |
| examples | examples |
| src | src |
| .gitignore | .gitignore |
| README.md | README.md |
| build.zig | build.zig |
| build.zig.zon | build.zig.zon |
| flake.lock | flake.lock |
| flake.nix | flake.nix |
| View all files |

## Repository files navigation

# RGFW Zig Bindings

**Thanks to https://codeberg.org/Zettexe/rgfw-zig for the base**

Minimal cross-platform window management library using RGFW header-only C
library.

## Known Issues

### Wayland Window Sizing

**Issue**: Wayland backend ignores window size parameters. All windows are
created taking up t

Title: GitHub - Batres3/zlfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Author: Batres3
Published Date: 2025-03-09T00:00:00.000Z
URL: https://github.com/batres3/zlfw
Text: # Repository: Batres3/zlfw

Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.

- Stars: 13
- Forks: 4
- Watchers: 13
- Open issues: 0
- Primary language: Zig
- Languages: Zig
- License: MIT License (MIT)
- Default branch: main
- Created: 2025-03-09T23:42:46Z
- Last push: 2026-02-16T15:15:55Z
- Contributors: 4 (top: Batres3, siniarskimar, FalsePattern, RespiteFromReality)
- Archived: true

---

This repo is no longer actively maintaned, I created this mostly as a learning tool for zig, and no longer have any interest in maintining/developing a glfw clone in zig, I will leave this archived in case anyone else would like to make their own version of it.

# zlfw

This package is meant to be entirely equivalent to using the C code direcly in terms of performance, while keeping a nice ziggified API.

The advantages it offers over C are pretty clear:
 * __Enums__, unlike GLFW, you always know what a function can accept, for example `window.getKey(.a)` instead of `c.glfwGetKey(window, c.GLFW_KEY_ESCAPE)`.
 * Slices instead of C pointers
 * packed structs for bit masks, allowing for `if (joystick.down)` instead of `if (joystick * c.GLF

Title: GitHub - StoryTreeGames/windowing: A native OS window creation and management library made in pure zig
Author: StoryTreeGames
Published Date: 2024-03-26T00:00:00.000Z
URL: https://github.com/StoryTreeGames/windowing
Text: GitHub - StoryTreeGames/storytree-core: A native OS window creation and management library made in pure zig
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
StoryTreeGames/**storytree-core**Public
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star6
A native OS window creation and management library made in pure zig
### License
BSD-2-Clause license
6stars0forksBranchesTagsActivity
Star
N

Title: GitHub - Aransentin/ZWL: Zig Windowing Library
Author: Aransentin
Published Date: 2020-06-27T00:00:00.000Z
URL: https://github.com/Aransentin/ZWL
Text: GitHub - Aransentin/ZWL: Zig Windowing Library
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

Aransentin

/
**
ZWL
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
15

*

Star
91

*
Zig Windowing Library
### License

EUPL-1.2 license


91
stars
 
15
forks
 
Branches
 
Tags
 
Activity


Star


Notifications
 You must be signed in to change notification settings
# Aransentin/ZWL
This commit does not belong to any branch on this repository, and may belong to a fork outside of the rep

Title: FalsePattern/glfw: A fork of GLFW packaged for the Zig build system - GitHub
Author: FalsePattern
Published Date: 2025-02-15T20:45:04.000Z
URL: https://github.com/falsepattern/glfw/
Text: GitHub - FalsePattern/glfw: A fork of GLFW packaged for the Zig build system
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
FalsePattern/**glfw**Public
forked fromleroycep/glfw
* NotificationsYou must be signed in to change notification settings
* Fork1
* Star2
A fork of GLFW packaged for the Zig build system
### License
Zlib license
2stars30forksBranchesTagsActivity
Star
NotificationsYou must be signed in to change notification settings
# FalsePatte

Title: GitHub - AshishBhattarai/mach-glfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Author: AshishBhattarai
Published Date: 2024-05-22T00:00:00.000Z
URL: https://github.com/ashishbhattarai/mach-glfw
Text: # Repository: AshishBhattarai/mach-glfw

Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.

- Stars: 4
- Forks: 1
- Watchers: 4
- Open issues: 0
- Primary language: Zig
- Languages: Zig
- License: Other (NOASSERTION)
- Default branch: main
- Created: 2024-05-22T03:25:10Z
- Last push: 2025-09-25T19:35:21Z
- Contributors: 40 (top: InKryption, alichraghi, wrench-bot, castholm, AshishBhattarai, iddev5, leecannon, Avokadoen, PiergiorgioZagaria, BratishkaErik)

---

# GLFW binding for zig

This repository is a fork of the now-discontinued mach-glfw.

## Features

- Zero-fuss installation, cross-compilation at the flip of a switch, and broad platform support.
- 100% API coverage. Every function, type, constant, etc. has been exposed in a ziggified API.

## What does a ziggified GLFW API offer?

- **Enums**, always know what value a GLFW function can accept as everything is strictly typed. And use the nice Zig syntax to access enums, like `window.getKey(.escape)` instead of `c.glfwGetKey(window, c.GLFW_KEY_ESCAPE)`
- Slices instead of C pointers and lengths.
- Generics, so you can just use window.hint

Title: Zigistry: A package registry and manager for Zig | Find & Share Zig Packages
Author: Rohan Vashisht
Published Date: 2024-01-01T00:00:00.000Z
URL: https://zigistry.dev/programs/github/Darkfllame/ZWL
Text: Zigistry: A package registry and manager for Zig | Find & Share Zig Packages
Loading...
misshodZWL
Darkfllame/ZWL
MIT
Zig cross platform Windowing Library
101001
3
cross-platform,opengl,zig
build.zig.zonbuild.zig
View program on GitHub
## Dependencies
Namezgll
URL
https://github.com/Darkfllame/zgll
Tag URL
https://github.com/Darkfllame/zgll/archive/3f7d62dcab0d59242f0a49092687cf2ad3a9b308.tar.gz.tar.gz
Commit`3f7d62dcab0d59242f0a49092687cf2ad3a9b308.tar.gz`
## README
# Zig Windowing Library
ZWL (Zig Windowing Library, /zwil/) is a cross-platform zig windowing library with loop-based event polling (like SDL) and aimed to be lightweight thanks to zig's conditional compilation/lazy evaluation.
## Current state:
Win32
Window
Event
OpenGL Context
Linux
* X11
Window
Event
OpenGL Context
* Wayland
Window
Event
OpenGL ContextMacOS
Window
Event
OpenGL Context
### ZWL is very WIP, so expect bugs, inconsistencies and lack of support on certain platforms. If you wish you can help me bycontributingto this project via pull requests or filing issues.
# Contributing
Feel free to contribute to the library by making PRs or by filing issues. My machine is a windows one, so I'll prioritize my work (and might only wo


```

---

## Assistant (Plan · minimax-m2.5-free · 19.0s)

_Thinking:_

The user wants to see all possible window management options for Zig, especially for WebGPU. Let me also search for more options, especially pure Wayland solutions.

**Tool: websearch**

**Input:**
```json
{
  "query": "Zig pure Wayland window library without GLFW"
}
```

**Output:**
```
Title: GitHub - psnszsn/way-z: Zig Wayland client and app toolkit
Author: psnszsn
Published Date: 2023-05-28T00:00:00.000Z
URL: https://github.com/psnszsn/way-z
Text: GitHub - psnszsn/way-z: Zig Wayland client and app toolkit
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
psnszsn/**way-z**Public
* NotificationsYou must be signed in to change notification settings
* Fork1
* Star14
Zig Wayland client and app toolkit
### License
MPL-2.0 license
14stars1forkBranchesTagsActivity
Star
NotificationsYou must be signed in to change notification settings
# psnszsn/way-z
main
BranchesTags

Go to file
Code
Open more actions menu
## Folders and files
|Na

Title: GitHub - StoryTreeGames/windowing: A native OS window creation and management library made in pure zig
Author: StoryTreeGames
Published Date: 2024-03-26T00:00:00.000Z
URL: https://github.com/StoryTreeGames/windowing
Text: GitHub - StoryTreeGames/storytree-core: A native OS window creation and management library made in pure zig
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
StoryTreeGames/**storytree-core**Public
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star6
A native OS window creation and management library made in pure zig
### License
BSD-2-Clause license
6stars0forksBranchesTagsActivity
Star
N

Title: GitHub - andrewrk/zig-window: window client library
Author: andrewrk
Published Date: 2018-06-09T00:00:00.000Z
URL: https://github.com/andrewrk/zig-window
Text: GitHub - andrewrk/zig-window: window client library
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

andrewrk

/
**
zig-window
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
14

*

Star
114

*
window client library

114
stars
 
14
forks
 
Branches
 
Tags
 
Activity


Star


Notifications
 You must be signed in to change notification settings
# andrewrk/zig-window
This commit does not belong to any branch on this repository, and may belong to a fork outside of the repositor

Title: GitHub - Aransentin/ZWL: Zig Windowing Library
Author: Aransentin
Published Date: 2020-06-27T00:00:00.000Z
URL: https://github.com/Aransentin/ZWL
Text: # Repository: Aransentin/ZWL

Zig Windowing Library

- Stars: 108
- Forks: 12
- Watchers: 108
- Open issues: 5
- Primary language: Zig
- Languages: Zig (99.9%), AMPL (0.1%)
- License: European Union Public License 1.2 (EUPL-1.2)
- Default branch: master
- Created: 2020-06-27T23:14:32Z
- Last push: 2022-06-13T22:35:03Z
- Contributors: 20 (top: ikskuh, Aransentin, nektro, Snektron, xtian, hugh-fox, fabioarnold, Hejsil, Sethughes, Sobeston)

---

# ZWL

A Zig Windowing Library

Title: seizer: Cross platform windowing/rendering library for Zig
URL: https://sr.ht/~geemili/seizer/
Text: seizer: Cross platform windowing/rendering library for Zig
## \~geemili/seizer
* summary
* sources
Cross platform windowing/rendering library for Zig
e5e4f0f`release 0.1.1`
\~geemilipushed to\~geemili/shimizugit
2 months ago
05939f1`update to zig version 0.14.0-dev.3145+6a6e72fff`
\~geemilipushed to\~geemili/shimizugit
2 months ago
View project feedRSSReport abuse
## #seizer
`seizer`is a Zig library for making games and applications that target the desktop and browser.
It exposes an OpenGL ES 3.0 rendering context. It is currently in an alpha state, and the APIs
constantly break.
### #Planned Features
* [ ] Cross-platform Windowing
* [ ] Linux (Wayland only, X11 is not planned at the moment, sorry)
* [ ] Windows
* [ ] Web (Firefox, Chrome)
* [ ] MacOS
* [ ] Input handling
* [ ] Gamepad
* [ ] Mouse
* [ ] Keyboard
* [ ] Touch
* [ ] Hardware accelerated rendering
* [ ] 2d sprite based rendering
* [ ] shader effects
* [ ] Multiple backends
* [ ] WebGL 2.0/OpenGL ES 3.0
* [ ] DirectX
* [ ] Vulkan
* [ ] a built-in by optional GUI library
* [ ] specific device support
* [ ] Steam Deck
* [ ] Anbernic RG35XX H
* [ ] Anbernic RG351M
* [ ] Powkiddy RGB30### #FAQ
> > Why should I use `> seizer
`> over SDL or GLFW?
> You probably shouldn't, at the moment. I'm using it for the following reasons:
* I want to lea

Title: GitHub - allyourcodebase/wayland: wayland ported to the zig build system
Author: allyourcodebase
Published Date: 2024-12-18T00:00:00.000Z
URL: https://github.com/allyourcodebase/wayland
Text: GitHub - allyourcodebase/wayland: wayland ported to the zig build system
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
allyourcodebase/**wayland**Public
* NotificationsYou must be signed in to change notification settings
* Fork2
* Star12
wayland ported to the zig build system
### License
MIT license
12stars2forksBranchesTagsActivity
Star
NotificationsYou must be signed in to change notification settings
# allyourcodebase/wayland
master
Branches

Title: GitHub - james-orcales/raylib-zig-wayland: Setup raylib C interop for Zig 0.13.0 on Wayland
Author: james-orcales
Published Date: 2024-07-27T00:00:00.000Z
URL: https://github.com/amesaine/raylib-zig-wayland
Text: GitHub - james-orcales/raylib-zig-wayland: Setup raylib C interop for Zig 0.13.0 on Wayland
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
james-orcales/**raylib-zig-wayland**Public
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star1
Setup raylib C interop for Zig 0.13.0 on Wayland
1star0forksBranchesTagsActivity
Star
NotificationsYou must be signed in to change notification settings
# james-o


```

---

## Assistant (Plan · minimax-m2.5-free · 22.6s)

_Thinking:_

Now I have a comprehensive list. Let me also check if there's a pure Wayland + WebGPU approach.

**Tool: websearch**

**Input:**
```json
{
  "query": "zig wayland client directly without window library webgpu"
}
```

**Output:**
```
Title: Writing a Wayland client from scratch in Zig
Author: 
Published Date: 2026-01-29T00:00:00.000Z
URL: https://www.seagin.me/writing-a-wayland-client-from-scratch-in-zig/
Text: Writing a Wayland client from scratch in Zig

Lately I've been enjoying writing things from scratch. Writing a Wayland client from scratch has been the most frustrating and rewarding experience of my last two weeks. The number of new things that I've learned was more than worth all the frustrations. It took two weeks but at this point I'm not sure if it was actually more. It's part of my building a debugger in Zig series.

If you'd like to skip the explanation and see the code you can find it here. It's a work in progress but it works. You'll also find links to all the resources that helped in the comments on top of the file.

### What is Wayland?

It's a communication protocol for serving windows on displays on Linux and is designed to be an improvement on X11. Which was the original window system for my debugger but since then I upgraded my OS and the OS now uses Wayland instead of X11. You can render X11 windows in Wayland (I think) but I saw an opportunity to write my own client which would be in Zig just like the rest of the code. Which makes thi

Title: Shimizu - The Wayland Protocol, in Zig - Showcase
URL: https://ziggit.dev/t/shimizu-the-wayland-protocol-in-zig/6246
Text: Shimizu - The Wayland Protocol, in Zig - Showcase - Ziggit
Loading

Title: GitHub - psnszsn/way-z: Zig Wayland client and app toolkit
Author: psnszsn
Published Date: 2023-05-28T00:00:00.000Z
URL: https://github.com/psnszsn/way-z
Text: GitHub - psnszsn/way-z: Zig Wayland client and app toolkit
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
psnszsn/**way-z**Public
* NotificationsYou must be signed in to change notification settings
* Fork1
* Star14
Zig Wayland client and app toolkit
### License
MPL-2.0 license
14stars1forkBranchesTagsA

Title: wayland_client.zig ~ glfmn.io
Author: 
URL: https://glfmn.io/code/hardmode-triangle/wayland-client-zig/
Text: wayland_client.zig ~ glfmn.io

Name

# wayland_client.zig

generated by zig-wayland via a build.zig file.

## Description

This file gets generated using the zig-wayland`Scanner` at build time and placed in the`zig-cache/o` directory.

build.zig

```zig
27const scanner = Scanner.create(b, .{});
28const wayland = b.createModule(.{ .source_file = scanner.result });
2930scanner.generate("wl_compositor", 1);
3132exe.addModule("wayland", wayland);
33exe.linkLibC();
34exe.linkSystemLibrary("wayland-client");

```

## Contents

```zig
1// Generated by zig-wayland
23// Copyright © 2008-2011 Kristian Høgsberg
4// Copyright © 2010-2011 Intel Corporation
5// Copyright © 2012-2013 Collabora, Ltd.
6//
7// Permission is hereby granted, free of charge, to any person
8// obtaining a copy of this software and associated documentation files
9// (the "Software"), to deal in the Software without restriction,
10// including without limitation the rights to use, copy, modify, merge,
11// publish, distribute, sublicense, and/or sell copies of the Software,
12// and to permit persons to whom the Software is furnished to do so,
13// subje

Title: zacoons/zig-wayland: Zig wayland scanner and libwayland bindings - Codeberg.org
Author: zacoons
URL: https://codeberg.org/zacoons/zig-wayland
Text: zacoons/zig-wayland: Zig wayland scanner and libwayland bindings - Codeberg.org
zacoons/zig-wayland

Watch1
Star0
Fork
You've already forked zig-wayland
0
forked fromifreund/zig-wayland
CodePull requestsActivity
Zig wayland scanner and libwayland bindings
**243**commits**4**branches**4**tags**563**KiB
* **Zig100%
**main**
Find a file
HTTPS
Download ZIPDownload TAR.GZDownload BUNDLEOpen with VS CodeOpen with VSCodiumOpen with Intellij IDEA
|
**Isaac Freund**6afd094563

scanner: add ext\_image\_capture\_source\_v1 to version locked list...
```
This is more of a bandaid than a proper fix, but allows users to
use zig-wayland with the ext\_image\_capture\_source\_v1 protocol for now
until this list of version locked interfaces can be de-hardcoded.
```
|2025-10-13 20:31:37 +02:00|
.builds|ci: update to Zig 0.15.1|2025-08-22 14:29:03 +02:00|
example|build: update to Zig 0.15.0|2025-08-21 11:20:07 +02:00|
src|scanner: add ext\_image\_capture\_source\_v1 to version locked list|2025-10-13 20:31:37 +02:00|
test|build: update to Zig 0.15.0|2025-08-21 11:20:07 +02:00|
.gitignore|build: upg

Title: build.zig - zigway - A hello world Zig Wayland client
Author: 
URL: https://git.yaroslavps.com/zigway/tree/build.zig
Text: build.zig - zigway - A hello world Zig Wayland client
cgit logo|index:zigway|cairo-shmgl/rgb-squaregl/rgb-square-animgl/rgb-trianglegl/squaregl/trianglemaster|
A hello world Zig Wayland client|Yaroslav de la Peña Smirnov &lt;yps@yaroslavps.com&gt;|
aboutsummaryrefslogtreecommitdiff|log msgauthorcommitterrange|
path:root/build.zig
blob: 5e885fc95e88cc4985e809f2aa1b262ba79e66bb (plain)
```
1234567891011121314151617181920212223242526272829303132333435363738394041424344
```
|
```
`
```
conststd=@import(&quot;std&quot;);constScanner=@import(&quot;zig-wayland&quot;).Scanner;pubfnbuild(b:\*std.Build)void{consttarget=b.standardTargetOptions(.{});constoptimize=b.standardOptimizeOption(.{});constscanner=Scanner.create(b,.{});scanner.addSystemProtocol(&quot;stable/xdg-shell/xdg-shell.xml&quot;);scanner.addSystemProtocol(&quot;staging/fractional-scale/fractional-scale-v1.xml&quot;);scanner.generate(&quot;&quot;wl\_compositor&quot;&quot;,6);scanner.generate(&quot;&quot;wl\_shm&quot;&quot;,1);scanner.generate(&quot;&quot;wl\_output&quot;&quot;,4);scanner.generate(&quot;&quot;xdg\_wm\_base&quot;&quot;,2);scanner.gen

Title: bronter/wgpu_native_zig: Zig bindings for wgpu-native
Author: bronter
URL: https://github.com/bronter/wgpu-native-zig
Text: GitHub - bronter/wgpu\_native\_zig: Zig bindings for wgpu-native
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
bronter/**wgpu\_native\_zig**Public
* NotificationsYou must be signed in to change notification settings
* Fork24
* Star103
Zig bindings for wgpu-native
### License
MIT license
103stars24forksBranchesTagsActivity
Star
Notificati

Title: Writing a simple wayland client without any libraries or dependencies
Author: umurgdk
URL: https://www.reddit.com/r/wayland/comments/1e9pqv2/writing_a_simple_wayland_client_without_any/
Text: 
 Writing a simple wayland client without any libraries or dependencies 
 Author: umurgdk 
 Time Posted (UTC): 2024-07-22 21:18:04+00:00 
 Score: 7 
 
 
 Link: https://www.reddit.com/r/wayland/comments/1e9pqv2/writing_a_simple_wayland_client_without_any/ 
 
 
 If anyone is looking for a resource to write a wayland client application without using any sort of libraries or third party dependencies here is a nice article I find: https://gaultier.github.io/blog/wayland\_from\_scratch.html All codes are written in plain C, so it makes it easy to follow up on other languages as well. 
 
 
 No comments found. 



```

---

## Assistant (Plan · minimax-m2.5-free · 13.9s)

_Thinking:_

Now I have a comprehensive view. Let me also search for how to directly get the Wayland surface for WebGPU without any window library.

**Tool: websearch**

**Input:**
```json
{
  "query": "wgpu native wayland surface create from wayland window"
}
```

**Output:**
```
You've hit Exa's free MCP rate limit. To continue using without limits, create your own Exa API key.

Fix: Create API key at https://dashboard.exa.ai/api-keys , and then update Exa MCP URL to this https://mcp.exa.ai/mcp?exaApiKey=YOUR_EXA_API_KEY
```

---

## Assistant (Plan · minimax-m2.5-free · 6.2s)

_Thinking:_

Let me check directly in the webgpu headers or wgpu-native for how to create a surface from Wayland.

**Tool: bash**

**Input:**
```json
{
  "command": "pacman -Qs wayland | head -30",
  "description": "Check installed Wayland packages"
}
```

**Output:**
```
local/cliphist 1:0.7.0-2
    wayland clipboard manager
local/clipse 1.2.0-2
    A configurable TUI clipboard manager for Unix, built for wayland.
local/egl-wayland 4:1.1.21-1
    EGLStream-based Wayland external platform
local/egl-wayland2 1.0.0.rc.r57.g1893c37-1
    EGLStream-based Wayland external platform (2)
local/glfw 1:3.4-1
    A free, open source, portable framework for graphical application development
local/grim 1.5.0-2
    Screenshot utility for Wayland
local/gtk-layer-shell 0.10.0-1
    Library to create Wayland desktop components using the Layer Shell protocol
local/gtk4-layer-shell 1.3.0-1
    Library to create panels and other desktop components for Wayland
local/hyprland 0.54.1-1
    a highly customizable dynamic tiling Wayland compositor
local/hyprpaper 0.8.3-2
    a blazing fast wayland wallpaper utility with IPC controls
local/hyprpicker 0.4.6-2
    A wlroots-compatible Wayland color picker that does not suck
local/hyprtoolkit 0.5.3-1
    A modern C++ Wayland-native GUI toolkit
local/hyprwayland-scanner 0.4.5-1
    A Hyprland implementation of wayland-scanner, in and for C++
local/lib32-libva 2.22.0-1
    Video Acceleration (VA) API for Linux (32-bit)
local/lib32-wayland 1.24.0-1
    A computer display server protocol

```

---

## Assistant (Plan · minimax-m2.5-free · 28.3s)

_Thinking:_

Now I have comprehensive information. Let me present all the window management options to the user in a well-organized way.

Here's a comprehensive overview of all window management options for Zig + WebGPU on Wayland:

---

## Window Management Options for Zig + WebGPU

### Option 1: GLFW-based (Most Popular)
| Library | Repository | Status | Notes |
|---------|-----------|--------|-------|
| **zglfw** | IridescenceTech/zglfw | Active, 76 stars | Maintained fork of mach-glfw |
| **mach-glfw** | ashishbhattarai/mach-glfw | Archived | Original, still works |
| **zig-glfw** | FalsePattern/zig-glfw | Active | Community maintained |
| **zlfw** | Batres3/zlfw | Archived | Learning project |

**Pros:** Full-featured, cross-platform, well-tested
**Cons:** Has the XWayland issues we just debugged

---

### Option 2: Pure Zig Windowing Libraries
| Library | Repository | Status | Wayland |
|---------|-----------|--------|---------|
| **ZWL** | Darkfllame/ZWL | Active | ✅ Full support |
| **storytree-core** | StoryTreeGames/windowing | Active | ✅ Pure Zig |
| **seizer** | ~geemili/seizer | Alpha | ✅ Wayland only (planned) |
| **andrewrk/zig-window** | andrewrk/zig-window | Old | ❌ Unknown |

**Pros:** No C dependencies, pure Zig
**Cons:** May be less mature

---

### Option 3: Pure Wayland (No GLFW)
| Library | Repository | Status | Notes |
|---------|-----------|--------|-------|
| **way-z** | psnszsn/way-z | Active, 14 stars | App toolkit |
| **zig-wayland** | ifreund/zig-wayland | Active, 243 commits | Protocol bindings |
| **allyourcodebase/wayland** | allyourcodebase/wayland | Active | Zig-built wayland |

**Pros:** Native Wayland, no X11/XWayland issues
**Cons:** More low-level, more setup work

---

### Option 4: Write Your Own (From Scratch)
Since you want full control, you can create minimal bindings:

**What you need to bind:**
1. **libwayland-client** - Core Wayland protocol
2. **xdg-shell** - Window management protocol  
3. **xdg-decoration** - Window decorations (optional)

**Key functions to wrap:**
- `wl_display_connect()` - Connect to Wayland
- `wl_registry_bind()` - Get Wayland objects
- `xdg_wm_base_create_surface()` - Create window surface

**WebGPU surface creation:**
```c
// From wgpu.h - Wayland surface
WGPUStatus wgpuSurfacePresent(WGPUSurface surface);
WGPUSurface wgpuSurfaceFromWaylandSurface(
    WGPUInstance instance,
    const WGPUSurfaceDescriptorFromWaylandSurface* descriptor
);
```

---

### Option 5: RGFW (Another Option)
| Library | Repository | Status |
|---------|-----------|--------|
| **rgfw** | ethanthoma/rgfw | New (1 star) |

Minimal cross-platform window lib using RGFW C header.

---

## Recommendation for Your Use Case

Given your setup (NVIDIA + Hyprland + want control), here's my suggestion:

| Priority | Approach | Why |
|---------|---------|-----|
| **Easiest** | zglfw + wgpu-native | Works, just need version matching |
| **Most Control** | zig-wayland + custom wgpu binding | Full control, no version issues |
| **Quickest** | ZWL | Pure Zig, actively maintained |

**For creating your own bindings**, the minimal approach would be:
1. Use **zig-wayland** for protocol bindings (already done!)
2. Create thin wrapper around **wgpu-native** C API
3. Connect Wayland surface to wgpu

---

Would you like me to:
1. **Proceed with zglfw + wgpu-native** (easiest path)?
2. **Create custom bindings from scratch** using zig-wayland?
3. **Try ZWL** (pure Zig windowing)?

Which approach interests you most?

---

## User

i want to create from scratch

---

## Assistant (Plan · minimax-m2.5-free · 124.8s)

_Thinking:_

The user wants to create window management from scratch for their Zig + WebGPU project. They're on Hyprland (Wayland) with NVIDIA. They want full control and to avoid the version compatibility issues with existing libraries.

Since I'm in plan mode, I need to create a comprehensive plan for creating window management from scratch using pure Wayland.

Let me think about what this entails:

1. **Wayland basics**: Connect to display, get registry, bind required interfaces
2. **Required Wayland protocols**:
   - wl_compositor - for creating surfaces
   - wl_shm - for shared memory (buffer allocation)
   - wl_output - for display info
   - xdg_wm_base - for window management (xdg-shell)
   - xdg_decoration - for window decorations (optional but good)
   - zxdg_decoration - for xdg-decoration-unstable-v1

3. **Event loop**: Poll Wayland events
4. **Surface management**: Create, configure, map windows
5. **WebGPU integration**: Create wgpu surface from Wayland surface

Let me structure this plan clearly.

Let me create a comprehensive plan for creating window management from scratch using pure Wayland.

**Tool: question**

**Input:**
```json
{
  "questions": [
    {
      "header": "Scope",
      "multiple": false,
      "options": [
        {
          "description": "Everything from scratch - Wayland protocol, window, events",
          "label": "Full from scratch"
        },
        {
          "description": "Use zig-wayland for protocol bindings, wrap in Zig",
          "label": "zig-wayland + custom wrapper"
        },
        {
          "description": "Only handle window creation, use wgpu for rendering",
          "label": "Minimal - just window + wgpu"
        }
      ],
      "question": "How much do you want to build from scratch?"
    }
  ]
}
```

**Output:**
```
User has answered your questions: "How much do you want to build from scratch?"="Full from scratch". You can now continue with the user's answers in mind.
```

---

## Assistant (Plan · minimax-m2.5-free · 49.5s)

_Thinking:_

The user wants to build everything from scratch. Let me create a comprehensive plan.

Key components to build:
1. Wayland connection and event loop
2. Wayland protocol bindings (or manually implement)
3. Window creation (xdg-shell)
4. Buffer management (wl_shm)
5. Input handling
6. Integration with WebGPU (wgpu-native)

This is a substantial project. Let me create a detailed plan.

Now I have a clear picture. Here's the comprehensive plan:

---

## Plan: Full From-Scratch Window Management + WebGPU

### Project Structure
```
zimul/
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig           # Entry point
│   ├── wayland/
│   │   ├── mod.zig        # Wayland module exports
│   │   ├── connection.zig # Connect to Wayland display
│   │   ├── registry.zig   # Bind Wayland interfaces
│   │   ├──.zig   # Window surface management
│   │   ├── buffer.zig surface    # SHM buffer for rendering
│   │   ├── xdg.zig       # XDG shell window protocol
│   │   └── events Event loop handling.zig    #
│   ├── input/
│   │   ├── mod.zig
│   │   ├── keyboard.zig
│   │   ├── mouse.zig
│   │   └── events.zig
│   └── webgpu/
│       ├── mod.zig
│       ├── instance.zig
│       ├── device.zig
│       └── surface.zig    # Wayland surface → wgpu surface
├── webgpu-headers/        # webgpu.h, wgpu.h from webgpu-native
└── deps/
    └── wgpu-native/       # Prebuilt library
```

---

### Phase 1: Wayland Connection

**Files:** `connection.zig`

| Step | Description |
|------|-------------|
| 1.1 | Connect to Wayland display via `wl_display_connect(NULL)` |
| 1.2 | Get display file descriptor for polling |
| 1.3 | Set up round-trip to sync with compositor |
| 1.4 | Create display wrapper with cleanup (`wl_display_disconnect`) |

**Key functions to wrap:**
```zig
wl_display_connect() -> *wl_display
wl_display_display()
wl_display_roundtrip() -> c_int
```

---

### Phase 2: Registry & Interface Binding

**Files:** `registry.zig`

| Step | Description |
|------|-------------|
| 2.1 | Get `wl_registry` from display |
| 2.2 | Implement `wl_registry_listener` |
| 2.3 | Bind core interfaces: `wl_compositor`, `wl_shm`, `wl_output`, `xdg_wm_base` |
| 2.4 | Store bound interfaces in struct |

**Required interfaces:**
- `wl_compositor` (v6) - Create surfaces
- `wl_shm` (v1) - Shared memory buffers
- `wl_output` (v4) - Display/monitor info
- `xdg_wm_base` (v6) - Window management

---

### Phase 3: Window Surface (XDG)

**Files:** `xdg.zig`, `surface.zig`

| Step | Description |
|------|-------------|
| 3.1 | Create `wl_surface` via compositor |
| 3.2 | Get `xdg_wm_base` and call `xdg_wm_base.get_xdg_surface(surface)` |
| 3.3 | Set up `xdg_surface_listener` for configure events |
| 3.4 | Get `xdg_toplevel` and set title/size |
| 3.5 | Commit surface to map window |

**Key events to handle:**
- `xdg_surface.configure` - Resize handling
- `xdg_toplevel.configure` - Size/position changes
- `xdg_toplevel.close` - Window close request

---

### Phase 4: Buffer Management (SHM)

**Files:** `buffer.zig`

| Step | Description |
|------|-------------|
| 4.1 | Get `wl_shm` from registry |
| 4.2 | Create pool via `wl_shm.create_pool` |
| 4.3 | Allocate buffer for window content (RGBA pixels) |
| 4.4 | Implement double-buffering for smooth rendering |

**Format:** `WL_SHM_FORMAT_XRGB8888` or `WL_SHM_FORMAT_BGRA8888`

---

### Phase 5: Event Loop

**Files:** `events.zig`

| Step | Description |
|------|-------------|
| 5.1 | Poll display file descriptor (`epoll` or `poll`) |
| 5.2 | Call `wl_display_dispatch_pending()` |
| 5.3 | Handle `wl_keyboard`, `wl_pointer` for input |
| 5.4 | Process resize/configure events |
| 5.5 | Callback system for application events |

---

### Phase 6: WebGPU Integration

**Files:** `webgpu/`

| Step | Description |
|------|-------------|
| 6.1 | Import `wgpu.h` via `@cImport` |
| 6.2 | Create `WGPUInstance` with backend options |
| 6.3 | Create surface from Wayland: `wgpuSurfaceFromWaylandSurface()` |
| 6.4 | Request adapter + device + queue |
| 6.5 | Handle resize → recreate swapchain |

**wgpu-native integration:**
```zig
const wgpu = @cImport(@cInclude("wgpu.h"));

// Create instance
var instance_desc = wgpu.WGPUInstanceDescriptor{.nextInChain = null};
var instance = wgpu.wgpuCreateInstance(&instance_desc);

// Create surface from Wayland
var surface_desc = wgpu.WGPUSurfaceDescriptor{
    .nextInChain = @ptrCast(&wayland_surface_config),
    .label = "zimul surface",
};
var surface = wgpu.wgpuInstanceCreateSurface(instance, &surface_desc);
```

---

### Phase 7: Render Loop

**Files:** `main.zig`

| Step | Description |
|------|-------------|
| 7.1 | Initialize Wayland connection |
| 7.2 | Create window surface |
| 7.3 | Initialize WebGPU (instance → adapter → device → queue) |
| 7.4 | Main loop: poll events → render frame → present |
| 7.5 | Handle cleanup on close |

**Example flow:**
```zig
while (!should_close) {
    // Poll Wayland events
    wayland.pollEvents();
    
    // Render WebGPU frame
    var cmd_encoder = device.createCommandEncoder();
    // ... render commands ...
    queue.submit(&.{cmd_encoder.finish()});
    
    // Present
    surface.present();
}
```

---

### System Dependencies

Install required packages:
```bash
# Wayland development files
sudo pacman -S wayland wayland-protocols

# For building wgpu-native (if building from source)
sudo pacman -S rust cargo clang llvm

# For linking
sudo pacman -S vulkan-icd-loader vulkan-nvidia
```

---

### Deliverables

| File | Purpose |
|------|---------|
| `src/wayland/connection.zig` | Wayland display connection |
| `src/wayland/registry.zig` | Interface binding |
| `src/wayland/surface.zig` | Surface management |
| `src/wayland/buffer.zig` | SHM buffer handling |
| `src/wayland/xdg.zig` | XDG shell integration |
| `src/wayland/events.zig` | Event loop |
| `src/webgpu/mod.zig` | WebGPU wrapper |
| `src/main.zig` | Application entry |

---

### Estimated Lines of Code

- Wayland core: ~500 lines
- XDG shell: ~200 lines  
- Event loop: ~150 lines
- WebGPU wrapper: ~300 lines
- Main app: ~100 lines
- **Total: ~1,250 lines**

---

**Do you want me to proceed with this implementation?**

I can start by:
1. Setting up the project structure
2. Creating the Wayland connection module
3. Adding webgpu-headers as dependency
4. Building incrementally

---

## User

what if i want it to be cross-platform? linux(x11,wayland), windows, macos, web? is it hard?

---

## Assistant (Plan · minimax-m2.5-free · 16.2s)

_Thinking:_

The user is asking about making this cross-platform - supporting Linux (X11 + Wayland), Windows, macOS, and Web. This is a big question that requires research on what's possible and what's practical.

Let me think about this:

1. **Linux (X11 + Wayland)** - The from-scratch approach we planned would work for Wayland. For X11, we'd need to add X11 support separately.

2. **Windows** - Would need Win32 API bindings for window creation

3. **macOS** - Would need Cocoa/AppKit bindings

4. **Web** - Would need WebGPU JavaScript bindings

This is definitely more complex. Let me research what approaches exist for cross-platform Zig window management.

Actually, I should search for what's available in the Zig ecosystem for cross-platform window management that could help, rather than building everything from scratch.

**Tool: websearch**

**Input:**
```json
{
  "query": "Zig cross-platform window library Linux Windows macOS web"
}
```

**Output:**
```
Title: GitHub - bluesillybeard/Pinc2: a cross platform window library for game and application development, with a focus on cross-compilation, dependency minimization, and ease of integration
Author: bluesillybeard
Published Date: 2025-03-15T00:00:00.000Z
URL: https://github.com/bluesillybeard/pinc2
Text: # Repository: bluesillybeard/Pinc2

a cross platform window library for game and application development, with a focus on cross-compilation, dependency minimization, and ease of integration

- Stars: 3
- Forks: 0
- Watchers: 3
- Open issues: 28
- Primary language: C
- Languages: C (96.8%), C++ (2.7%), Objective-C (0.2%), CMake (0.1%), Zig (0.1%)
- License: Other (NOASSERTION)
- Topics: c, cmake, linux, windowing, windows
- Default branch: main
- Created: 2025-03-15T02:01:09Z
- Last push: 2025-12-14T04:45:12Z
- Contributors: 1 (top: bluesillybeard)

---

# Pinc 2

Pinc is a cross platform window library for game and application development, with a focus on cross-compilation, dependency minimization, and ease of integration.

Pinc is written entirely in C, making it (theoretically) portable to any system with a C compiler. Pinc currently uses cmake, however its design hopefully makes it simple to port to other build systems. See 

Title: Capy UI — Cross Platform GUI Toolkit
URL: https://capy-ui.org/
Text: Capy UI — Cross Platform GUI Toolkit

# Capy — Create cross-platform apps in Zig

Effortlessly get a native experience across all platforms.

Get Started

## Acrossall platforms.

Capy uses Zig's cross-compilation abilities in order to create an UI toolkit that runs on all major operating systems. There's no more hassle with different dev environments, you can compile from everywhere to anywhere.

Windows, Linux, Web supported. macOS and Android WIP. iOS planned.

## Simple

Capy apps always have a true native look and feel on every platform. Your users won't have to bother with small behaviour differences compared to other apps. This makes a huge difference when discovering a software.

## Native components

Capy always uses native UIs. This mean the user interfaces you make will always have the native look and feel of the target platform. When compiled for Windows, it looks like a Windows app. When compiled for Linux, it looks like a Linux app, and so on.

This provides OS-grade support for keyboard shortcuts, IME, accessibility. This ensures that even them obscure keyboard shortcuts from KDE to Windows still work.

Capy is made possible by Zig, featur

Title: GitHub - hexops/mach-core: window+input+GPU, truly cross-platform
Author: hexops
Published Date: 2023-04-05T00:00:00.000Z
URL: https://github.com/hexops/mach-core
Text: GitHub - hexops/mach-core: window+input+GPU, truly cross-platform
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

hexops

/
**
mach-core
**
Public
*
* Notifications
 You must be signed in to change notification settings
* Fork
30

*

Star
184

*
window+input+GPU, truly cross-platform
machengine.org/core

184
stars
 
30
forks
 
B

Title: GitHub - StoryTreeGames/windowing: A native OS window creation and management library made in pure zig
Author: StoryTreeGames
Published Date: 2024-03-26T00:00:00.000Z
URL: https://github.com/storytreegames/windowing
Text: # Repository: StoryTreeGames/zinit

Cross platform window creation and management library made in pure zig

- Stars: 7
- Forks: 0
- Watchers: 7
- Open issues: 5
- Primary language: Zig
- Languages: Zig (100.0%), C
- License: BSD 2-Clause "Simplified" License (BSD-2-Clause)
- Default branch: main
- Created: 2024-03-26T21:45:44Z
- Last push: 2026-01-30T17:31:37Z
- Contributors: 1 (top: Tired-Fox)

---

# Zig Native Window Library (ZNWL)

This project serves as a part of a larger project to create a game engine from scratch. However, I strive to keep this library abstracted from the game engine and more generic. The initial focus of features may be around getting a minimal product for the engine, but I plan to expand the library to be generic and easy to use for any purpose.

I am fairly new to Zig and it has been a few years since I last programmed in C/C++. With that in mind this project also serves as a learning tool for Zig, system programming, and open source.

I hope to keep all my projects as open so

Title: Capy – Cross-platform library for making native GUIs in Zig
URL: https://news.ycombinator.com/item?id=32314757
Text: Capy –Cross-platform library for making native GUIs in Zig | Hacker News|**Hacker News**new|past|comments|ask|show|jobs|submit|login|
|
|
|Capy –Cross-platform library for making native GUIs in Zig(github.com/capy-ui)|
|164 pointsbySparkensteinon Aug 2, 2022|hide|past|favorite|52comments|
|
|
comexon Aug 2, 2022|next[[–]]
There&#x27;s a severe lack of good libraries of this type; all the UI libraries want to invent their own controls and rendering instead.
I think this is a shame, demonstrating more than a small amount of NIH. Yes, different platforms have different widgets and different design guidelines, so a cross-platform UI using greatest-common-denominator set of native widgets will never look quite native. But at least text boxes will work the way text boxes should work, with keyboard shortcuts, the special characters menu, IME, the works. That already puts you ahead of most cross-platform UI frameworks that aren&#x27;t browser engines! Menus will work the way menus should work. HiDPI will work (failing to support that is less common these days, but it still happens). Text rendering will look native.

Title: Desktop web wrapper for Zig recommendation - Help
URL: https://ziggit.dev/t/desktop-web-wrapper-for-zig-recommendation/10904
Text: Desktop web wrapper for Zig recommendation - Help - Ziggit

Skip to main content


Ziggit

Sign Up
Log In
*
​
​
Ziggit is a forum for those interested in, or who are currently programing in the Zig Programming Language. We hope you find what you’re looking for, or help others to do just that. Feel free to post any forum-related issues in the *Site Feedback* category. Once again, welcome to Ziggit and thanks for being part of the Zig community.
#

Desktop web wrapper for Zig recommendation 
Help
build-system
You have selected **0** posts.

select all


cancel selecting

685
views
10
likes
10
links


4














Jul 2025

2 / 8
Jul 2025

Aug 2025

##
post by Volk on Jul 10, 2025




Volk

1

Jul 2025

What would anyone suggest for Zig desktop apps (using web stack as frontend) that is not electron or tauri?
I found Photino, but I would prefer a Zig-compatible or even Zig-based option if possible. No problem if it’s still in very early stages.
New into Zig, so I’m still researching what I can potentially use in the future for some projects. While existing options mentioned can be used, most o

Title: Search code, repositories, users, issues, pull requests...
Author: capy-ui
Published Date: 2021-03-24T00:00:00.000Z
URL: https://github.com/capy-ui/capy
Text: GitHub - capy-ui/capy: 💻Build one codebase and get native UI on Windows, Linux and Web
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
capy-ui/**capy**Public
* NotificationsYou must be signed in to change notification settings
* Fork90
* Star2.5k
💻Build one codebase and get native UI on Windows, Linux a

Title: Zig GUI From Scratch (Part 1) - vogt.world
URL: https://www.vogt.world/zig-gui-from-scratch-part-1/
Text: Zig GUI From Scratch (Part 1) - vogt.world
# Zig GUI From Scratch (Part 1)
October 27, 2024
writingcodezigprojects
This is the first of hopefully many posts as I work on building a cross-platform desktop GUI
application using Zig. I&rsquo;m probably going to open-source this at some point, but in the mean time
it&rsquo;s fun and interesting to write about. Hopefully I can share the details, reasoning, and
things I&rsquo;ve learned along the way.
These posts are going to be informal and unceremonious, and I&rsquo;m not going to ask pardon for it; the
goal here is to write something, and keep the updates flowing, rather than make them perfect.
## Motivation + Tech Stack
I want to build something challenging, from scratch, without learning a lot of frameworks, or
absorbing someone else&rsquo;s abstraction. I also think there&rsquo;s a certain art to writing code, because
writing code is art. Not in the sense that art is never finished, and neither is code (there will
always be bugs, etc) but in the sense that they&rsquo;re creative acts. I wanted to work on an application
that is challenging, and free from self critique.


```

---

## Assistant (Plan · minimax-m2.5-free · 16.6s)

_Thinking:_

This is very helpful! Let me summarize what I've found:

1. **mach-core** - hexops' cross-platform window+input+GPU library - 184 stars, very comprehensive
2. **capy** - Cross-platform native UI toolkit - 2.5k stars, supports Windows, Linux, Web (macOS WIP)
3. **storytree-core/windowing** - Pure Zig cross-platform window library - 7 stars, actively maintained
4. **Pinc2** - C library for cross-platform window (can use from Zig)

Also there's **Capy** which is specifically for cross-platform native UIs.

Let me get more details on mach-core since it seems most relevant for what the user wants (window + GPU).

**Tool: webfetch**

**Input:**
```json
{
  "format": "markdown",
  "url": "https://github.com/hexops/mach-core"
}
```

**Output:**
```
                        GitHub - hexops/mach-core: window+input+GPU, truly cross-platform · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fhexops%2Fmach-core)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub SparkBuild and deploy intelligent apps
            
            ](https://github.com/features/spark)
        -   [
            
            GitHub ModelsManage and compare prompts
            
            ](https://github.com/features/models)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/accelerator)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fhexops%2Fmach-core)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=hexops%2Fmach-core)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[hexops](/hexops) / **[mach-core](/hexops/mach-core)** Public

-   ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   [Notifications](/login?return_to=%2Fhexops%2Fmach-core) You must be signed in to change notification settings
-   [Fork 27](/login?return_to=%2Fhexops%2Fmach-core)
-   [Star 182](/login?return_to=%2Fhexops%2Fmach-core)
    

-   [Code](/hexops/mach-core)
-   [Pull requests 0](/hexops/mach-core/pulls)
-   [Actions](/hexops/mach-core/actions)
-   [Projects](/hexops/mach-core/projects)
-   [Security 0](/hexops/mach-core/security)
-   [Insights](/hexops/mach-core/pulse)

Additional navigation options

-   [Code](/hexops/mach-core)
-   [Pull requests](/hexops/mach-core/pulls)
-   [Actions](/hexops/mach-core/actions)
-   [Projects](/hexops/mach-core/projects)
-   [Security](/hexops/mach-core/security)
-   [Insights](/hexops/mach-core/pulse)

 [](/hexops/mach-core)

# hexops/mach-core

 moved

[Branches](/hexops/mach-core/branches)[Tags](/hexops/mach-core/tags)

[](/hexops/mach-core/branches)[](/hexops/mach-core/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[277 Commits](/hexops/mach-core/commits/moved/)

[](/hexops/mach-core/commits/moved/)277 Commits

[README.md](/hexops/mach-core/blob/moved/README.md "README.md")

[README.md](/hexops/mach-core/blob/moved/README.md "README.md")

View all files

## Repository files navigation

-   [README](#)

 [![mach-core](https://camo.githubusercontent.com/356f11474f42edf719df25db8aae9548bc76ad205b4f632ba3d70f340a5aa009/68747470733a2f2f6d616368656e67696e652e6f72672f6173736574732f6d6163682f636f72652d66756c6c2d6c696768742e737667)](https://machengine.org/pkg/mach-core)

window+input+GPU, truly cross-platform

## Moved

[](#moved)

This project has moved into [the Mach standard library](https://machengine.org/engine/stdlib/), to upgrade see [the migration guide](https://machengine.org/core/migrations/#machcore-package-url-change-2024-03-06)

## About

window+input+GPU, truly cross-platform

[machengine.org/core](https://machengine.org/core "https://machengine.org/core")

### Topics

[gamedev](/topics/gamedev "Topic: gamedev") [ziglang](/topics/ziglang "Topic: ziglang")

### Resources

[Readme](#readme-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/hexops/mach-core/activity)

[Custom properties](/hexops/mach-core/custom-properties)

### Stars

[**182** stars](/hexops/mach-core/stargazers)

### Watchers

[**4** watching](/hexops/mach-core/watchers)

### Forks

[**27** forks](/hexops/mach-core/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fhexops%2Fmach-core&report=hexops+%28user%29)

## [Releases](/hexops/mach-core/releases)

[2 tags](/hexops/mach-core/tags)

## Sponsor this project

### Uh oh!

There was an error while loading. Please reload this page.

## [Packages 0](/orgs/hexops/packages?repo_name=mach-core)

### Uh oh!

There was an error while loading. Please reload this page.

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors](/hexops/mach-core/graphs/contributors)

### Uh oh!

There was an error while loading. Please reload this page.

## Languages

-   [Zig 95.1%](/hexops/mach-core/search?l=zig)
-   [JavaScript 4.7%](/hexops/mach-core/search?l=javascript)
-   [C 0.2%](/hexops/mach-core/search?l=c)

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```

---

## Assistant (Plan · minimax-m2.5-free · 14.9s)

_Thinking:_

I see - mach-core has moved to "the Mach standard library". Let me search for more details about it.

**Tool: websearch**

**Input:**
```json
{
  "query": "Mach engine standard library window zig cross-platform"
}
```

**Output:**
```
Title: Mach: A Modern Zig Game Engine Pushing the Boundaries - Oreate AI Blog
Author: oreate
Published Date: 2026-02-13T00:00:00.000Z
URL: http://oreateai.com/blog/mach-a-modern-zig-game-engine-pushing-the-boundaries/8eccb365f4b8b7716de24f132a10d09c
Text: Mach: A Modern Zig Game Engine Pushing the Boundaries - Oreate AI Blog

It's always exciting to see new tools emerge in the game development space, especially when they're built with modern languages and a focus on performance. That's precisely where Mach comes in. While the name "ZIG Game Engine" might pop up in searches, it's important to clarify that the primary project gaining traction and being actively developed is Mach, a powerful game engine and graphics toolkit built using the Zig programming language.

Think of Mach as a contemporary answer to the need for a robust, cross-platform engine that doesn't shy away from complexity. It's designed from the ground up to be modular and efficient, aiming to serve not just games but also visualization applications and desktop/mobile GUI projects. This ambition is reflected in its architecture, which embraces modern standards and practices.

One of the standout features of Mach is its commitment to true cross-platform compatibilit

Title: GitHub - hexops/mach-core: window+input+GPU, truly cross-platform
Author: hexops
Published Date: 2023-04-05T00:00:00.000Z
URL: https://github.com/hexops/mach-core
Text: GitHub - hexops/mach-core: window+input+GPU, truly cross-platform
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

hexops

/
**
mach-core
**
Public
*
* Notifications
 You must be signed in to change notification settings
* Fork
30

*

Star
184

*
window+input+GPU, truly cross-platform
machengine.org/core

184
stars
 
30
forks
 
B

Title: GitHub - Brugarolas/mach-engine: zig game engine & graphics toolkit
Author: Brugarolas
Published Date: 2024-03-12T00:00:00.000Z
URL: https://github.com/Brugarolas/mach-engine
Text: GitHub - Brugarolas/mach-engine: zig game engine &amp; graphics toolkit
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign upReseting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
Brugarolas/**mach-engine**Public
forked fromhexops/mach
* NotificationsYou must be signed in to change notification settings
* Fork0
* Star0
zig game engine &amp; graphics toolkit
machengine.org
### License

Title: Mach v0.3 released - Zig game engine & graphics toolkit
URL: https://devlog.hexops.com/2024/mach-v0.3-released/
Text: Mach v0.3 released - Zig game engine & graphics toolkit | Hexops' devlog

Mach is a Zig game engine & graphics toolkit for building high-performance & modular games, visualizations, and desktop/mobile apps. Learn more

We are working towards Mach 1, and have just released v0.3 which includes 6 months of work- here are the highlights!

## Coming soon: intro to 2D gamedev workshop

The first-ever intro to 2D gamedev workshop using Mach will be hosted at the Software You Can Love conference in Milan, Italy, May 14-17. The workshop will use Mach’s currently in-development higher level 2D graphics APIs.

If you’re interested in Zig or Mach, then check out the SYCL conference! It’s an amazing experience, a great opportunity to meet a ton of Zig community members, core team members, as well as enjoy some of the best food that Italy has to offer!

## Community highlight: Pixi and Scoop’ems

@foxxne is an early adopter of Mach core, largely pushing it to its limits. They make use of Mach’s new experimental sysgpu graphics API (which we intend to be a successor/descendant of WebGPU), as well as other libraries like 

Title: GitHub - hexops/mach-glfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Author: hexops
Published Date: 2021-10-24T00:00:00.000Z
URL: https://github.com/hexops/mach-glfw
Text: GitHub - hexops/mach-glfw: Ziggified GLFW bindings with 100% API coverage, zero-fuss installation, cross compilation, and more.
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

hexops

/
**
mach-glfw
**
Public
*
* Notifications
 You must be signed in to change notifica

Title: GitHub - StoryTreeGames/windowing: A native OS window creation and management library made in pure zig
Author: StoryTreeGames
Published Date: 2024-03-26T00:00:00.000Z
URL: https://github.com/storytreegames/windowing
Text: GitHub - StoryTreeGames/storytree-core: A native OS window creation and management library made in pure zig
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Appearance settings
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
StoryTreeGames/**storytree-core**Public
* NotificationsYou must be signed in to change 

Title: Mach: zig game engine & graphics toolkit
URL: https://machengine.org/
Text: Mach: zig game engine & graphics toolkit


DocsProject
DevlogGitHubDiscordHeartDonate
# Mach
## Zig game engine & graphics toolkit
For building high-performance, truly cross-platform, robust & modular games, visualizations, and desktop/mobile GUI apps.
What's new in v0.3?

Get started
# Built with love, hard-work & Zig
Zigis a general-purpose simple programming language featuring compile-time code execution, blazing-fast compilation speeds, and bare-metal performance.

## Get started in \~60 seconds
Zero system dependenciesto slow you down; onlyzigis needed, we build and package the few relevant dependencies on our own.
To run on your machine: 
```
`$ git clone https://github.com/hexops/mach
$ cd mach/ && git checkout 0.4
$ zig build run-core-textured-cube`
```
Requiresthis nominated Zig version|known issues 
## Effortless cross-compilation
Cross-compile to any OS at the flip of a switch.
```
`$ zig build -Dtarget=x86\_64-windows
$ zig build -Dtarget=x86\_64-linux-gnu
$ zig build -Dtarget=x86\_64-macos
$ zig build -Dtarget=aarch64-macos`
```

mach-glfw# Comprehensive, but modular
## Competitive with other engines
Our ultimate aim is for Mach to ha

Title: How to make a cross platform window + inputs for my game ...
Author: MasterpieceMajor1056
URL: https://www.reddit.com/r/Zig/comments/1j1d2zj/how_to_make_a_cross_platform_window_inputs_for_my/
Text: 
 How to make a cross platform window + inputs for my game written in zig 
 Author: MasterpieceMajor1056 
 Time Posted (UTC): 2025-03-01 23:36:54+00:00 
 Score: 7 
 


 
 Link: https://www.reddit.com/r/Zig/comments/1j1d2zj/how_to_make_a_cross_platform_window_inputs_for_my/ 
 


 
 **I am aiming to build a demo project of a game with zig as the main language.** Also, mind that I am new to Zig, I may not know a simple solution to my worry. I want it to be low level, because tools like Unidy3d and Godot have failed me with their magical side effect black box approaches to many things *(I know that Godot is open source, but when I want to build a game, I don't want to spend hours searching through the engine's source code to fix some desync network api stuff if I can write something similar myself from scratch in a reasonable time, that I will later understand fully.)* Anyway, I decided that I want to use Vulkan for my rendering and Jolt for the physics. I've seen binding for those, and I am not afraid to write my own if needed. **


```

---

## Assistant (Plan · minimax-m2.5-free · 36.0s)

_Thinking:_

This is very helpful! I now have a clearer picture. Let me summarize what I've found for cross-platform options in Zig:1. **Mach** - The most comprehensive cross-platform engine. It has moved the mach-core to "Mach standard library" at machengine.org. It supports:
   - Windows, Linux (X11 + Wayland), macOS
   - Web (via WebGPU)
   - Zero system dependencies - builds everything from source
   - Has its own sysgpu (WebGPU successor) graphics API

2. **storytree-core/windowing** - Pure Zig cross-platform window library

3. **Capy** - For native GUI, supports Windows, Linux, Web (macOS WIP)Now let me think about what to present to the user. Since they want to create from scratch but also cross-platform, I should present both options:

**Option A: Use existing cross-platform library (easier)**
- Mach - comprehensive, zero deps
- storytree-core - pure Zig, lightweight
- ZWL - pure Zig

**Option B: Create custom abstraction layer (harder but more control)**
- Create platform-specific implementations for each OS
- Abstract behind a common interface
- Much more work but full controlLet me present this clearly to the user.

Now I have a clear picture. Here's the comprehensive answer:

---

## Cross-Platform Window Management in Zig

### Option A: Use Existing Libraries (Easier)

| Library | Platforms | Status | Notes |
|---------|-----------|--------|-------|
| **Mach** (machengine.org) | Linux, Windows, macOS, Web | ✅ Production | Zero deps, builds everything |
| **storytree-core/windowing** | All 4 | ✅ Active | Pure Zig |
| **ZWL** | Linux, macOS, Windows | ⚠️ Older | 91 stars, may need updates |

**Mach** is particularly impressive:
- Zero system dependencies
- Builds everything from source (including GPU drivers)
- Supports all target platforms
- Has its own `sysgpu` graphics API

---

### Option B: Create Custom Abstraction (From Scratch)

This is harder but gives you full control:

```
                    ┌─────────────────────────────────────┐
                    │       Platform Abstraction Layer    │
                    │         (common interface)         │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐        ┌───────────────┐        ┌───────────────┐
│    Linux      │        │   Windows    │        │    macOS      │
│  ┌─────────┐  │        │              │        │               │
│  │ X11     │  │        │   Win32     │        │  AppKit/     │
│  │ Wayland │  │        │   (WinRT)   │        │  Metal       │
│  └─────────┘  │        │              │        │               │
└───────────────┘        └───────────────┘        └───────────────┘
        │
        ▼
┌───────────────┐
│     Web       │
│  ┌─────────┐  │
│  │ Canvas  │  │
│  │ DOM     │  │
│  └─────────┘  │
└───────────────┘
```

---

### What's Needed for Each Platform

| Platform | Window API | Graphics | Events |
|----------|------------|----------|--------|
| **Linux X11** | Xlib/XCB | Vulkan/OpenGL | X events |
| **Linux Wayland** | Wayland protocols | Vulkan | wl callbacks |
| **Windows** | Win32/WinRT | D3D12/Vulkan | MSG loop |
| **macOS** | AppKit/Metal | Metal | NSRunLoop |
| **Web** | HTML Canvas | WebGPU | JS events |

---

### Effort Comparison

| Approach | Time to Implement | Maintenance | Control |
|----------|-------------------|-------------|---------|
| **Use Mach** | 1 hour | Low | Low |
| **Use storytree** | 1 hour | Low | Medium |
| **Custom abstraction** | 2-3 weeks | High | Full |

---

### My Recommendation

**For your goals**, here's what I'd suggest:

1. **If you want it working fast** → Use **Mach** or **storytree-core**
   - Already cross-platform
   - Well-tested
   - Works with WebGPU

2. **If you want to learn** → Create **thin abstraction** over existing libs
   - Use platform-specific libs under the hood
   - Write once, swap implementations

3. **If you want total control** → Build **platform-specific modules** from scratch
   - More work upfront
   - Full understanding
   - But: reinventing the wheel

---

**Questions to clarify:**

1. What's your primary goal?
   - a) Get a working app quickly
   - b) Learn how window systems work
   - c) Full control over everything

2. How much time do you want to spend?
   - a) Hours (use existing lib)
   - b) Days (thin abstraction)
   - c) Weeks (from scratch per platform)

3. Which platforms are must-haves?
   - All 5 (Linux X11+Wayland, Windows, macOS, Web)?
   - Just desktop + web?
   - Something else?

This will help me give you the best plan!

---

## User

1) c
2) c
3) All

how about i implement only for wayland for now and then later implement for other platforms as well?

---

## Assistant (Plan · claude-sonnet-4-6 · 6.3s)

Great approach — start with Wayland, design the abstraction correctly from day one so other platforms slot in later. Let me look at the current project structure first.

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul</path>
<type>directory</type>
<entries>
.git/
.gitignore
.zig-cache/
AGENTS.md
build.zig
build.zig.zon
src/
zig-out/
zig-pkg/

(9 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/src/main.zig"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/src/main.zig</path>
<type>file</type>
<content>1: const std = @import("std");
2: const Io = std.Io;
3: 
4: const zimul = @import("zimul");
5: const rl = @import("raylib");
6: 
7: pub fn main() !void {
8:     rl.setTraceLogLevel(.all);
9: 
10:     rl.initWindow(800, 400, "zimul");
11:     defer rl.closeWindow();
12: 
13:     rl.setTargetFPS(144);
14: 
15:     while (!rl.windowShouldClose()) {
16:         rl.beginDrawing();
17:         defer rl.endDrawing();
18: 
19:         rl.clearBackground(rl.Color.blue);
20:         rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.white);
21:     }
22: }

(End of file - total 22 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/build.zig</path>
<type>file</type>
<content>1: const std = @import("std");
2: 
3: pub fn build(b: *std.Build) void {
4:     const target = b.standardTargetOptions(.{});
5:     const optimize = b.standardOptimizeOption(.{});
6: 
7:     const mod = b.addModule("zimul", .{
8:         .root_source_file = b.path("src/root.zig"),
9:         .target = target,
10:         .optimize = optimize,
11:     });
12: 
13:     const exe = b.addExecutable(.{
14:         .name = "zimul",
15:         .root_module = b.createModule(.{
16:             .root_source_file = b.path("src/main.zig"),
17:             .target = target,
18:             .optimize = optimize,
19:             .imports = &.{
20:                 .{ .name = "zimul", .module = mod },
21:             },
22:         }),
23:     });
24: 
25:     // Raylib
26:     const raylib_dep = b.dependency("raylib_zig", .{
27:         .target = target,
28:         .optimize = optimize,
29:         .linux_display_backend = @as(@import("raylib_zig").LinuxDisplayBackend, .X11),
30:     });
31:     const raylib_artifact = raylib_dep.artifact("raylib");
32:     exe.root_module.linkLibrary(raylib_artifact);
33:     // Add a C shim that references glClear to force libGL into DT_NEEDED.
34:     // This ensures GLVND dispatch is initialized by the dynamic linker before
35:     // GLFW's dlopen call, fixing black windows on XWayland+NVIDIA.
36:     exe.root_module.addCSourceFile(.{
37:         .file = b.path("src/gl_preload.c"),
38:         .flags = &.{},
39:     });
40:     exe.root_module.linkSystemLibrary("GL", .{});
41:     exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
42:     exe.root_module.addImport("raygui", raylib_dep.module("raygui"));
43: 
44:     b.installArtifact(exe);
45: 
46:     const run_step = b.step("run", "Run the app");
47: 
48:     const run_cmd = b.addRunArtifact(exe);
49:     run_step.dependOn(&run_cmd.step);
50: 
51:     run_cmd.step.dependOn(b.getInstallStep());
52: 
53:     if (b.args) |args| {
54:         run_cmd.addArgs(args);
55:     }
56: 
57:     // Check
58:     const exe_check = b.addExecutable(.{
59:         .name = "zimul",
60:         .root_module = exe.root_module,
61:     });
62: 
63:     const check_step = b.step("check", "Check");
64:     check_step.dependOn(&exe_check.step);
65: }

(End of file - total 65 lines)
</content>
```

---

## Assistant (Plan · claude-sonnet-4-6 · 3.1s)

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/src/root.zig"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/src/root.zig</path>
<type>file</type>
<content>1: //! By convention, root.zig is the root source file when making a package.
2: const std = @import("std");
3: const Io = std.Io;
4: 
5: /// This is a documentation comment to explain the `printAnotherMessage` function below.
6: ///
7: /// Accepting an `Io.Writer` instance is a handy way to write reusable code.
8: pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
9:     try writer.print("Run `zig build test` to run the tests.\n", .{});
10: }
11: 
12: pub fn add(a: i32, b: i32) i32 {
13:     return a + b;
14: }
15: 
16: test "basic add functionality" {
17:     try std.testing.expect(add(3, 7) == 10);
18: }

(End of file - total 18 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/home/mzwallow/Development/zimul/build.zig.zon"
}
```

**Output:**
```
<path>/home/mzwallow/Development/zimul/build.zig.zon</path>
<type>file</type>
<content>1: .{
2:     // This is the default name used by packages depending on this one. For
3:     // example, when a user runs `zig fetch --save <url>`, this field is used
4:     // as the key in the `dependencies` table. Although the user can choose a
5:     // different name, most users will stick with this provided value.
6:     //
7:     // It is redundant to include "zig" in this name because it is already
8:     // within the Zig package namespace.
9:     .name = .zimul,
10:     // This is a [Semantic Version](https://semver.org/).
11:     // In a future version of Zig it will be used for package deduplication.
12:     .version = "0.0.0",
13:     // Together with name, this represents a globally unique package
14:     // identifier. This field is generated by the Zig toolchain when the
15:     // package is first created, and then *never changes*. This allows
16:     // unambiguous detection of one package being an updated version of
17:     // another.
18:     //
19:     // When forking a Zig project, this id should be regenerated (delete the
20:     // field and run `zig build`) if the upstream project is still maintained.
21:     // Otherwise, the fork is *hostile*, attempting to take control over the
22:     // original project's identity. Thus it is recommended to leave the comment
23:     // on the following line intact, so that it shows up in code reviews that
24:     // modify the field.
25:     .fingerprint = 0x652d4f49928472cf, // Changing this has security and trust implications.
26:     // Tracks the earliest Zig version that the package considers to be a
27:     // supported use case.
28:     .minimum_zig_version = "0.16.0-dev.2682+02142a54d",
29:     // This field is optional.
30:     // Each dependency must either provide a `url` and `hash`, or a `path`.
31:     // `zig build --fetch` can be used to fetch all dependencies of a package, recursively.
32:     // Once all dependencies are fetched, `zig build` no longer requires
33:     // internet connectivity.
34:     .dependencies = .{
35:         .raylib_zig = .{
36:             .url = "/home/mzwallow/Development/raylib-zig",
37:             .hash = "raylib_zig-5.6.0-dev-KE8REFFOBQCQGmJT17KHj8mmGBENuOAKj-Sep881zkKH",
38:         },
39:     },
40:     .paths = .{
41:         "build.zig",
42:         "build.zig.zon",
43:         "src",
44:         // For example...
45:         //"LICENSE",
46:         //"README.md",
47:     },
48: }

(End of file - total 48 lines)
</content>
```

---

## Assistant (Plan · claude-sonnet-4-6 · 35.7s)

Good — I have full context. Here's the complete plan:

---

## Plan: Cross-Platform Window Abstraction (Wayland First)

### Core Design Philosophy

The key to making this extensible is a **platform-agnostic interface** defined once, with platform-specific backends plugged in at compile time using Zig's `comptime`. You never touch `main.zig` when adding a new platform.

---

### Abstraction Design

```
src/
├── main.zig                  # App code — uses only platform.zig API
├── root.zig                  # Lib exports
│
├── platform.zig              # The common interface (comptime dispatch)
│
├── platform/
│   ├── wayland/              # Linux Wayland (Phase 1 — now)
│   │   ├── mod.zig           # Exports Platform impl
│   │   ├── connection.zig    # wl_display connect/disconnect
│   │   ├── registry.zig      # wl_registry + interface binding
│   │   ├── window.zig        # wl_surface + xdg_toplevel
│   │   └── events.zig        # Event loop + input callbacks
│   │
│   ├── x11/                  # Linux X11 (Phase 2 — later)
│   │   └── mod.zig           # stub
│   │
│   ├── win32/                # Windows (Phase 3 — later)
│   │   └── mod.zig           # stub
│   │
│   ├── cocoa/                # macOS (Phase 4 — later)
│   │   └── mod.zig           # stub
│   │
│   └── web/                  # Browser (Phase 5 — later)
│       └── mod.zig           # stub
│
└── webgpu/
    ├── mod.zig               # wgpu-native @cImport wrapper
    ├── instance.zig          # WGPUInstance creation
    ├── surface.zig           # wl_surface → WGPUSurface
    ├── device.zig            # Adapter + Device + Queue
    └── pipeline.zig          # Render pipeline
```

---

### The Interface (`platform.zig`)

The single interface all backends implement:

```zig
// platform.zig — every backend implements this
pub const Platform = switch (builtin.os.tag) {
    .linux => @import("platform/wayland/mod.zig"),
    .windows => @import("platform/win32/mod.zig"),
    .macos => @import("platform/cocoa/mod.zig"),
    else => @compileError("unsupported platform"),
};

// The common interface all backends must expose:
// Platform.init(allocator, options) !Window
// Platform.deinit()
// Window.pollEvents() void
// Window.shouldClose() bool
// Window.getWaylandDisplay() ?*anyopaque   <- for wgpu surface
// Window.getWaylandSurface() ?*anyopaque
// Window.size() struct { w: u32, h: u32 }
```

---

### Phase 1: Wayland Backend (What We Implement Now)

#### 1. `connection.zig` — Wayland Display
- Call `wl_display_connect(null)` via `libwayland-client`
- Store `*wl_display`
- Handle disconnect + error

#### 2. `registry.zig` — Interface Binding
Bind these globals from `wl_registry`:
| Interface | Version | Purpose |
|-----------|---------|---------|
| `wl_compositor` | 6 | Create surfaces |
| `wl_shm` | 1 | Shared memory (for cursor) |
| `xdg_wm_base` | 6 | Window management |
| `wl_seat` | 9 | Input devices |

#### 3. `window.zig` — Window Surface
- Create `wl_surface` from compositor
- Wrap in `xdg_surface` → `xdg_toplevel`
- Handle configure/close/resize events
- Set title, min size, app ID

#### 4. `events.zig` — Event Loop
- `wl_display_dispatch()` / `wl_display_flush()`
- Keyboard: `wl_keyboard_listener` (key down/up, modifiers)
- Pointer: `wl_pointer_listener` (move, button, scroll)

#### 5. wgpu surface
- Pass `wl_display` + `wl_surface` pointers to wgpu:
  ```zig
  WGPUSurfaceDescriptorFromWaylandSurface{
      .display = wayland_display,
      .surface = wayland_surface,
  }
  ```

---

### Build Setup

**Dependencies to add to `build.zig.zon`:**
- `wgpu-native` prebuilt binary (from GitHub releases, pinned version)
- `webgpu-headers` (`webgpu.h` + `wgpu.h`)

**`build.zig` changes:**
- Remove raylib entirely
- Link `libwayland-client` (system)
- Link `libwgpu_native.a` (static, from fetched release)
- `addCSourceFile` for wgpu headers

**Zig version is `0.16.0-dev.2682+`** — we need to pick a wgpu-native version whose headers match what we write bindings for. We'll pin to **v27.0.4.0** (latest stable as of Dec 2025).

---

### What `main.zig` Looks Like After

```zig
const platform = @import("platform.zig");
const webgpu = @import("webgpu/mod.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Init window (platform-agnostic)
    var window = try platform.Platform.init(allocator, .{
        .title = "zimul",
        .width = 800,
        .height = 400,
    });
    defer window.deinit();

    // Init WebGPU
    var gpu = try webgpu.init(&window);
    defer gpu.deinit();

    // Render loop
    while (!window.shouldClose()) {
        window.pollEvents();

        const frame = try gpu.beginFrame();
        // ... render ...
        gpu.endFrame(frame);
    }
}
```

---

### Files to Change vs Create

| Action | File | Notes |
|--------|------|-------|
| **Replace** | `src/main.zig` | Remove raylib, use new API |
| **Replace** | `build.zig` | Remove raylib, add wgpu-native + wayland |
| **Replace** | `build.zig.zon` | Replace raylib_zig dep with wgpu-native |
| **Keep** | `src/root.zig` | Unchanged |
| **Delete** | `src/gl_preload.c` | No longer needed |
| **Create** | `src/platform.zig` | Comptime platform dispatch |
| **Create** | `src/platform/wayland/mod.zig` | Wayland backend |
| **Create** | `src/platform/wayland/connection.zig` | |
| **Create** | `src/platform/wayland/registry.zig` | |
| **Create** | `src/platform/wayland/window.zig` | |
| **Create** | `src/platform/wayland/events.zig` | |
| **Create** | `src/webgpu/mod.zig` | wgpu-native C bindings |
| **Create** | `src/webgpu/instance.zig` | |
| **Create** | `src/webgpu/surface.zig` | |
| **Create** | `src/webgpu/device.zig` | |
| **Create** | `src/webgpu/pipeline.zig` | |

---

### Estimated Scope

| Module | Lines | Difficulty |
|--------|-------|------------|
| Wayland connection | ~80 | Easy |
| Registry binding | ~150 | Medium |
| Window/XDG shell | ~200 | Medium |
| Event loop | ~150 | Medium |
| wgpu bindings | ~300 | Medium |
| build.zig setup | ~60 | Easy |
| **Total** | **~940** | |

---

### Open Questions Before Starting

1. **wgpu-native linking**: Static (`.a`) or dynamic (`.so`)? Static is simpler, no runtime path issues.

2. **Wayland protocols**: Should we use `wayland-scanner` at build time to generate protocol code, or hand-write the C interop? Hand-writing is simpler for now.

3. **Cursor support**: Include it from the start or skip for now?

4. **Input events**: Do you want a callback-based API or a poll-based queue (like `while (window.nextEvent()) |event| { ... }`)?

---

## User

i'm very new to this thing wayland, display backend, working with c, zig. can you suggest me

---

## Assistant (Plan · claude-sonnet-4-6 · 22.4s)

That's a very honest and self-aware question. Let me give you a straight answer.

---

## Honest Assessment

Building a cross-platform window manager from scratch requires understanding several layers simultaneously:

| Layer | What You Need to Know |
|-------|-----------------------|
| **Wayland protocol** | How compositors work, wire protocol, object/interface model |
| **C interop in Zig** | `@cImport`, extern structs, C pointers, ABI |
| **WebGPU/wgpu-native** | GPU adapter/device/surface/pipeline concepts |
| **Build systems** | Linking `.a`/`.so` files, pkg-config, compile flags |
| **OS concepts** | File descriptors, shared memory, event loops |

Each of these is a multi-day topic on its own. Combining all 5 at once is a steep cliff.

---

## Suggested Learning Path

Rather than jumping straight to "build it all from scratch", here's a progression that builds understanding one layer at a time:

### Step 1 — Learn Zig ↔ C interop (1-2 days)
Write small programs that call C functions from Zig:
- Call `printf` via `@cImport`
- Use a simple C struct from Zig
- Link a `.a` static library manually

**Why:** Everything else depends on this.

### Step 2 — Learn the Wayland wire protocol (2-3 days)
Read through these in order:
- https://wayland-book.com — the definitive free book
- Chapter 1 (architecture), Chapter 4 (objects), Chapter 7 (surfaces)

Write a tiny C program (not Zig yet) that opens a Wayland window using `libwayland-client` directly. Many tutorials exist for this.

**Why:** You need to understand *what* you're wrapping before you wrap it.

### Step 3 — Port that C program to Zig (1 day)
Take your working C Wayland window and rewrite it in Zig using `@cImport` to call the same `libwayland-client` functions.

**Why:** Now you understand both sides.

### Step 4 — Learn wgpu-native basics (2-3 days)
Read the wgpu-native C examples:
- https://github.com/gfx-rs/wgpu-native/tree/trunk/examples

Get a triangle rendering in C first, then port to Zig.

**Why:** WebGPU has a lot of setup. Understanding it in C first removes one variable.

### Step 5 — Connect Wayland + wgpu-native (1-2 days)
Combine your Wayland window with your wgpu surface. This is where it comes together.

### Step 6 — Abstract into a clean Zig API (ongoing)
Only now does building the abstraction layer make sense — because you understand what you're abstracting.

---

## Alternative: Use an Existing Library Temporarily

There's no shame in using something like **zglfw** or **ZWL** while learning. You can:

1. Use an existing library **now** to get things working
2. Study how it works internally
3. Replace it with your own implementation later

This is actually how most people learn — by reading working code first.

---

## Bottom Line

| If you want to... | Do this |
|-------------------|---------|
| Learn properly | Follow the 5-step path above |
| Get something working fast | Use ZWL or zglfw for now |
| Do both | Use existing lib, read its source, replace gradually |

The from-scratch approach is absolutely worth doing — it's just better done after you've seen the pieces working individually first.

**What would you like to do?**

---

## User

from scratch, should i work with window management first?

---

## Assistant (Plan · claude-sonnet-4-6 · 24.1s)

Yes, window management first is the right order. You can't do GPU rendering without a window to render into.

Here's the recommended order and why:

---

## Build Order

```
1. Wayland Window          ← start here
        ↓
2. Event Loop (input)
        ↓
3. wgpu-native bindings
        ↓
4. WebGPU surface + render
```

Each step depends on the previous one. You can verify each step works before moving on.

---

## Step 1: Wayland Window (What We Build First)

The minimum to get a visible window on screen:

```
libwayland-client
    │
    ├── wl_display          — connect to compositor
    ├── wl_registry         — discover available interfaces
    ├── wl_compositor       — create surfaces
    └── xdg_wm_base         — turn a surface into a window
            │
            └── xdg_toplevel  — set title, handle close
```

**Goal:** A blank window appears, can be moved/resized, closes cleanly.

**You do NOT need:**
- Input handling yet
- WebGPU yet
- Shared memory buffers (wgpu replaces this)
- Cursor yet

---

## What the Code Looks Like

The Wayland protocol is **object-oriented over a Unix socket**. Every "object" (display, surface, window) is just an integer ID. You call methods by sending messages, and receive events via callbacks (listeners).

```zig
// Pseudocode of what we'll write

// 1. Connect
const display = wl_display_connect(null);

// 2. Get registry, bind compositor + xdg_wm_base
const registry = wl_display_get_registry(display);
wl_registry_add_listener(registry, &registry_listener, &state);
wl_display_roundtrip(display);  // wait for globals

// 3. Create surface
const surface = wl_compositor_create_surface(state.compositor);

// 4. Wrap in xdg window
const xdg_surface = xdg_wm_base_get_xdg_surface(state.xdg_wm_base, surface);
const toplevel = xdg_surface_get_toplevel(xdg_surface);
xdg_toplevel_set_title(toplevel, "zimul");

// 5. Commit + event loop
wl_surface_commit(surface);
while (!state.should_close) {
    wl_display_dispatch(display);
}
```

---

## Three Approaches to Calling Wayland from Zig

Since you're new to C interop, here are your options — each with different tradeoffs:

### Approach A: `@cImport` the headers (Simplest)

```zig
const wl = @cImport(@cInclude("wayland-client.h"));

const display = wl.wl_display_connect(null);
```

- Uses system `libwayland-client.so`
- Direct C struct/function access
- Easiest to start with
- **Recommended for learning**

### Approach B: Hand-write `extern` declarations (No C headers)

```zig
// Declare only what you need, no @cImport
extern fn wl_display_connect(name: ?[*:0]const u8) ?*wl_display;
extern fn wl_display_disconnect(display: *wl_display) void;
```

- No dependency on C headers
- You control exactly what's exposed
- More work upfront, more educational
- Good for understanding the ABI

### Approach C: Speak the raw wire protocol (No libwayland)

```zig
// Open the socket yourself
const sock = try std.net.connectUnixSocket(wayland_socket_path);
// Send/receive binary protocol messages manually
```

- Zero C dependencies
- Deepest understanding
- Very complex — not recommended until you understand Approach A/B

---

## My Recommendation

**Start with Approach A** (`@cImport`) because:
- You get a working window quickly
- You focus on learning *Wayland concepts* not C interop mechanics
- You can always rewrite with Approach B later once concepts are clear

**Migration path:**
```
Approach A           →    Approach B         →    Approach C
(learn concepts)          (remove C headers)       (remove libwayland)
```

---

## Concrete First Task

Write `src/platform/wayland/connection.zig` that:

1. Calls `wl_display_connect(null)`
2. Returns an error if it fails
3. Has a `deinit()` that calls `wl_display_disconnect()`
4. Compiles and links against `libwayland-client`

That's it — one file, ~30 lines. Verify it compiles before moving on.

---

**Does this make sense? Want to start implementing Step 1 with Approach A?**

---

## User

let's go approach A, u just guide me what do i need or gimme sources or directions and i will implement by myselft

---

## Assistant (Plan · claude-sonnet-4-6 · 37.4s)

Perfect approach. Here's everything you need to implement Step 1 yourself.

---

## What You're Building

A minimal Wayland window that appears on screen. Nothing more.

---

## Reading Material (in order)

**1. The Wayland Book** — read these chapters only:
- https://wayland-book.com/protocol-design/interfaces-requests-events.html
- https://wayland-book.com/registry.html
- https://wayland-book.com/xdg-shell-basics.html

**2. A minimal C example to study** (not copy — read and understand):
- https://gist.github.com/Demonstrandum/1b4cf4f5e1c31bcf2c7e4aa0b88cb0d5

**3. Zig `@cImport` docs:**
- https://ziglang.org/documentation/master/#cImport

---

## System Headers You'll Use

On your Arch system these are already installed:

```bash
# Confirm they exist
ls /usr/include/wayland-client.h
ls /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml
```

The XDG shell header doesn't exist pre-generated — you need to generate it:

```bash
wayland-scanner client-header \
    /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
    /tmp/xdg-shell-client-protocol.h
```

Study that generated header — it shows every struct, function, and listener you need.

---

## Functions You Need (in order of use)

### 1. Connect to display
```c
// wayland-client.h
struct wl_display *wl_display_connect(const char *name); // pass NULL
void               wl_display_disconnect(struct wl_display *display);
int                wl_display_roundtrip(struct wl_display *display);
int                wl_display_dispatch(struct wl_display *display);
```

### 2. Get registry
```c
struct wl_registry *wl_display_get_registry(struct wl_display *display);

// Add listener to receive global announcements
int wl_registry_add_listener(
    struct wl_registry *registry,
    const struct wl_registry_listener *listener,
    void *data
);

// Inside the listener, bind what you need:
void *wl_registry_bind(
    struct wl_registry *registry,
    uint32_t name,         // the id announced in the event
    const struct wl_interface *interface,
    uint32_t version
);
```

### 3. Create surface
```c
// wl_compositor_interface is the wl_interface to bind in registry
struct wl_surface *wl_compositor_create_surface(struct wl_compositor *compositor);
void               wl_surface_commit(struct wl_surface *surface);
```

### 4. XDG window
```c
// xdg-shell-client-protocol.h (generated)
void xdg_wm_base_add_listener(...);  // respond to ping events
struct xdg_surface  *xdg_wm_base_get_xdg_surface(xdg_wm_base, wl_surface);
struct xdg_toplevel *xdg_surface_get_toplevel(xdg_surface);

void xdg_toplevel_set_title(toplevel, "zimul");
void xdg_toplevel_set_app_id(toplevel, "zimul");

// Add listeners to handle configure + close
xdg_surface_add_listener(...);
xdg_toplevel_add_listener(...);
```

---

## The Listener Structs You Must Implement

These are callbacks Wayland calls when events arrive:

```c
// Registry: called when a global interface is available
struct wl_registry_listener {
    void (*global)(void *data, struct wl_registry *registry,
                   uint32_t name, const char *interface, uint32_t version);
    void (*global_remove)(void *data, struct wl_registry *registry,
                          uint32_t name);
};

// XDG base: must respond to ping or compositor kills you
struct xdg_wm_base_listener {
    void (*ping)(void *data, struct xdg_wm_base *xdg_wm_base, uint32_t serial);
};

// XDG surface: must ack configure
struct xdg_surface_listener {
    void (*configure)(void *data, struct xdg_surface *xdg_surface, uint32_t serial);
};

// XDG toplevel: resize + close events
struct xdg_toplevel_listener {
    void (*configure)(void *data, struct xdg_toplevel *toplevel,
                      int32_t width, int32_t height, struct wl_array *states);
    void (*close)(void *data, struct xdg_toplevel *toplevel);
};
```

In Zig these become `extern struct` with function pointers.

---

## How to Translate C Listeners to Zig

The key pattern:

```zig
// C struct with function pointers becomes an extern struct in Zig
const wl_registry_listener = extern struct {
    global: *const fn (
        data: ?*anyopaque,
        registry: *wl.wl_registry,
        name: u32,
        interface: [*:0]const u8,
        version: u32,
    ) callconv(.C) void,

    global_remove: *const fn (
        data: ?*anyopaque,
        registry: *wl.wl_registry,
        name: u32,
    ) callconv(.C) void,
};
```

Key rules:
- All callbacks must have `callconv(.C)`
- C `void *data` becomes `?*anyopaque` in Zig
- C `const char *` becomes `[*:0]const u8` in Zig
- Cast `data` back to your state struct with `@ptrCast` + `@alignCast`

---

## Your State Struct

You need one struct to carry state through all the callbacks:

```zig
const State = struct {
    compositor: ?*wl.wl_compositor = null,
    xdg_wm_base: ?*xdg.xdg_wm_base = null,
    surface: ?*wl.wl_surface = null,
    xdg_surface: ?*xdg.xdg_surface = null,
    toplevel: ?*xdg.xdg_toplevel = null,
    should_close: bool = false,
    configured: bool = false,
};
```

Pass `&state` as the `void *data` to every `add_listener` call.

---

## Build Setup

In `build.zig` you need:

```zig
// Link wayland-client
exe.root_module.linkSystemLibrary("wayland-client", .{});
exe.root_module.link_libc = true;

// Include generated xdg-shell header dir
exe.root_module.addIncludePath(b.path("src/platform/wayland/generated/"));

// Compile the generated xdg-shell glue C file
exe.root_module.addCSourceFile(.{
    .file = b.path("src/platform/wayland/generated/xdg-shell-protocol.c"),
    .flags = &.{},
});
```

Generate both files before building:
```bash
# Run these once, commit the output
wayland-scanner client-header \
    /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
    src/platform/wayland/generated/xdg-shell-client-protocol.h

wayland-scanner private-code \
    /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
    src/platform/wayland/generated/xdg-shell-protocol.c
```

---

## File Structure to Create

```
src/
├── main.zig                          ← keep simple for now
└── platform/
    └── wayland/
        ├── mod.zig                   ← exports Window struct
        ├── connection.zig            ← wl_display connect/disconnect
        ├── registry.zig              ← bind compositor + xdg_wm_base
        ├── window.zig                ← surface + toplevel + event loop
        └── generated/
            ├── xdg-shell-client-protocol.h   ← generated
            └── xdg-shell-protocol.c          ← generated
```

---

## Sequence to Implement

Implement in this exact order — verify each compiles before the next:

1. `connection.zig` — just connect + disconnect, print success
2. `registry.zig` — bind compositor + xdg_wm_base, print their addresses
3. `window.zig` — create surface, wrap in xdg_toplevel, commit
4. Event loop in `window.zig` — `while (!state.should_close) wl_display_dispatch()`
5. Wire up `should_close = true` in toplevel close callback
6. `mod.zig` — wrap everything in a clean `Window` struct

---

## Checkpoint: How You Know It Works

After step 4, running `zig build run` should:
- Show a blank window on your Hyprland desktop
- Have a title bar saying "zimul"
- Close cleanly when you press the X button

No rendering needed yet — the window will just be whatever color the compositor draws for empty surfaces (usually black or transparent). That's fine.

---

**Start with `connection.zig`. Once you have `wl_display_connect` working and printing the display pointer, come back and we'll move to the registry.**

---

## User

links u gave me is invalid/notfound

---

## Assistant (Plan · minimax-m2.5-free · 15.0s)

_Thinking:_

The user is saying the links I provided are invalid. The system reminder says I'm in plan mode - read only. Let me find valid resources for learning Wayland.

The key resources I mentioned:
1. wayland-book.com - let me verify this exists
2. A gist for minimal C example
3. Zig @cImport docs

Let me search for valid Wayland learning resources.

**Tool: websearch**

**Input:**
```json
{
  "query": "wayland client tutorial simple window C 2025"
}
```

**Output:**
```
Title: C++: Wayland client GUI: Beginner code example. Is this OK? Year 2025.
URL: https://www.linuxquestions.org/questions/programming-9/c-wayland-client-gui-beginner-code-example-is-this-ok-year-2025-a-4175753421/
Text: C++: Wayland client GUI: Beginner code example. Is this OK? Year 2025.
LinuxQuestions.org|
Welcome to the most active**Linux Forum**on the web.
|
Blogs|
Recent Entries|
Best Entries|
Best Blogs|
Blog List|
Search Blogs|
Home|Forums|Tutorials|Articles|Register|Search|
Search Forums|
|
Advanced Search|
Search Tags|
|
Search LQ Wiki|
Search Tutorials/Articles|
|
Search Reviews|
|
Search ISOs|
Go to Page...|
|
Go Back||LinuxQuestions.org&gt;Forums&gt;Non-\*NIX Forums&gt;Programming|
Reload this Page**C++: Wayland client GUI: Beginner code example. Is this OK? Year 2025.**|
|User Name||Remember Me?|
Password|||
|
**Programming**This forum is for all programming questions.
The question does not have to be directly related to Linux and any language is fair game.|
Notices|
Welcome to**LinuxQuestions.org**, a friendly and active Linux Community.
You are currently viewing LQ as a guest. By joining our community you will have the ability to post topics, receive our newsletter, use the advanced search, subscribe to threads

Title: GitHub - shivkr6/wayland-window-toy: A simple wayland window
Author: shivkr6
Published Date: 2024-02-22T00:00:00.000Z
URL: https://github.com/shivkr6/wayland-window-toy
Text: GitHub - shivkr6/wayland-window-toy: A simple wayland window
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

shivkr6

/
**
wayland-window-toy
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
0

*

Star
2

*
A simple wayland window

2
stars
 
0
forks
 
Branches
 
Tags
 
Activity


Star

Title: GitHub - zezba9000/WaylandClientWindow: Create a native Wayland client window with client-side decorations if needed. Written in C.
Author: zezba9000
Published Date: 2024-02-09T00:00:00.000Z
URL: https://github.com/zezba9000/WaylandClientWindow
Text: GitHub - zezba9000/WaylandClientWindow: Create a native Wayland client window with client-side decorations if needed. Written in C.
Skip to content
## Navigation Menu
Toggle navigation

Sign in
Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear
Search syntax tips
# Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
CancelSubmit feedback
# Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see ourdocumentation.
CancelCreate saved search
Sign in
Sign upReseting focus
You signed in with another tab or window.Reloadto refresh your session.You signed out in another tab or window.Reloadto refresh your session.You switched accounts on another tab or window.Reloadto refresh your session.Dismiss alert
{{ message }}
zezba9000/**WaylandClientWindow**Public
* NotificationsYou must be signed in

Title: GitHub - willth7/wayland-client-example: example of a wayland client with input
Author: willth7
Published Date: 2022-10-08T00:00:00.000Z
URL: https://github.com/willth7/wayland-client-example
Text: GitHub - willth7/wayland-client-example: example of a wayland client with input
Skip to content
## Navigation Menu
Toggle navigation



Sign in

Search or jump to...
# Search code, repositories, users, issues, pull requests...
 
Search
Clear

Search syntax tips

#
Provide feedback
 
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel
Submit feedback
#
Saved searches
## Use saved searches to filter your results more quickly
 
Name
Query
To see all available qualifiers, see our documentation.
Cancel
Create saved search

Sign in


Sign up

You signed in with another tab or window. Reload to refresh your session.
You signed out in another tab or window. Reload to refresh your session.
You switched accounts on another tab or window. Reload to refresh your session.
Dismiss alert
{{ message }}

willth7

/
**
wayland-client-example
**
Public
* Notifications
 You must be signed in to change notification settings
* Fork
0

*

Star
8

*
example of a wayland client with

Title: Hello, Wayland!
Author: 
Published Date: 2024-01-01T00:00:00.000Z
URL: https://developer.orbitrc.io/documentation/wayland/guides/hello-wayland/
Text: Hello, Wayland! | Orbit Developer
Orbit Developer
# Hello, Wayland#
The first step of Wayland client programming is connecting to as server. In
this chapter, we will learn about how to connect to a Wayland server and get
informations.
In this guide we will use global variables for convenience. But this is
discouraged for real applications.
## Connecting#
This is a very simple example to connect to a server and disconnect.
Create directories wherever you want. For example,
```
`$ mkdir -p wayland-client/connect
$ cd wayland-client/connect`
```
```
`/\* main.c \*/
#include &lt;&lt;stdio.h&gt;&gt;
#include &lt;&lt;stdlib.h&gt;&gt;
#include &lt;&lt;wayland-client.h&gt;&gt;
struct wl\_display \*display = NULL;
int main(int argc, char \*argv[])
{
display = wl\_display\_connect(NULL);
if (display == NULL) {
fprintf(stderr, &quot;&quot;Failed to connect to display.\\n&quot;&quot;);
exit(1);
}
printf(&quot;&quot;Connected to display!\\n&quot;&quot;);
wl\_display\_disconnect(display);
printf(&quot;&quot;Disconnected from display.\\n&quot;&quot;);
return 0;
}`
```
Then, compile it and 

Title: Writing a Wayland client from scratch in Zig
URL: https://www.seagin.me/writing-a-wayland-client-from-scratch-in-zig/
Text: Writing a Wayland client from scratch in Zig

Lately I've been enjoying writing things from scratch. Writing a Wayland client from scratch has been the most frustrating and rewarding experience of my last two weeks. The number of new things that I've learned was more than worth all the frustrations. It took two weeks but at this point I'm not sure if it was actually more. It's part of my building a debugger in Zig series.

If you'd like to skip the explanation and see the code you can find it here. It's a work in progress but it works. You'll also find links to all the resources that helped in the comments on top of the file.

### What is Wayland?

It's a communication protocol for serving windows on displays on Linux and is designed to be an improvement on X11. Which was the original window system for my debugger but since then I upgraded my OS and the OS now uses Wayland instead of X11. You can render X11 windows in Wayland (I think) but I saw an opportunity to write my own client which would be in Zig just like the rest of the code. Which makes things a lot more easier for me.

### Connecting to W

Title: Wayland Tutorial - A Wayland HowTo - The grimoire of a modern Linux professional
Author: Marco Antonio Carcano
URL: https://grimoire.carcano.ch/blog/wayland-tutorial-a-wayland-howto/
Text: Wayland Tutorial - A Wayland HowTo

The first Wayland release is dated 2012, and it was of course in a very early stage. Now 16 years have passed since the initial design, they say Wayland is mature enough that it is safe to remove X11 sessions. In the Wayland Tutorial - A Wayland HowTo post we will go through everything it is worth the effort to know about Wayland, trying to answer the question: do Wayland replace the whole X Window system, or do it replace just the X11 protocol?

Toggle

## Why Wayland Was Started

As we saw in the X Window Tutorial - X Display Server HowTo And Cheatsheet post, the X Window System is really seasoned (1984, so it's 40 years old): the software has been maintained and reworked a lot of times in all these decades, and of course the X11 protocol needed several revisions. In 2008 they decided going on with the improvement of the X11 protocol was not worth the effort and so it was a dead end: they decided drastically cut budget from the X11 protocol's maintenance and spin up a new project called Wayland, bei

Title: Extended example code - The Wayland Protocol
Author: 
URL: https://wayland-book.com/xdg-shell-basics/example-code.html
Text: Extended example code - The Wayland Protocol

# The Wayland Protocol

# Extended example code

Using the sum of what we've learned so far, we can now write a Wayland client which displays something on the screen. The following code is a complete Wayland application which opens an XDG toplevel window and shows a 640x480 grid of squares on it. Compile it like so:

```
wayland-scanner private-code \
  < /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
  > xdg-shell-protocol.c
wayland-scanner client-header \
  < /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
  > xdg-shell-client-protocol.h
cc -o client client.c xdg-shell-protocol.c -lwayland-client -lrt

```

Then run`./client` to see it in action, or`WAYLAND_DEBUG=1 ./client` to include a bunch of useful debugging information. Tada! In future chapters we will be building upon this client, so stow this code away somewhere safe.

```
#define _POSIX_C_SOURCE 200112L
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdbool.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#incl


```

---

## Assistant (Plan · minimax-m2.5-free · 21.3s)

_Thinking:_

Now I found valid resources. Let me provide the user with working links and resources.

Found working resources for you:

---

## Valid Learning Resources

### Wayland Tutorial (Beginner-friendly)
- **Orbit Dev - Hello Wayland**: https://developer.orbitrc.io/documentation/wayland/guides/hello-wayland/
- **Wayland Book - XDG Shell Example Code**: https://wayland-book.com/xdg-shell-basics/example-code.html
- **Grimoire Wayland Tutorial**: https://grimoire.carcano.ch/blog/wayland-tutorial-a-wayland-howto/

### Zig + Wayland (from scratch)
- **Writing a Wayland client from scratch in Zig**: https://www.seagin.me/writing-a-wayland-client-from-scratch-in-zig/

### Simple C Examples (to study)
- **GitHub - shivkr6/wayland-window-toy**: https://github.com/shivkr6/wayland-window-toy
- **GitHub - zezba9000/WaylandClientWindow**: https://github.com/zezba9000/WaylandClientWindow
- **GitHub - willth7/wayland-client-example** (with input): https://github.com/willth7/wayland-client-example

### Zig @cImport Docs
- https://ziglang.org/documentation/master/#cImport

---

## What to Read (in order)

1. **Start here** — Orbit Dev "Hello Wayland" (5 min): explains connection basics
2. **Then** — Wayland Book XDG Shell example code (comprehensive example)
3. **Optional** — The Zig from-scratch blog post shows exactly what you want to do

---

## System Headers (already on your Arch)

```bash
# These exist on your system:
/usr/include/wayland-client.h

# Generate xdg-shell headers:
wayland-scanner client-header \
    /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
    /tmp/xdg-shell.h
```

---

## Quick Summary

| Step | What you do |
|------|-------------|
| 1 | Read "Hello Wayland" — understand `wl_display_connect` |
| 2 | Read Wayland Book example — see full picture |
| 3 | Generate xdg-shell headers |
| 4 | Write `connection.zig` — just connect + print success |

That's it — the first step is just getting a connection working. Once you confirm `wl_display_connect(null)` returns a valid pointer on your Hyprland, you're done with step 1.

---

**Any specific question before you start?**

---

## User

if i write in zig, how zig communicate with wayland?

---

## Assistant (Plan · minimax-m2.5-free · 42.3s)

_Thinking:_

The user is asking a conceptual question about how Zig communicates with Wayland. They're in read-only mode (plan mode), so I should just explain the concept clearly without making any code changes.

This is a great question - understanding the communication mechanism is fundamental to everything else they'll do.

Great question! Here's how Zig talks to Wayland:

---

## Communication Path

```
Zig Code  →  @cImport  →  libwayland-client.so  →  Unix Socket  →  Hyprland
```

### The Chain

```
┌─────────────────────────────────────────────────────────────────┐
│  Your Zig Code                                                  │
│                                                                 │
│  const wl = @cImport(@cInclude("wayland-client.h"));          │
│  const display = wl.wl_display_connect(null);                   │
└────────────────────────┬────────────────────────────────────────┘
                       │
                       ▼ (calls C function)
┌─────────────────────────────────────────────────────────────────┐
│  libwayland-client.so (system C library)                       │
│                                                                 │
│  wl_display_connect() {                                         │
│      open("/run/user/1000/wayland-0", O_RDWR)  // Unix socket │
│      return display pointer                                     │
│  }                                                              │
└────────────────────────┬────────────────────────────────────────┘
                       │
                       ▼ (sends/receives binary messages)
┌─────────────────────────────────────────────────────────────────┐
│  Unix Domain Socket                                             │
│                                                                 │
│  /run/user/1000/wayland-0  (the compositor's socket)         │
└────────────────────────┬────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hyprland (Wayland Compositor)                                 │
│                                                                 │
│  Listens on socket, receives messages, creates windows, etc.    │
└─────────────────────────────────────────────────────────────────┘
```

---

## What `@cImport` Does

```zig
// This tells Zig: "include these C headers and give me access to them"
const wl = @cImport(@cInclude("wayland-client.h"));

// Now you can call C functions directly from Zig:
const display = wl.wl_display_connect(null);
//            ↑                      ↑
//            |                      |
//            C function name        pass NULL to connect to default display
```

The C functions live in `libwayland-client.so` on your system. Zig links to that library at runtime and calls those functions.

---

## What Happens When You Call a Function

```zig
const display = wl.wl_display_connect(null);
```

This actually:
1. Opens the Wayland socket (e.g., `/run/user/1000/wayland-0`)
2. Sends a "hello" message to the compositor (Hyprland)
3. Returns a pointer to a `wl_display` struct (C's way of returning an object)

---

## Key Concept: Wayland Objects Are Just IDs

In Wayland, everything is an object identified by a number:

| Object | ID | What it is |
|--------|----|------------|
| `wl_display` | 0 (implicit) | The connection itself |
| `wl_registry` | 1 | Lists available interfaces |
| `wl_compositor` | X | Creates surfaces |
| `wl_surface` | Y | The drawing area |
| `xdg_toplevel` | Z | The window |

You don't create these objects directly — you send messages to the compositor asking it to create them, and it assigns IDs.

---

## The Message Flow (Simplified)

```
Zig: "Hey compositor, create me a surface!"
      ──────────────────────────────────→  [Hyprland allocates ID 5]
                                          [Creates surface internally]
                                          [Sends back "surface created"]

Zig: "Hey surface, here is my pixel data!"
      ──────────────────────────────────→  [Hyprland copies to screen]

Zig: "Any events happen?"
      ← ─────────────────────────────────  [Hyprland: "user pressed a key"]
```

---

## Summary

| Layer | What it does |
|-------|--------------|
| **Zig** | Your code calls functions |
| **`@cImport`** | Makes C functions available in Zig |
| **libwayland-client.so** | Implements the protocol in C |
| **Unix socket** | Sends binary messages to compositor |
| **Hyprland** | Receives messages, manages windows/screens |

You don't need to understand the socket protocol — `libwayland-client` handles that for you. You just call functions.

---

**Does this make sense? Ready to start with step 1?**

---

## User

how to not use `@cImport`? is it still working?

---

## Assistant (Plan · minimax-m2.5-free · 52.5s)

_Thinking:_

The user is asking about how to use Wayland without `@cImport`. They want to know the alternative approaches and whether they work.

Let me explain the alternatives to using `@cImport`:

1. **Write extern declarations manually** - declare the C functions yourself in Zig
2. **Use the raw socket protocol** - talk directly to Wayland without libwayland-client
3. **Use an existing Zig wrapper** - like zig-wayland which generates Zig bindings

Let me explain each approach clearly.

Good question! Here are the alternatives to `@cImport`:

---

## Option 1: Write `extern` Declarations Yourself

Instead of importing C headers, you declare the functions manually:

```zig
// Instead of @cImport, you write:
extern "c" fn wl_display_connect(name: ?[*:0]const u8) ?*WlDisplay;
extern "c" fn wl_display_disconnect(display: *WlDisplay) void;
extern "c" fn wl_display_roundtrip(display: *WlDisplay) c_int;

// Then use them directly:
const display = wl_display_connect(null);
```

**Pros:**
- No C header dependencies
- You control exactly what's exposed
- Cleaner Zig code (no C structs)

**Cons:**
- Must manually declare every function you use
- Must manually translate C structs to Zig

**Does it work?** Yes — it's just more manual work.

---

## Option 2: Use Generated Bindings (zig-wayland)

There's a tool called **wayland-scanner** that generates Zig code from the Wayland protocol XML files:

```bash
# Generate Zig bindings from protocol
wayland-scanner zig-code \
    /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml \
    xdg-shell.zig
```

This produces pure Zig code (no C):

```zig
// Generated output looks like pure Zig:
pub const XdgShell = opaque {};
pub const XdgSurface = opaque {};

pub extern fn xdg_wm_base_get_x basedg_surface(
   : *XdgWmBase,
    surface: *WlSurface,
) *XdgSurface;
```

**Projects that do this:**
- `ifreund/zig-wayland` (243 commits, very active)
- `allyourcodebase/wayland`

---

## Option 3: Raw Socket Protocol (No Library at All)

You can speak the Wayland protocol directly over the Unix socket without any library:

```zig
// Open the socket yourself
const socket = try std.net.connectUnixSocket("/run/user/1000/wayland-0");

// Send binary "hello" message (Wayland wire format)
// Receive and parse responses manually
```

**This is what the blog post you mentioned does.**

**Pros:**
- Zero dependencies
- Full understanding of the protocol

**Cons:**
- Extremely complex
- Need to understand wire format, message marshalling
- Not recommended for beginners

---

## Comparison

| Approach | Complexity | Dependencies | Recommended? |
|----------|------------|--------------|--------------|
| `@cImport` | Low | C headers | ✅ Yes, for learning |
| `extern` declarations | Medium | None | Good once you know what you need |
| zig-wayland (generated) | Low | zig-wayland package | ✅ Best for production |
| Raw socket | Very High | None | Only for deep learning |

---

## For Your Goal

Since you want to learn and build from scratch:

1. **Start with `@cImport`** — easiest, fastest to get working
2. **Later** → rewrite with `extern` declarations to understand the ABI
3. **Or** → use `zig-wayland` for cleaner code once you understand the protocol

The key insight: `@cImport` and `extern` achieve the same thing — both call C functions. `@cImport` just auto-generates the declarations from headers.

---

**My suggestion:** Start with `@cImport` (Approach A I gave earlier). It's not "wrong" — it's the standard way to use C libraries from Zig. Once you have a working window, you can always rewrite to use `extern` declarations later if you want.

Would you still prefer to avoid `@cImport` entirely?

---

