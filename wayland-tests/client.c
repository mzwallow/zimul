#include <stdio.h>
#include <wayland-client.h>

int main(int argc, char *argv[]) {
  // libwayland will:
  // 1. If $WAYLAND_DISPLAY is set, attempt to connect to
  //	$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY
  // 2. Otherwise, attempt to connect to $XDG_RUNTIME_DIR/wayland-0
  // 3. Otherwise, fail :(
  struct wl_display *display = wl_display_connect(NULL);
  if (!display) {
    fprintf(stderr, "Failed to connect to Wayland display.\n");
    return 1;
  }
  fprintf(stderr, "Connection established!\n");

  wl_display_disconnect(display);
  return 0;
}
