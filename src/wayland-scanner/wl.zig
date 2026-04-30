// Generated from the protocol XML file. DO NOT EDIT.

const std = @import("std");
const mem = std.mem;

const inner = @import("client.zig");
const common = @import("common.zig");

const Client = @This();

pub const Wl = struct {
    pub const Display = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn sync(display: *Display) !*Callback {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(display));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &Callback.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getRegistry(display: *Display) !*Registry {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(display));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Registry.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        const Listener = extern struct {
            @"error": ?*const fn (data: ?*anyopaque, display: *Display, object_id: ?*anyopaque, code: u32, message: [*:0]const u8) callconv(.c) void,
            deleteId: ?*const fn (data: ?*anyopaque, display: *Display, id: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                @"error": ?*const fn (data: *T, display: *Display, object_id: ?*anyopaque, code: u32, message: [*:0]const u8) void = null,
                deleteId: ?*const fn (data: *T, display: *Display, id: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .@"error" = if (handlers.@"error" != null) @"error" else null,
                    .deleteId = if (handlers.deleteId != null) deleteId else null,
                };

                fn @"error"(ptr: ?*anyopaque, display_: *Display, object_id_: ?*anyopaque, code_: u32, message_: [*:0]const u8) callconv(.c) void {
                    if (handlers.@"error") |h| {
                        h(@ptrCast(@alignCast(ptr)), display_, object_id_, code_, message_);
                    }
                }
                fn deleteId(ptr: ?*anyopaque, display_: *Display, id_: u32) callconv(.c) void {
                    if (handlers.deleteId) |h| {
                        h(@ptrCast(@alignCast(ptr)), display_, id_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_object = 0,
            invalid_method = 1,
            no_memory = 2,
            implementation = 3,
        };

        pub const interface: common.Interface = .{
            .name = "wl_display",
            .version = 1,
            .method_count = 2,
            .methods = &.{
                .{
                    .name = "sync",
                    .signature = "n",
                    .types = &.{
                        &Callback.interface,
                    },
                },
                .{
                    .name = "get_registry",
                    .signature = "n",
                    .types = &.{
                        &Registry.interface,
                    },
                },
            },
            .event_count = 2,
            .events = &.{
                .{
                    .name = "error",
                    .signature = "ous",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "delete_id",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Registry = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn bind(registry: *Registry, name: u32, comptime T: type) !*T {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(registry));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &T.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                name,
                T.interface.name,
                T.interface.version,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        const Listener = extern struct {
            global: ?*const fn (data: ?*anyopaque, registry: *Registry, name: u32, interface: [*:0]const u8, version: u32) callconv(.c) void,
            globalRemove: ?*const fn (data: ?*anyopaque, registry: *Registry, name: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                global: ?*const fn (data: *T, registry: *Registry, name: u32, interface: [*:0]const u8, version: u32) void = null,
                globalRemove: ?*const fn (data: *T, registry: *Registry, name: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .global = if (handlers.global != null) global else null,
                    .globalRemove = if (handlers.globalRemove != null) globalRemove else null,
                };

                fn global(ptr: ?*anyopaque, registry_: *Registry, name_: u32, interface_: [*:0]const u8, version_: u32) callconv(.c) void {
                    if (handlers.global) |h| {
                        h(@ptrCast(@alignCast(ptr)), registry_, name_, interface_, version_);
                    }
                }
                fn globalRemove(ptr: ?*anyopaque, registry_: *Registry, name_: u32) callconv(.c) void {
                    if (handlers.globalRemove) |h| {
                        h(@ptrCast(@alignCast(ptr)), registry_, name_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const interface: common.Interface = .{
            .name = "wl_registry",
            .version = 1,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "bind",
                    .signature = "usun",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
            },
            .event_count = 2,
            .events = &.{
                .{
                    .name = "global",
                    .signature = "usu",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "global_remove",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Callback = opaque {
        const Self = @This();

        const version: u32 = 1;

        const Listener = extern struct {
            done: ?*const fn (data: ?*anyopaque, callback: *Callback, callback_data: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                done: ?*const fn (data: *T, callback: *Callback, callback_data: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .done = if (handlers.done != null) done else null,
                };

                fn done(ptr: ?*anyopaque, callback_: *Callback, callback_data_: u32) callconv(.c) void {
                    if (handlers.done) |h| {
                        h(@ptrCast(@alignCast(ptr)), callback_, callback_data_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const interface: common.Interface = .{
            .name = "wl_callback",
            .version = 1,
            .method_count = 0,
            .methods = &.{},
            .event_count = 1,
            .events = &.{
                .{
                    .name = "done",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Compositor = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn createSurface(compositor: *Compositor) !*Surface {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(compositor));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &Surface.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn createRegion(compositor: *Compositor) !*Region {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(compositor));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Region.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn release(compositor: *Compositor) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(compositor));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub const interface: common.Interface = .{
            .name = "wl_compositor",
            .version = 7,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "create_surface",
                    .signature = "n",
                    .types = &.{
                        &Surface.interface,
                    },
                },
                .{
                    .name = "create_region",
                    .signature = "n",
                    .types = &.{
                        &Region.interface,
                    },
                },
                .{
                    .name = "release",
                    .signature = "7",
                    .types = &.{},
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const ShmPool = opaque {
        const Self = @This();

        const version: u32 = 2;

        pub fn createBuffer(shm_pool: *ShmPool, offset: i32, width: i32, height: i32, stride: i32, format: Shm.Format) !*Buffer {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shm_pool));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &Buffer.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                offset,
                width,
                height,
                stride,
                @intFromEnum(format),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn destroy(shm_pool: *ShmPool) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shm_pool));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn resize(shm_pool: *ShmPool, size: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shm_pool));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                size,
            );
        }

        pub const interface: common.Interface = .{
            .name = "wl_shm_pool",
            .version = 2,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "create_buffer",
                    .signature = "niiiiu",
                    .types = &.{
                        &Buffer.interface,
                        null,
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "resize",
                    .signature = "i",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Shm = opaque {
        const Self = @This();

        const version: u32 = 2;

        pub fn createPool(shm: *Shm, fd: std.os.linux.fd_t, size: i32) !*ShmPool {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shm));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &ShmPool.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                fd,
                size,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn release(shm: *Shm) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shm));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            format: ?*const fn (data: ?*anyopaque, shm: *Shm, format: Format) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                format: ?*const fn (data: *T, shm: *Shm, format: Format) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .format = if (handlers.format != null) format else null,
                };

                fn format(ptr: ?*anyopaque, shm_: *Shm, format_: Format) callconv(.c) void {
                    if (handlers.format) |h| {
                        h(@ptrCast(@alignCast(ptr)), shm_, format_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_format = 0,
            invalid_stride = 1,
            invalid_fd = 2,
        };

        pub const Format = enum(u32) {
            argb8888 = 0,
            xrgb8888 = 1,
            c8 = 538982467,
            rgb332 = 943867730,
            bgr233 = 944916290,
            xrgb4444 = 842093144,
            xbgr4444 = 842089048,
            rgbx4444 = 842094674,
            bgrx4444 = 842094658,
            argb4444 = 842093121,
            abgr4444 = 842089025,
            rgba4444 = 842088786,
            bgra4444 = 842088770,
            xrgb1555 = 892424792,
            xbgr1555 = 892420696,
            rgbx5551 = 892426322,
            bgrx5551 = 892426306,
            argb1555 = 892424769,
            abgr1555 = 892420673,
            rgba5551 = 892420434,
            bgra5551 = 892420418,
            rgb565 = 909199186,
            bgr565 = 909199170,
            rgb888 = 875710290,
            bgr888 = 875710274,
            xbgr8888 = 875709016,
            rgbx8888 = 875714642,
            bgrx8888 = 875714626,
            abgr8888 = 875708993,
            rgba8888 = 875708754,
            bgra8888 = 875708738,
            xrgb2101010 = 808669784,
            xbgr2101010 = 808665688,
            rgbx1010102 = 808671314,
            bgrx1010102 = 808671298,
            argb2101010 = 808669761,
            abgr2101010 = 808665665,
            rgba1010102 = 808665426,
            bgra1010102 = 808665410,
            yuyv = 1448695129,
            yvyu = 1431918169,
            uyvy = 1498831189,
            vyuy = 1498765654,
            ayuv = 1448433985,
            nv12 = 842094158,
            nv21 = 825382478,
            nv16 = 909203022,
            nv61 = 825644622,
            yuv410 = 961959257,
            yvu410 = 961893977,
            yuv411 = 825316697,
            yvu411 = 825316953,
            yuv420 = 842093913,
            yvu420 = 842094169,
            yuv422 = 909202777,
            yvu422 = 909203033,
            yuv444 = 875713881,
            yvu444 = 875714137,
            r8 = 538982482,
            r16 = 540422482,
            rg88 = 943212370,
            gr88 = 943215175,
            rg1616 = 842221394,
            gr1616 = 842224199,
            xrgb16161616f = 1211388504,
            xbgr16161616f = 1211384408,
            argb16161616f = 1211388481,
            abgr16161616f = 1211384385,
            xyuv8888 = 1448434008,
            vuy888 = 875713878,
            vuy101010 = 808670550,
            y210 = 808530521,
            y212 = 842084953,
            y216 = 909193817,
            y410 = 808531033,
            y412 = 842085465,
            y416 = 909194329,
            xvyu2101010 = 808670808,
            xvyu12_16161616 = 909334104,
            xvyu16161616 = 942954072,
            y0l0 = 810299481,
            x0l0 = 810299480,
            y0l2 = 843853913,
            x0l2 = 843853912,
            yuv420_8bit = 942691673,
            yuv420_10bit = 808539481,
            xrgb8888_a8 = 943805016,
            xbgr8888_a8 = 943800920,
            rgbx8888_a8 = 943806546,
            bgrx8888_a8 = 943806530,
            rgb888_a8 = 943798354,
            bgr888_a8 = 943798338,
            rgb565_a8 = 943797586,
            bgr565_a8 = 943797570,
            nv24 = 875714126,
            nv42 = 842290766,
            p210 = 808530512,
            p010 = 808530000,
            p012 = 842084432,
            p016 = 909193296,
            axbxgxrx106106106106 = 808534593,
            nv15 = 892425806,
            q410 = 808531025,
            q401 = 825242705,
            xrgb16161616 = 942953048,
            xbgr16161616 = 942948952,
            argb16161616 = 942953025,
            abgr16161616 = 942948929,
            c1 = 538980675,
            c2 = 538980931,
            c4 = 538981443,
            d1 = 538980676,
            d2 = 538980932,
            d4 = 538981444,
            d8 = 538982468,
            r1 = 538980690,
            r2 = 538980946,
            r4 = 538981458,
            r10 = 540029266,
            r12 = 540160338,
            avuy8888 = 1498764865,
            xvuy8888 = 1498764888,
            p030 = 808661072,
            rgb161616 = 942950226,
            bgr161616 = 942950210,
            r16f = 1210064978,
            gr1616f = 1210077767,
            bgr161616f = 1213351746,
            r32f = 1176510546,
            gr3232f = 1176523335,
            bgr323232f = 1179797314,
            abgr32323232f = 1178092097,
            nv20 = 808605262,
            nv30 = 808670798,
            s010 = 808530003,
            s210 = 808530515,
            s410 = 808531027,
            s012 = 842084435,
            s212 = 842084947,
            s412 = 842085459,
            s016 = 909193299,
            s216 = 909193811,
            s416 = 909194323,
        };

        pub const interface: common.Interface = .{
            .name = "wl_shm",
            .version = 2,
            .method_count = 2,
            .methods = &.{
                .{
                    .name = "create_pool",
                    .signature = "nhi",
                    .types = &.{
                        &ShmPool.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "release",
                    .signature = "2",
                    .types = &.{},
                },
            },
            .event_count = 1,
            .events = &.{
                .{
                    .name = "format",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Buffer = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn destroy(buffer: *Buffer) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(buffer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            release: ?*const fn (data: ?*anyopaque, buffer: *Buffer) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                release: ?*const fn (data: *T, buffer: *Buffer) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .release = if (handlers.release != null) release else null,
                };

                fn release(ptr: ?*anyopaque, buffer_: *Buffer) callconv(.c) void {
                    if (handlers.release) |h| {
                        h(@ptrCast(@alignCast(ptr)), buffer_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const interface: common.Interface = .{
            .name = "wl_buffer",
            .version = 1,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
            },
            .event_count = 1,
            .events = &.{
                .{
                    .name = "release",
                    .signature = "",
                    .types = &.{},
                },
            },
        };
    }; // Interface

    pub const DataOffer = opaque {
        const Self = @This();

        const version: u32 = 4;

        pub fn accept(data_offer: *DataOffer, serial: u32, mime_type: ?[*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_offer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
                mime_type,
            );
        }

        pub fn receive(data_offer: *DataOffer, mime_type: [*:0]const u8, fd: std.os.linux.fd_t) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_offer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                mime_type,
                fd,
            );
        }

        pub fn destroy(data_offer: *DataOffer) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_offer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn finish(data_offer: *DataOffer) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_offer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setActions(data_offer: *DataOffer, dnd_actions: DataDeviceManager.DndAction, preferred_action: DataDeviceManager.DndAction) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_offer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(dnd_actions),
                @intFromEnum(preferred_action),
            );
        }

        const Listener = extern struct {
            offer: ?*const fn (data: ?*anyopaque, data_offer: *DataOffer, mime_type: [*:0]const u8) callconv(.c) void,
            sourceActions: ?*const fn (data: ?*anyopaque, data_offer: *DataOffer, source_actions: DataDeviceManager.DndAction) callconv(.c) void,
            action: ?*const fn (data: ?*anyopaque, data_offer: *DataOffer, dnd_action: DataDeviceManager.DndAction) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                offer: ?*const fn (data: *T, data_offer: *DataOffer, mime_type: [*:0]const u8) void = null,
                sourceActions: ?*const fn (data: *T, data_offer: *DataOffer, source_actions: DataDeviceManager.DndAction) void = null,
                action: ?*const fn (data: *T, data_offer: *DataOffer, dnd_action: DataDeviceManager.DndAction) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .offer = if (handlers.offer != null) offer else null,
                    .sourceActions = if (handlers.sourceActions != null) sourceActions else null,
                    .action = if (handlers.action != null) action else null,
                };

                fn offer(ptr: ?*anyopaque, data_offer_: *DataOffer, mime_type_: [*:0]const u8) callconv(.c) void {
                    if (handlers.offer) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_offer_, mime_type_);
                    }
                }
                fn sourceActions(ptr: ?*anyopaque, data_offer_: *DataOffer, source_actions_: DataDeviceManager.DndAction) callconv(.c) void {
                    if (handlers.sourceActions) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_offer_, source_actions_);
                    }
                }
                fn action(ptr: ?*anyopaque, data_offer_: *DataOffer, dnd_action_: DataDeviceManager.DndAction) callconv(.c) void {
                    if (handlers.action) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_offer_, dnd_action_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_finish = 0,
            invalid_action_mask = 1,
            invalid_action = 2,
            invalid_offer = 3,
        };

        pub const interface: common.Interface = .{
            .name = "wl_data_offer",
            .version = 4,
            .method_count = 5,
            .methods = &.{
                .{
                    .name = "accept",
                    .signature = "u?s",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "receive",
                    .signature = "sh",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "finish",
                    .signature = "3",
                    .types = &.{},
                },
                .{
                    .name = "set_actions",
                    .signature = "3uu",
                    .types = &.{
                        null,
                        null,
                    },
                },
            },
            .event_count = 3,
            .events = &.{
                .{
                    .name = "offer",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "source_actions",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "action",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const DataSource = opaque {
        const Self = @This();

        const version: u32 = 4;

        pub fn offer(data_source: *DataSource, mime_type: [*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_source));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                mime_type,
            );
        }

        pub fn destroy(data_source: *DataSource) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_source));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setActions(data_source: *DataSource, dnd_actions: DataDeviceManager.DndAction) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_source));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(dnd_actions),
            );
        }

        const Listener = extern struct {
            target: ?*const fn (data: ?*anyopaque, data_source: *DataSource, mime_type: ?[*:0]const u8) callconv(.c) void,
            send: ?*const fn (data: ?*anyopaque, data_source: *DataSource, mime_type: [*:0]const u8, fd: std.os.linux.fd_t) callconv(.c) void,
            cancelled: ?*const fn (data: ?*anyopaque, data_source: *DataSource) callconv(.c) void,
            dndDropPerformed: ?*const fn (data: ?*anyopaque, data_source: *DataSource) callconv(.c) void,
            dndFinished: ?*const fn (data: ?*anyopaque, data_source: *DataSource) callconv(.c) void,
            action: ?*const fn (data: ?*anyopaque, data_source: *DataSource, dnd_action: DataDeviceManager.DndAction) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                target: ?*const fn (data: *T, data_source: *DataSource, mime_type: ?[*:0]const u8) void = null,
                send: ?*const fn (data: *T, data_source: *DataSource, mime_type: [*:0]const u8, fd: std.os.linux.fd_t) void = null,
                cancelled: ?*const fn (data: *T, data_source: *DataSource) void = null,
                dndDropPerformed: ?*const fn (data: *T, data_source: *DataSource) void = null,
                dndFinished: ?*const fn (data: *T, data_source: *DataSource) void = null,
                action: ?*const fn (data: *T, data_source: *DataSource, dnd_action: DataDeviceManager.DndAction) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .target = if (handlers.target != null) target else null,
                    .send = if (handlers.send != null) send else null,
                    .cancelled = if (handlers.cancelled != null) cancelled else null,
                    .dndDropPerformed = if (handlers.dndDropPerformed != null) dndDropPerformed else null,
                    .dndFinished = if (handlers.dndFinished != null) dndFinished else null,
                    .action = if (handlers.action != null) action else null,
                };

                fn target(ptr: ?*anyopaque, data_source_: *DataSource, mime_type_: ?[*:0]const u8) callconv(.c) void {
                    if (handlers.target) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_, mime_type_);
                    }
                }
                fn send(ptr: ?*anyopaque, data_source_: *DataSource, mime_type_: [*:0]const u8, fd_: std.os.linux.fd_t) callconv(.c) void {
                    if (handlers.send) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_, mime_type_, fd_);
                    }
                }
                fn cancelled(ptr: ?*anyopaque, data_source_: *DataSource) callconv(.c) void {
                    if (handlers.cancelled) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_);
                    }
                }
                fn dndDropPerformed(ptr: ?*anyopaque, data_source_: *DataSource) callconv(.c) void {
                    if (handlers.dndDropPerformed) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_);
                    }
                }
                fn dndFinished(ptr: ?*anyopaque, data_source_: *DataSource) callconv(.c) void {
                    if (handlers.dndFinished) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_);
                    }
                }
                fn action(ptr: ?*anyopaque, data_source_: *DataSource, dnd_action_: DataDeviceManager.DndAction) callconv(.c) void {
                    if (handlers.action) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_source_, dnd_action_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_action_mask = 0,
            invalid_source = 1,
        };

        pub const interface: common.Interface = .{
            .name = "wl_data_source",
            .version = 4,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "offer",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_actions",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 6,
            .events = &.{
                .{
                    .name = "target",
                    .signature = "?s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "send",
                    .signature = "sh",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "cancelled",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "dnd_drop_performed",
                    .signature = "3",
                    .types = &.{},
                },
                .{
                    .name = "dnd_finished",
                    .signature = "3",
                    .types = &.{},
                },
                .{
                    .name = "action",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const DataDevice = opaque {
        const Self = @This();

        const version: u32 = 4;

        pub fn startDrag(data_device: *DataDevice, source: ?*const DataSource, origin: *const Surface, icon: ?*const Surface, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                source,
                origin,
                icon,
                serial,
            );
        }

        pub fn setSelection(data_device: *DataDevice, source: ?*const DataSource, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                source,
                serial,
            );
        }

        pub fn release(data_device: *DataDevice) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            dataOffer: ?*const fn (data: ?*anyopaque, data_device: *DataDevice) callconv(.c) void,
            enter: ?*const fn (data: ?*anyopaque, data_device: *DataDevice, serial: u32, surface: *const Surface, x: common.Fixed, y: common.Fixed, id: ?*const DataOffer) callconv(.c) void,
            leave: ?*const fn (data: ?*anyopaque, data_device: *DataDevice) callconv(.c) void,
            motion: ?*const fn (data: ?*anyopaque, data_device: *DataDevice, time: u32, x: common.Fixed, y: common.Fixed) callconv(.c) void,
            drop: ?*const fn (data: ?*anyopaque, data_device: *DataDevice) callconv(.c) void,
            selection: ?*const fn (data: ?*anyopaque, data_device: *DataDevice, id: ?*const DataOffer) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                dataOffer: ?*const fn (data: *T, data_device: *DataDevice) void = null,
                enter: ?*const fn (data: *T, data_device: *DataDevice, serial: u32, surface: *const Surface, x: common.Fixed, y: common.Fixed, id: ?*const DataOffer) void = null,
                leave: ?*const fn (data: *T, data_device: *DataDevice) void = null,
                motion: ?*const fn (data: *T, data_device: *DataDevice, time: u32, x: common.Fixed, y: common.Fixed) void = null,
                drop: ?*const fn (data: *T, data_device: *DataDevice) void = null,
                selection: ?*const fn (data: *T, data_device: *DataDevice, id: ?*const DataOffer) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .dataOffer = if (handlers.dataOffer != null) dataOffer else null,
                    .enter = if (handlers.enter != null) enter else null,
                    .leave = if (handlers.leave != null) leave else null,
                    .motion = if (handlers.motion != null) motion else null,
                    .drop = if (handlers.drop != null) drop else null,
                    .selection = if (handlers.selection != null) selection else null,
                };

                fn dataOffer(ptr: ?*anyopaque, data_device_: *DataDevice) callconv(.c) void {
                    if (handlers.dataOffer) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_);
                    }
                }
                fn enter(ptr: ?*anyopaque, data_device_: *DataDevice, serial_: u32, surface_: *const Surface, x_: common.Fixed, y_: common.Fixed, id_: ?*const DataOffer) callconv(.c) void {
                    if (handlers.enter) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_, serial_, surface_, x_, y_, id_);
                    }
                }
                fn leave(ptr: ?*anyopaque, data_device_: *DataDevice) callconv(.c) void {
                    if (handlers.leave) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_);
                    }
                }
                fn motion(ptr: ?*anyopaque, data_device_: *DataDevice, time_: u32, x_: common.Fixed, y_: common.Fixed) callconv(.c) void {
                    if (handlers.motion) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_, time_, x_, y_);
                    }
                }
                fn drop(ptr: ?*anyopaque, data_device_: *DataDevice) callconv(.c) void {
                    if (handlers.drop) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_);
                    }
                }
                fn selection(ptr: ?*anyopaque, data_device_: *DataDevice, id_: ?*const DataOffer) callconv(.c) void {
                    if (handlers.selection) |h| {
                        h(@ptrCast(@alignCast(ptr)), data_device_, id_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            role = 0,
            used_source = 1,
        };

        pub const interface: common.Interface = .{
            .name = "wl_data_device",
            .version = 4,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "start_drag",
                    .signature = "?oo?ou",
                    .types = &.{
                        &DataSource.interface,
                        &Surface.interface,
                        &Surface.interface,
                        null,
                    },
                },
                .{
                    .name = "set_selection",
                    .signature = "?ou",
                    .types = &.{
                        &DataSource.interface,
                        null,
                    },
                },
                .{
                    .name = "release",
                    .signature = "2",
                    .types = &.{},
                },
            },
            .event_count = 6,
            .events = &.{
                .{
                    .name = "data_offer",
                    .signature = "n",
                    .types = &.{
                        &DataOffer.interface,
                    },
                },
                .{
                    .name = "enter",
                    .signature = "uoff?o",
                    .types = &.{
                        null,
                        &Surface.interface,
                        null,
                        null,
                        &DataOffer.interface,
                    },
                },
                .{
                    .name = "leave",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "motion",
                    .signature = "uff",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "drop",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "selection",
                    .signature = "?o",
                    .types = &.{
                        &DataOffer.interface,
                    },
                },
            },
        };
    }; // Interface

    pub const DataDeviceManager = opaque {
        const Self = @This();

        const version: u32 = 4;

        pub fn createDataSource(data_device_manager: *DataDeviceManager) !*DataSource {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device_manager));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &DataSource.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getDataDevice(data_device_manager: *DataDeviceManager, seat: *const Seat) !*DataDevice {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device_manager));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &DataDevice.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                seat,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn release(data_device_manager: *DataDeviceManager) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(data_device_manager));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub const DndAction = enum(u32) {
            none = 0,
            copy = 1,
            move = 2,
            ask = 4,

            pub fn contains(self: DndAction, other: DndAction) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: DndAction, other: DndAction) DndAction {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const interface: common.Interface = .{
            .name = "wl_data_device_manager",
            .version = 4,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "create_data_source",
                    .signature = "n",
                    .types = &.{
                        &DataSource.interface,
                    },
                },
                .{
                    .name = "get_data_device",
                    .signature = "no",
                    .types = &.{
                        &DataDevice.interface,
                        &Seat.interface,
                    },
                },
                .{
                    .name = "release",
                    .signature = "4",
                    .types = &.{},
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Shell = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn getShellSurface(shell: *Shell, surface: *const Surface) !*ShellSurface {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &ShellSurface.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                surface,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            role = 0,
        };

        pub const interface: common.Interface = .{
            .name = "wl_shell",
            .version = 1,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "get_shell_surface",
                    .signature = "no",
                    .types = &.{
                        &ShellSurface.interface,
                        &Surface.interface,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const ShellSurface = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn pong(shell_surface: *ShellSurface, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
            );
        }

        pub fn move(shell_surface: *ShellSurface, seat: *const Seat, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
            );
        }

        pub fn resize(shell_surface: *ShellSurface, seat: *const Seat, serial: u32, edges: Resize) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
                @intFromEnum(edges),
            );
        }

        pub fn setToplevel(shell_surface: *ShellSurface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setTransient(shell_surface: *ShellSurface, parent: *const Surface, x: i32, y: i32, flags: Transient) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                parent,
                x,
                y,
                @intFromEnum(flags),
            );
        }

        pub fn setFullscreen(shell_surface: *ShellSurface, method: FullscreenMethod, framerate: u32, output: ?*const Output) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                5,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(method),
                framerate,
                output,
            );
        }

        pub fn setPopup(shell_surface: *ShellSurface, seat: *const Seat, serial: u32, parent: *const Surface, x: i32, y: i32, flags: Transient) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                6,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
                parent,
                x,
                y,
                @intFromEnum(flags),
            );
        }

        pub fn setMaximized(shell_surface: *ShellSurface, output: ?*const Output) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                7,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                output,
            );
        }

        pub fn setTitle(shell_surface: *ShellSurface, title: [*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                8,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                title,
            );
        }

        pub fn setClass(shell_surface: *ShellSurface, class_: [*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(shell_surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                9,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                class_,
            );
        }

        const Listener = extern struct {
            ping: ?*const fn (data: ?*anyopaque, shell_surface: *ShellSurface, serial: u32) callconv(.c) void,
            configure: ?*const fn (data: ?*anyopaque, shell_surface: *ShellSurface, edges: Resize, width: i32, height: i32) callconv(.c) void,
            popupDone: ?*const fn (data: ?*anyopaque, shell_surface: *ShellSurface) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                ping: ?*const fn (data: *T, shell_surface: *ShellSurface, serial: u32) void = null,
                configure: ?*const fn (data: *T, shell_surface: *ShellSurface, edges: Resize, width: i32, height: i32) void = null,
                popupDone: ?*const fn (data: *T, shell_surface: *ShellSurface) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .ping = if (handlers.ping != null) ping else null,
                    .configure = if (handlers.configure != null) configure else null,
                    .popupDone = if (handlers.popupDone != null) popupDone else null,
                };

                fn ping(ptr: ?*anyopaque, shell_surface_: *ShellSurface, serial_: u32) callconv(.c) void {
                    if (handlers.ping) |h| {
                        h(@ptrCast(@alignCast(ptr)), shell_surface_, serial_);
                    }
                }
                fn configure(ptr: ?*anyopaque, shell_surface_: *ShellSurface, edges_: Resize, width_: i32, height_: i32) callconv(.c) void {
                    if (handlers.configure) |h| {
                        h(@ptrCast(@alignCast(ptr)), shell_surface_, edges_, width_, height_);
                    }
                }
                fn popupDone(ptr: ?*anyopaque, shell_surface_: *ShellSurface) callconv(.c) void {
                    if (handlers.popupDone) |h| {
                        h(@ptrCast(@alignCast(ptr)), shell_surface_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Resize = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 4,
            top_left = 5,
            bottom_left = 6,
            right = 8,
            top_right = 9,
            bottom_right = 10,

            pub fn contains(self: Resize, other: Resize) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: Resize, other: Resize) Resize {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const Transient = enum(u32) {
            inactive = 1,

            pub fn contains(self: Transient, other: Transient) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: Transient, other: Transient) Transient {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const FullscreenMethod = enum(u32) {
            default = 0,
            scale = 1,
            driver = 2,
            fill = 3,
        };

        pub const interface: common.Interface = .{
            .name = "wl_shell_surface",
            .version = 1,
            .method_count = 10,
            .methods = &.{
                .{
                    .name = "pong",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "move",
                    .signature = "ou",
                    .types = &.{
                        &Seat.interface,
                        null,
                    },
                },
                .{
                    .name = "resize",
                    .signature = "ouu",
                    .types = &.{
                        &Seat.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_toplevel",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_transient",
                    .signature = "oiiu",
                    .types = &.{
                        &Surface.interface,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_fullscreen",
                    .signature = "uu?o",
                    .types = &.{
                        null,
                        null,
                        &Output.interface,
                    },
                },
                .{
                    .name = "set_popup",
                    .signature = "ouoiiu",
                    .types = &.{
                        &Seat.interface,
                        null,
                        &Surface.interface,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_maximized",
                    .signature = "?o",
                    .types = &.{
                        &Output.interface,
                    },
                },
                .{
                    .name = "set_title",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_class",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 3,
            .events = &.{
                .{
                    .name = "ping",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "configure",
                    .signature = "uii",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "popup_done",
                    .signature = "",
                    .types = &.{},
                },
            },
        };
    }; // Interface

    pub const Surface = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(surface: *Surface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn attach(surface: *Surface, buffer: ?*const Buffer, x: i32, y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                buffer,
                x,
                y,
            );
        }

        pub fn damage(surface: *Surface, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub fn frame(surface: *Surface) !*Callback {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                &Callback.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn setOpaqueRegion(surface: *Surface, region: ?*const Region) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                region,
            );
        }

        pub fn setInputRegion(surface: *Surface, region: ?*const Region) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                5,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                region,
            );
        }

        pub fn commit(surface: *Surface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                6,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setBufferTransform(surface: *Surface, transform: Output.Transform) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                7,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(transform),
            );
        }

        pub fn setBufferScale(surface: *Surface, scale: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                8,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                scale,
            );
        }

        pub fn damageBuffer(surface: *Surface, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                9,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub fn offset(surface: *Surface, x: i32, y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                10,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
            );
        }

        pub fn getRelease(surface: *Surface) !*Callback {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                11,
                &Callback.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        const Listener = extern struct {
            enter: ?*const fn (data: ?*anyopaque, surface: *Surface, output: *const Output) callconv(.c) void,
            leave: ?*const fn (data: ?*anyopaque, surface: *Surface, output: *const Output) callconv(.c) void,
            preferredBufferScale: ?*const fn (data: ?*anyopaque, surface: *Surface, factor: i32) callconv(.c) void,
            preferredBufferTransform: ?*const fn (data: ?*anyopaque, surface: *Surface, transform: Output.Transform) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                enter: ?*const fn (data: *T, surface: *Surface, output: *const Output) void = null,
                leave: ?*const fn (data: *T, surface: *Surface, output: *const Output) void = null,
                preferredBufferScale: ?*const fn (data: *T, surface: *Surface, factor: i32) void = null,
                preferredBufferTransform: ?*const fn (data: *T, surface: *Surface, transform: Output.Transform) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .enter = if (handlers.enter != null) enter else null,
                    .leave = if (handlers.leave != null) leave else null,
                    .preferredBufferScale = if (handlers.preferredBufferScale != null) preferredBufferScale else null,
                    .preferredBufferTransform = if (handlers.preferredBufferTransform != null) preferredBufferTransform else null,
                };

                fn enter(ptr: ?*anyopaque, surface_: *Surface, output_: *const Output) callconv(.c) void {
                    if (handlers.enter) |h| {
                        h(@ptrCast(@alignCast(ptr)), surface_, output_);
                    }
                }
                fn leave(ptr: ?*anyopaque, surface_: *Surface, output_: *const Output) callconv(.c) void {
                    if (handlers.leave) |h| {
                        h(@ptrCast(@alignCast(ptr)), surface_, output_);
                    }
                }
                fn preferredBufferScale(ptr: ?*anyopaque, surface_: *Surface, factor_: i32) callconv(.c) void {
                    if (handlers.preferredBufferScale) |h| {
                        h(@ptrCast(@alignCast(ptr)), surface_, factor_);
                    }
                }
                fn preferredBufferTransform(ptr: ?*anyopaque, surface_: *Surface, transform_: Output.Transform) callconv(.c) void {
                    if (handlers.preferredBufferTransform) |h| {
                        h(@ptrCast(@alignCast(ptr)), surface_, transform_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_scale = 0,
            invalid_transform = 1,
            invalid_size = 2,
            invalid_offset = 3,
            defunct_role_object = 4,
            no_buffer = 5,
        };

        pub const interface: common.Interface = .{
            .name = "wl_surface",
            .version = 7,
            .method_count = 12,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "attach",
                    .signature = "?oii",
                    .types = &.{
                        &Buffer.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "damage",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "frame",
                    .signature = "n",
                    .types = &.{
                        &Callback.interface,
                    },
                },
                .{
                    .name = "set_opaque_region",
                    .signature = "?o",
                    .types = &.{
                        &Region.interface,
                    },
                },
                .{
                    .name = "set_input_region",
                    .signature = "?o",
                    .types = &.{
                        &Region.interface,
                    },
                },
                .{
                    .name = "commit",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_buffer_transform",
                    .signature = "2i",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_buffer_scale",
                    .signature = "3i",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "damage_buffer",
                    .signature = "4iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "offset",
                    .signature = "5ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "get_release",
                    .signature = "7n",
                    .types = &.{
                        &Callback.interface,
                    },
                },
            },
            .event_count = 4,
            .events = &.{
                .{
                    .name = "enter",
                    .signature = "o",
                    .types = &.{
                        &Output.interface,
                    },
                },
                .{
                    .name = "leave",
                    .signature = "o",
                    .types = &.{
                        &Output.interface,
                    },
                },
                .{
                    .name = "preferred_buffer_scale",
                    .signature = "6i",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "preferred_buffer_transform",
                    .signature = "6u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Seat = opaque {
        const Self = @This();

        const version: u32 = 10;

        pub fn getPointer(seat: *Seat) !*Pointer {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(seat));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                &Pointer.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getKeyboard(seat: *Seat) !*Keyboard {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(seat));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Keyboard.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getTouch(seat: *Seat) !*Touch {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(seat));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                &Touch.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn release(seat: *Seat) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(seat));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            capabilities: ?*const fn (data: ?*anyopaque, seat: *Seat, capabilities: Capability) callconv(.c) void,
            name: ?*const fn (data: ?*anyopaque, seat: *Seat, name: [*:0]const u8) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                capabilities: ?*const fn (data: *T, seat: *Seat, capabilities: Capability) void = null,
                name: ?*const fn (data: *T, seat: *Seat, name: [*:0]const u8) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .capabilities = if (handlers.capabilities != null) capabilities else null,
                    .name = if (handlers.name != null) name else null,
                };

                fn capabilities(ptr: ?*anyopaque, seat_: *Seat, capabilities_: Capability) callconv(.c) void {
                    if (handlers.capabilities) |h| {
                        h(@ptrCast(@alignCast(ptr)), seat_, capabilities_);
                    }
                }
                fn name(ptr: ?*anyopaque, seat_: *Seat, name_: [*:0]const u8) callconv(.c) void {
                    if (handlers.name) |h| {
                        h(@ptrCast(@alignCast(ptr)), seat_, name_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Capability = enum(u32) {
            pointer = 1,
            keyboard = 2,
            touch = 4,

            pub fn contains(self: Capability, other: Capability) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: Capability, other: Capability) Capability {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const Error = enum(u32) {
            missing_capability = 0,
        };

        pub const interface: common.Interface = .{
            .name = "wl_seat",
            .version = 10,
            .method_count = 4,
            .methods = &.{
                .{
                    .name = "get_pointer",
                    .signature = "n",
                    .types = &.{
                        &Pointer.interface,
                    },
                },
                .{
                    .name = "get_keyboard",
                    .signature = "n",
                    .types = &.{
                        &Keyboard.interface,
                    },
                },
                .{
                    .name = "get_touch",
                    .signature = "n",
                    .types = &.{
                        &Touch.interface,
                    },
                },
                .{
                    .name = "release",
                    .signature = "5",
                    .types = &.{},
                },
            },
            .event_count = 2,
            .events = &.{
                .{
                    .name = "capabilities",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "name",
                    .signature = "2s",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Pointer = opaque {
        const Self = @This();

        const version: u32 = 10;

        pub fn setCursor(pointer: *Pointer, serial: u32, surface: ?*const Surface, hotspot_x: i32, hotspot_y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(pointer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
                surface,
                hotspot_x,
                hotspot_y,
            );
        }

        pub fn release(pointer: *Pointer) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(pointer));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            enter: ?*const fn (data: ?*anyopaque, pointer: *Pointer, serial: u32, surface: *const Surface, surface_x: common.Fixed, surface_y: common.Fixed) callconv(.c) void,
            leave: ?*const fn (data: ?*anyopaque, pointer: *Pointer, serial: u32, surface: *const Surface) callconv(.c) void,
            motion: ?*const fn (data: ?*anyopaque, pointer: *Pointer, time: u32, surface_x: common.Fixed, surface_y: common.Fixed) callconv(.c) void,
            button: ?*const fn (data: ?*anyopaque, pointer: *Pointer, serial: u32, time: u32, button: u32, state: ButtonState) callconv(.c) void,
            axis: ?*const fn (data: ?*anyopaque, pointer: *Pointer, time: u32, axis: Axis, value: common.Fixed) callconv(.c) void,
            frame: ?*const fn (data: ?*anyopaque, pointer: *Pointer) callconv(.c) void,
            axisSource: ?*const fn (data: ?*anyopaque, pointer: *Pointer, axis_source: AxisSource) callconv(.c) void,
            axisStop: ?*const fn (data: ?*anyopaque, pointer: *Pointer, time: u32, axis: Axis) callconv(.c) void,
            axisDiscrete: ?*const fn (data: ?*anyopaque, pointer: *Pointer, axis: Axis, discrete: i32) callconv(.c) void,
            axisValue120: ?*const fn (data: ?*anyopaque, pointer: *Pointer, axis: Axis, value120: i32) callconv(.c) void,
            axisRelativeDirection: ?*const fn (data: ?*anyopaque, pointer: *Pointer, axis: Axis, direction: AxisRelativeDirection) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                enter: ?*const fn (data: *T, pointer: *Pointer, serial: u32, surface: *const Surface, surface_x: common.Fixed, surface_y: common.Fixed) void = null,
                leave: ?*const fn (data: *T, pointer: *Pointer, serial: u32, surface: *const Surface) void = null,
                motion: ?*const fn (data: *T, pointer: *Pointer, time: u32, surface_x: common.Fixed, surface_y: common.Fixed) void = null,
                button: ?*const fn (data: *T, pointer: *Pointer, serial: u32, time: u32, button: u32, state: ButtonState) void = null,
                axis: ?*const fn (data: *T, pointer: *Pointer, time: u32, axis: Axis, value: common.Fixed) void = null,
                frame: ?*const fn (data: *T, pointer: *Pointer) void = null,
                axisSource: ?*const fn (data: *T, pointer: *Pointer, axis_source: AxisSource) void = null,
                axisStop: ?*const fn (data: *T, pointer: *Pointer, time: u32, axis: Axis) void = null,
                axisDiscrete: ?*const fn (data: *T, pointer: *Pointer, axis: Axis, discrete: i32) void = null,
                axisValue120: ?*const fn (data: *T, pointer: *Pointer, axis: Axis, value120: i32) void = null,
                axisRelativeDirection: ?*const fn (data: *T, pointer: *Pointer, axis: Axis, direction: AxisRelativeDirection) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .enter = if (handlers.enter != null) enter else null,
                    .leave = if (handlers.leave != null) leave else null,
                    .motion = if (handlers.motion != null) motion else null,
                    .button = if (handlers.button != null) button else null,
                    .axis = if (handlers.axis != null) axis else null,
                    .frame = if (handlers.frame != null) frame else null,
                    .axisSource = if (handlers.axisSource != null) axisSource else null,
                    .axisStop = if (handlers.axisStop != null) axisStop else null,
                    .axisDiscrete = if (handlers.axisDiscrete != null) axisDiscrete else null,
                    .axisValue120 = if (handlers.axisValue120 != null) axisValue120 else null,
                    .axisRelativeDirection = if (handlers.axisRelativeDirection != null) axisRelativeDirection else null,
                };

                fn enter(ptr: ?*anyopaque, pointer_: *Pointer, serial_: u32, surface_: *const Surface, surface_x_: common.Fixed, surface_y_: common.Fixed) callconv(.c) void {
                    if (handlers.enter) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, serial_, surface_, surface_x_, surface_y_);
                    }
                }
                fn leave(ptr: ?*anyopaque, pointer_: *Pointer, serial_: u32, surface_: *const Surface) callconv(.c) void {
                    if (handlers.leave) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, serial_, surface_);
                    }
                }
                fn motion(ptr: ?*anyopaque, pointer_: *Pointer, time_: u32, surface_x_: common.Fixed, surface_y_: common.Fixed) callconv(.c) void {
                    if (handlers.motion) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, time_, surface_x_, surface_y_);
                    }
                }
                fn button(ptr: ?*anyopaque, pointer_: *Pointer, serial_: u32, time_: u32, button_: u32, state_: ButtonState) callconv(.c) void {
                    if (handlers.button) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, serial_, time_, button_, state_);
                    }
                }
                fn axis(ptr: ?*anyopaque, pointer_: *Pointer, time_: u32, axis_: Axis, value_: common.Fixed) callconv(.c) void {
                    if (handlers.axis) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, time_, axis_, value_);
                    }
                }
                fn frame(ptr: ?*anyopaque, pointer_: *Pointer) callconv(.c) void {
                    if (handlers.frame) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_);
                    }
                }
                fn axisSource(ptr: ?*anyopaque, pointer_: *Pointer, axis_source_: AxisSource) callconv(.c) void {
                    if (handlers.axisSource) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, axis_source_);
                    }
                }
                fn axisStop(ptr: ?*anyopaque, pointer_: *Pointer, time_: u32, axis_: Axis) callconv(.c) void {
                    if (handlers.axisStop) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, time_, axis_);
                    }
                }
                fn axisDiscrete(ptr: ?*anyopaque, pointer_: *Pointer, axis_: Axis, discrete_: i32) callconv(.c) void {
                    if (handlers.axisDiscrete) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, axis_, discrete_);
                    }
                }
                fn axisValue120(ptr: ?*anyopaque, pointer_: *Pointer, axis_: Axis, value120_: i32) callconv(.c) void {
                    if (handlers.axisValue120) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, axis_, value120_);
                    }
                }
                fn axisRelativeDirection(ptr: ?*anyopaque, pointer_: *Pointer, axis_: Axis, direction_: AxisRelativeDirection) callconv(.c) void {
                    if (handlers.axisRelativeDirection) |h| {
                        h(@ptrCast(@alignCast(ptr)), pointer_, axis_, direction_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            role = 0,
        };

        pub const ButtonState = enum(u32) {
            released = 0,
            pressed = 1,
        };

        pub const Axis = enum(u32) {
            vertical_scroll = 0,
            horizontal_scroll = 1,
        };

        pub const AxisSource = enum(u32) {
            wheel = 0,
            finger = 1,
            continuous = 2,
            wheel_tilt = 3,
        };

        pub const AxisRelativeDirection = enum(u32) {
            identical = 0,
            inverted = 1,
        };

        pub const interface: common.Interface = .{
            .name = "wl_pointer",
            .version = 10,
            .method_count = 2,
            .methods = &.{
                .{
                    .name = "set_cursor",
                    .signature = "u?oii",
                    .types = &.{
                        null,
                        &Surface.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "release",
                    .signature = "3",
                    .types = &.{},
                },
            },
            .event_count = 11,
            .events = &.{
                .{
                    .name = "enter",
                    .signature = "uoff",
                    .types = &.{
                        null,
                        &Surface.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "leave",
                    .signature = "uo",
                    .types = &.{
                        null,
                        &Surface.interface,
                    },
                },
                .{
                    .name = "motion",
                    .signature = "uff",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "button",
                    .signature = "uuuu",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "axis",
                    .signature = "uuf",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "frame",
                    .signature = "5",
                    .types = &.{},
                },
                .{
                    .name = "axis_source",
                    .signature = "5u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "axis_stop",
                    .signature = "5uu",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "axis_discrete",
                    .signature = "5ui",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "axis_value120",
                    .signature = "8ui",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "axis_relative_direction",
                    .signature = "9uu",
                    .types = &.{
                        null,
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Keyboard = opaque {
        const Self = @This();

        const version: u32 = 10;

        pub fn release(keyboard: *Keyboard) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(keyboard));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            keymap: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, format: KeymapFormat, fd: std.os.linux.fd_t, size: u32) callconv(.c) void,
            enter: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, serial: u32, surface: *const Surface, keys: *common.Array) callconv(.c) void,
            leave: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, serial: u32, surface: *const Surface) callconv(.c) void,
            key: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, serial: u32, time: u32, key: u32, state: KeyState) callconv(.c) void,
            modifiers: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) callconv(.c) void,
            repeatInfo: ?*const fn (data: ?*anyopaque, keyboard: *Keyboard, rate: i32, delay: i32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                keymap: ?*const fn (data: *T, keyboard: *Keyboard, format: KeymapFormat, fd: std.os.linux.fd_t, size: u32) void = null,
                enter: ?*const fn (data: *T, keyboard: *Keyboard, serial: u32, surface: *const Surface, keys: *common.Array) void = null,
                leave: ?*const fn (data: *T, keyboard: *Keyboard, serial: u32, surface: *const Surface) void = null,
                key: ?*const fn (data: *T, keyboard: *Keyboard, serial: u32, time: u32, key: u32, state: KeyState) void = null,
                modifiers: ?*const fn (data: *T, keyboard: *Keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) void = null,
                repeatInfo: ?*const fn (data: *T, keyboard: *Keyboard, rate: i32, delay: i32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .keymap = if (handlers.keymap != null) keymap else null,
                    .enter = if (handlers.enter != null) enter else null,
                    .leave = if (handlers.leave != null) leave else null,
                    .key = if (handlers.key != null) key else null,
                    .modifiers = if (handlers.modifiers != null) modifiers else null,
                    .repeatInfo = if (handlers.repeatInfo != null) repeatInfo else null,
                };

                fn keymap(ptr: ?*anyopaque, keyboard_: *Keyboard, format_: KeymapFormat, fd_: std.os.linux.fd_t, size_: u32) callconv(.c) void {
                    if (handlers.keymap) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, format_, fd_, size_);
                    }
                }
                fn enter(ptr: ?*anyopaque, keyboard_: *Keyboard, serial_: u32, surface_: *const Surface, keys_: *common.Array) callconv(.c) void {
                    if (handlers.enter) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, serial_, surface_, keys_);
                    }
                }
                fn leave(ptr: ?*anyopaque, keyboard_: *Keyboard, serial_: u32, surface_: *const Surface) callconv(.c) void {
                    if (handlers.leave) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, serial_, surface_);
                    }
                }
                fn key(ptr: ?*anyopaque, keyboard_: *Keyboard, serial_: u32, time_: u32, key_: u32, state_: KeyState) callconv(.c) void {
                    if (handlers.key) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, serial_, time_, key_, state_);
                    }
                }
                fn modifiers(ptr: ?*anyopaque, keyboard_: *Keyboard, serial_: u32, mods_depressed_: u32, mods_latched_: u32, mods_locked_: u32, group_: u32) callconv(.c) void {
                    if (handlers.modifiers) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, serial_, mods_depressed_, mods_latched_, mods_locked_, group_);
                    }
                }
                fn repeatInfo(ptr: ?*anyopaque, keyboard_: *Keyboard, rate_: i32, delay_: i32) callconv(.c) void {
                    if (handlers.repeatInfo) |h| {
                        h(@ptrCast(@alignCast(ptr)), keyboard_, rate_, delay_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const KeymapFormat = enum(u32) {
            no_keymap = 0,
            xkb_v1 = 1,
        };

        pub const KeyState = enum(u32) {
            released = 0,
            pressed = 1,
            repeated = 2,
        };

        pub const interface: common.Interface = .{
            .name = "wl_keyboard",
            .version = 10,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "release",
                    .signature = "3",
                    .types = &.{},
                },
            },
            .event_count = 6,
            .events = &.{
                .{
                    .name = "keymap",
                    .signature = "uhu",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "enter",
                    .signature = "uoa",
                    .types = &.{
                        null,
                        &Surface.interface,
                        null,
                    },
                },
                .{
                    .name = "leave",
                    .signature = "uo",
                    .types = &.{
                        null,
                        &Surface.interface,
                    },
                },
                .{
                    .name = "key",
                    .signature = "uuuu",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "modifiers",
                    .signature = "uuuuu",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "repeat_info",
                    .signature = "4ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Touch = opaque {
        const Self = @This();

        const version: u32 = 10;

        pub fn release(touch: *Touch) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(touch));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            down: ?*const fn (data: ?*anyopaque, touch: *Touch, serial: u32, time: u32, surface: *const Surface, id: i32, x: common.Fixed, y: common.Fixed) callconv(.c) void,
            up: ?*const fn (data: ?*anyopaque, touch: *Touch, serial: u32, time: u32, id: i32) callconv(.c) void,
            motion: ?*const fn (data: ?*anyopaque, touch: *Touch, time: u32, id: i32, x: common.Fixed, y: common.Fixed) callconv(.c) void,
            frame: ?*const fn (data: ?*anyopaque, touch: *Touch) callconv(.c) void,
            cancel: ?*const fn (data: ?*anyopaque, touch: *Touch) callconv(.c) void,
            shape: ?*const fn (data: ?*anyopaque, touch: *Touch, id: i32, major: common.Fixed, minor: common.Fixed) callconv(.c) void,
            orientation: ?*const fn (data: ?*anyopaque, touch: *Touch, id: i32, orientation: common.Fixed) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                down: ?*const fn (data: *T, touch: *Touch, serial: u32, time: u32, surface: *const Surface, id: i32, x: common.Fixed, y: common.Fixed) void = null,
                up: ?*const fn (data: *T, touch: *Touch, serial: u32, time: u32, id: i32) void = null,
                motion: ?*const fn (data: *T, touch: *Touch, time: u32, id: i32, x: common.Fixed, y: common.Fixed) void = null,
                frame: ?*const fn (data: *T, touch: *Touch) void = null,
                cancel: ?*const fn (data: *T, touch: *Touch) void = null,
                shape: ?*const fn (data: *T, touch: *Touch, id: i32, major: common.Fixed, minor: common.Fixed) void = null,
                orientation: ?*const fn (data: *T, touch: *Touch, id: i32, orientation: common.Fixed) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .down = if (handlers.down != null) down else null,
                    .up = if (handlers.up != null) up else null,
                    .motion = if (handlers.motion != null) motion else null,
                    .frame = if (handlers.frame != null) frame else null,
                    .cancel = if (handlers.cancel != null) cancel else null,
                    .shape = if (handlers.shape != null) shape else null,
                    .orientation = if (handlers.orientation != null) orientation else null,
                };

                fn down(ptr: ?*anyopaque, touch_: *Touch, serial_: u32, time_: u32, surface_: *const Surface, id_: i32, x_: common.Fixed, y_: common.Fixed) callconv(.c) void {
                    if (handlers.down) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_, serial_, time_, surface_, id_, x_, y_);
                    }
                }
                fn up(ptr: ?*anyopaque, touch_: *Touch, serial_: u32, time_: u32, id_: i32) callconv(.c) void {
                    if (handlers.up) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_, serial_, time_, id_);
                    }
                }
                fn motion(ptr: ?*anyopaque, touch_: *Touch, time_: u32, id_: i32, x_: common.Fixed, y_: common.Fixed) callconv(.c) void {
                    if (handlers.motion) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_, time_, id_, x_, y_);
                    }
                }
                fn frame(ptr: ?*anyopaque, touch_: *Touch) callconv(.c) void {
                    if (handlers.frame) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_);
                    }
                }
                fn cancel(ptr: ?*anyopaque, touch_: *Touch) callconv(.c) void {
                    if (handlers.cancel) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_);
                    }
                }
                fn shape(ptr: ?*anyopaque, touch_: *Touch, id_: i32, major_: common.Fixed, minor_: common.Fixed) callconv(.c) void {
                    if (handlers.shape) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_, id_, major_, minor_);
                    }
                }
                fn orientation(ptr: ?*anyopaque, touch_: *Touch, id_: i32, orientation_: common.Fixed) callconv(.c) void {
                    if (handlers.orientation) |h| {
                        h(@ptrCast(@alignCast(ptr)), touch_, id_, orientation_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const interface: common.Interface = .{
            .name = "wl_touch",
            .version = 10,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "release",
                    .signature = "3",
                    .types = &.{},
                },
            },
            .event_count = 7,
            .events = &.{
                .{
                    .name = "down",
                    .signature = "uuoiff",
                    .types = &.{
                        null,
                        null,
                        &Surface.interface,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "up",
                    .signature = "uui",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "motion",
                    .signature = "uiff",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "frame",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "cancel",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "shape",
                    .signature = "6iff",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "orientation",
                    .signature = "6if",
                    .types = &.{
                        null,
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Output = opaque {
        const Self = @This();

        const version: u32 = 4;

        pub fn release(output: *Output) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(output));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            geometry: ?*const fn (data: ?*anyopaque, output: *Output, x: i32, y: i32, physical_width: i32, physical_height: i32, subpixel: Subpixel, make: [*:0]const u8, model: [*:0]const u8, transform: Transform) callconv(.c) void,
            mode: ?*const fn (data: ?*anyopaque, output: *Output, flags: Mode, width: i32, height: i32, refresh: i32) callconv(.c) void,
            done: ?*const fn (data: ?*anyopaque, output: *Output) callconv(.c) void,
            scale: ?*const fn (data: ?*anyopaque, output: *Output, factor: i32) callconv(.c) void,
            name: ?*const fn (data: ?*anyopaque, output: *Output, name: [*:0]const u8) callconv(.c) void,
            description: ?*const fn (data: ?*anyopaque, output: *Output, description: [*:0]const u8) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                geometry: ?*const fn (data: *T, output: *Output, x: i32, y: i32, physical_width: i32, physical_height: i32, subpixel: Subpixel, make: [*:0]const u8, model: [*:0]const u8, transform: Transform) void = null,
                mode: ?*const fn (data: *T, output: *Output, flags: Mode, width: i32, height: i32, refresh: i32) void = null,
                done: ?*const fn (data: *T, output: *Output) void = null,
                scale: ?*const fn (data: *T, output: *Output, factor: i32) void = null,
                name: ?*const fn (data: *T, output: *Output, name: [*:0]const u8) void = null,
                description: ?*const fn (data: *T, output: *Output, description: [*:0]const u8) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .geometry = if (handlers.geometry != null) geometry else null,
                    .mode = if (handlers.mode != null) mode else null,
                    .done = if (handlers.done != null) done else null,
                    .scale = if (handlers.scale != null) scale else null,
                    .name = if (handlers.name != null) name else null,
                    .description = if (handlers.description != null) description else null,
                };

                fn geometry(ptr: ?*anyopaque, output_: *Output, x_: i32, y_: i32, physical_width_: i32, physical_height_: i32, subpixel_: Subpixel, make_: [*:0]const u8, model_: [*:0]const u8, transform_: Transform) callconv(.c) void {
                    if (handlers.geometry) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_, x_, y_, physical_width_, physical_height_, subpixel_, make_, model_, transform_);
                    }
                }
                fn mode(ptr: ?*anyopaque, output_: *Output, flags_: Mode, width_: i32, height_: i32, refresh_: i32) callconv(.c) void {
                    if (handlers.mode) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_, flags_, width_, height_, refresh_);
                    }
                }
                fn done(ptr: ?*anyopaque, output_: *Output) callconv(.c) void {
                    if (handlers.done) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_);
                    }
                }
                fn scale(ptr: ?*anyopaque, output_: *Output, factor_: i32) callconv(.c) void {
                    if (handlers.scale) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_, factor_);
                    }
                }
                fn name(ptr: ?*anyopaque, output_: *Output, name_: [*:0]const u8) callconv(.c) void {
                    if (handlers.name) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_, name_);
                    }
                }
                fn description(ptr: ?*anyopaque, output_: *Output, description_: [*:0]const u8) callconv(.c) void {
                    if (handlers.description) |h| {
                        h(@ptrCast(@alignCast(ptr)), output_, description_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Subpixel = enum(u32) {
            unknown = 0,
            none = 1,
            horizontal_rgb = 2,
            horizontal_bgr = 3,
            vertical_rgb = 4,
            vertical_bgr = 5,
        };

        pub const Transform = enum(u32) {
            normal = 0,
            @"90" = 1,
            @"180" = 2,
            @"270" = 3,
            flipped = 4,
            flipped_90 = 5,
            flipped_180 = 6,
            flipped_270 = 7,
        };

        pub const Mode = enum(u32) {
            current = 1,
            preferred = 2,

            pub fn contains(self: Mode, other: Mode) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: Mode, other: Mode) Mode {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const interface: common.Interface = .{
            .name = "wl_output",
            .version = 4,
            .method_count = 1,
            .methods = &.{
                .{
                    .name = "release",
                    .signature = "3",
                    .types = &.{},
                },
            },
            .event_count = 6,
            .events = &.{
                .{
                    .name = "geometry",
                    .signature = "iiiiissi",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "mode",
                    .signature = "uiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "done",
                    .signature = "2",
                    .types = &.{},
                },
                .{
                    .name = "scale",
                    .signature = "2i",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "name",
                    .signature = "4s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "description",
                    .signature = "4s",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Region = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(region: *Region) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(region));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn add(region: *Region, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(region));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub fn subtract(region: *Region, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(region));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub const interface: common.Interface = .{
            .name = "wl_region",
            .version = 7,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "add",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "subtract",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Subcompositor = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn destroy(subcompositor: *Subcompositor) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subcompositor));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn getSubsurface(subcompositor: *Subcompositor, surface: *const Surface, parent: *const Surface) !*Subsurface {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subcompositor));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Subsurface.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                surface,
                parent,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            bad_surface = 0,
            bad_parent = 1,
        };

        pub const interface: common.Interface = .{
            .name = "wl_subcompositor",
            .version = 1,
            .method_count = 2,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "get_subsurface",
                    .signature = "noo",
                    .types = &.{
                        &Subsurface.interface,
                        &Surface.interface,
                        &Surface.interface,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Subsurface = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn destroy(subsurface: *Subsurface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setPosition(subsurface: *Subsurface, x: i32, y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
            );
        }

        pub fn placeAbove(subsurface: *Subsurface, sibling: *const Surface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                sibling,
            );
        }

        pub fn placeBelow(subsurface: *Subsurface, sibling: *const Surface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                sibling,
            );
        }

        pub fn setSync(subsurface: *Subsurface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setDesync(subsurface: *Subsurface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(subsurface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                5,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub const Error = enum(u32) {
            bad_surface = 0,
        };

        pub const interface: common.Interface = .{
            .name = "wl_subsurface",
            .version = 1,
            .method_count = 6,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_position",
                    .signature = "ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "place_above",
                    .signature = "o",
                    .types = &.{
                        &Surface.interface,
                    },
                },
                .{
                    .name = "place_below",
                    .signature = "o",
                    .types = &.{
                        &Surface.interface,
                    },
                },
                .{
                    .name = "set_sync",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_desync",
                    .signature = "",
                    .types = &.{},
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Fixes = opaque {
        const Self = @This();

        const version: u32 = 1;

        pub fn destroy(fixes: *Fixes) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(fixes));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn destroyRegistry(fixes: *Fixes, registry: *const Registry) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(fixes));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                registry,
            );
        }

        pub const interface: common.Interface = .{
            .name = "wl_fixes",
            .version = 1,
            .method_count = 2,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "destroy_registry",
                    .signature = "o",
                    .types = &.{
                        &Registry.interface,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

};

pub const Xdg = struct {
    pub const WmBase = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(wm_base: *WmBase) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(wm_base));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn createPositioner(wm_base: *WmBase) !*Positioner {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(wm_base));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Positioner.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getXdgSurface(wm_base: *WmBase, surface: *const Wl.Surface) !*Surface {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(wm_base));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                &Surface.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                surface,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn pong(wm_base: *WmBase, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(wm_base));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
            );
        }

        const Listener = extern struct {
            ping: ?*const fn (data: ?*anyopaque, wm_base: *WmBase, serial: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                ping: ?*const fn (data: *T, wm_base: *WmBase, serial: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .ping = if (handlers.ping != null) ping else null,
                };

                fn ping(ptr: ?*anyopaque, wm_base_: *WmBase, serial_: u32) callconv(.c) void {
                    if (handlers.ping) |h| {
                        h(@ptrCast(@alignCast(ptr)), wm_base_, serial_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            role = 0,
            defunct_surfaces = 1,
            not_the_topmost_popup = 2,
            invalid_popup_parent = 3,
            invalid_surface_state = 4,
            invalid_positioner = 5,
            unresponsive = 6,
        };

        pub const interface: common.Interface = .{
            .name = "xdg_wm_base",
            .version = 7,
            .method_count = 4,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "create_positioner",
                    .signature = "n",
                    .types = &.{
                        &Positioner.interface,
                    },
                },
                .{
                    .name = "get_xdg_surface",
                    .signature = "no",
                    .types = &.{
                        &Surface.interface,
                        &Wl.Surface.interface,
                    },
                },
                .{
                    .name = "pong",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 1,
            .events = &.{
                .{
                    .name = "ping",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Positioner = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(positioner: *Positioner) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setSize(positioner: *Positioner, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                width,
                height,
            );
        }

        pub fn setAnchorRect(positioner: *Positioner, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub fn setAnchor(positioner: *Positioner, anchor: Anchor) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(anchor),
            );
        }

        pub fn setGravity(positioner: *Positioner, gravity: Gravity) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(gravity),
            );
        }

        pub fn setConstraintAdjustment(positioner: *Positioner, constraint_adjustment: ConstraintAdjustment) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                5,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @intFromEnum(constraint_adjustment),
            );
        }

        pub fn setOffset(positioner: *Positioner, x: i32, y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                6,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
            );
        }

        pub fn setReactive(positioner: *Positioner) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                7,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setParentSize(positioner: *Positioner, parent_width: i32, parent_height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                8,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                parent_width,
                parent_height,
            );
        }

        pub fn setParentConfigure(positioner: *Positioner, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(positioner));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                9,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
            );
        }

        pub const Error = enum(u32) {
            invalid_input = 0,
        };

        pub const Anchor = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 3,
            right = 4,
            top_left = 5,
            bottom_left = 6,
            top_right = 7,
            bottom_right = 8,
        };

        pub const Gravity = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 3,
            right = 4,
            top_left = 5,
            bottom_left = 6,
            top_right = 7,
            bottom_right = 8,
        };

        pub const ConstraintAdjustment = enum(u32) {
            none = 0,
            slide_x = 1,
            slide_y = 2,
            flip_x = 4,
            flip_y = 8,
            resize_x = 16,
            resize_y = 32,

            pub fn contains(self: ConstraintAdjustment, other: ConstraintAdjustment) bool {
                return @intFromEnum(self) & @intFromEnum(other) != 0;
            }

            pub fn merge(self: ConstraintAdjustment, other: ConstraintAdjustment) ConstraintAdjustment {
                return @enumFromInt(@intFromEnum(self) | @intFromEnum(other));
            }
        };

        pub const interface: common.Interface = .{
            .name = "xdg_positioner",
            .version = 7,
            .method_count = 10,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_size",
                    .signature = "ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_anchor_rect",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_anchor",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_gravity",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_constraint_adjustment",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_offset",
                    .signature = "ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_reactive",
                    .signature = "3",
                    .types = &.{},
                },
                .{
                    .name = "set_parent_size",
                    .signature = "3ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_parent_configure",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 0,
            .events = &.{},
        };
    }; // Interface

    pub const Surface = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(surface: *Surface) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn getToplevel(surface: *Surface) !*Toplevel {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                &Toplevel.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn getPopup(surface: *Surface, parent: ?*const Surface, positioner: *const Positioner) !*Popup {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            const id = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                &Popup.interface,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                @as(?*anyopaque, null),
                parent,
                positioner,
            ) orelse return error.MarshalFailed;

            return @ptrCast(@alignCast(id));
        }

        pub fn setWindowGeometry(surface: *Surface, x: i32, y: i32, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                x,
                y,
                width,
                height,
            );
        }

        pub fn ackConfigure(surface: *Surface, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(surface));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                serial,
            );
        }

        const Listener = extern struct {
            configure: ?*const fn (data: ?*anyopaque, surface: *Surface, serial: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                configure: ?*const fn (data: *T, surface: *Surface, serial: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .configure = if (handlers.configure != null) configure else null,
                };

                fn configure(ptr: ?*anyopaque, surface_: *Surface, serial_: u32) callconv(.c) void {
                    if (handlers.configure) |h| {
                        h(@ptrCast(@alignCast(ptr)), surface_, serial_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            not_constructed = 1,
            already_constructed = 2,
            unconfigured_buffer = 3,
            invalid_serial = 4,
            invalid_size = 5,
            defunct_role_object = 6,
        };

        pub const interface: common.Interface = .{
            .name = "xdg_surface",
            .version = 7,
            .method_count = 5,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "get_toplevel",
                    .signature = "n",
                    .types = &.{
                        &Toplevel.interface,
                    },
                },
                .{
                    .name = "get_popup",
                    .signature = "n?oo",
                    .types = &.{
                        &Popup.interface,
                        &Surface.interface,
                        &Positioner.interface,
                    },
                },
                .{
                    .name = "set_window_geometry",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "ack_configure",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
            .event_count = 1,
            .events = &.{
                .{
                    .name = "configure",
                    .signature = "u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Toplevel = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(toplevel: *Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setParent(toplevel: *Toplevel, parent: ?*const Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                parent,
            );
        }

        pub fn setTitle(toplevel: *Toplevel, title: [*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                title,
            );
        }

        pub fn setAppId(toplevel: *Toplevel, app_id: [*:0]const u8) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                3,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                app_id,
            );
        }

        pub fn showWindowMenu(toplevel: *Toplevel, seat: *const Wl.Seat, serial: u32, x: i32, y: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                4,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
                x,
                y,
            );
        }

        pub fn move(toplevel: *Toplevel, seat: *const Wl.Seat, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                5,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
            );
        }

        pub fn resize(toplevel: *Toplevel, seat: *const Wl.Seat, serial: u32, edges: ResizeEdge) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                6,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
                @intFromEnum(edges),
            );
        }

        pub fn setMaxSize(toplevel: *Toplevel, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                7,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                width,
                height,
            );
        }

        pub fn setMinSize(toplevel: *Toplevel, width: i32, height: i32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                8,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                width,
                height,
            );
        }

        pub fn setMaximized(toplevel: *Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                9,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn unsetMaximized(toplevel: *Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                10,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setFullscreen(toplevel: *Toplevel, output: ?*const Wl.Output) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                11,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                output,
            );
        }

        pub fn unsetFullscreen(toplevel: *Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                12,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn setMinimized(toplevel: *Toplevel) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(toplevel));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                13,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        const Listener = extern struct {
            configure: ?*const fn (data: ?*anyopaque, toplevel: *Toplevel, width: i32, height: i32, states: *common.Array) callconv(.c) void,
            close: ?*const fn (data: ?*anyopaque, toplevel: *Toplevel) callconv(.c) void,
            configureBounds: ?*const fn (data: ?*anyopaque, toplevel: *Toplevel, width: i32, height: i32) callconv(.c) void,
            wmCapabilities: ?*const fn (data: ?*anyopaque, toplevel: *Toplevel, capabilities: *common.Array) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                configure: ?*const fn (data: *T, toplevel: *Toplevel, width: i32, height: i32, states: *common.Array) void = null,
                close: ?*const fn (data: *T, toplevel: *Toplevel) void = null,
                configureBounds: ?*const fn (data: *T, toplevel: *Toplevel, width: i32, height: i32) void = null,
                wmCapabilities: ?*const fn (data: *T, toplevel: *Toplevel, capabilities: *common.Array) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .configure = if (handlers.configure != null) configure else null,
                    .close = if (handlers.close != null) close else null,
                    .configureBounds = if (handlers.configureBounds != null) configureBounds else null,
                    .wmCapabilities = if (handlers.wmCapabilities != null) wmCapabilities else null,
                };

                fn configure(ptr: ?*anyopaque, toplevel_: *Toplevel, width_: i32, height_: i32, states_: *common.Array) callconv(.c) void {
                    if (handlers.configure) |h| {
                        h(@ptrCast(@alignCast(ptr)), toplevel_, width_, height_, states_);
                    }
                }
                fn close(ptr: ?*anyopaque, toplevel_: *Toplevel) callconv(.c) void {
                    if (handlers.close) |h| {
                        h(@ptrCast(@alignCast(ptr)), toplevel_);
                    }
                }
                fn configureBounds(ptr: ?*anyopaque, toplevel_: *Toplevel, width_: i32, height_: i32) callconv(.c) void {
                    if (handlers.configureBounds) |h| {
                        h(@ptrCast(@alignCast(ptr)), toplevel_, width_, height_);
                    }
                }
                fn wmCapabilities(ptr: ?*anyopaque, toplevel_: *Toplevel, capabilities_: *common.Array) callconv(.c) void {
                    if (handlers.wmCapabilities) |h| {
                        h(@ptrCast(@alignCast(ptr)), toplevel_, capabilities_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_resize_edge = 0,
            invalid_parent = 1,
            invalid_size = 2,
        };

        pub const ResizeEdge = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 4,
            top_left = 5,
            bottom_left = 6,
            right = 8,
            top_right = 9,
            bottom_right = 10,
        };

        pub const State = enum(u32) {
            maximized = 1,
            fullscreen = 2,
            resizing = 3,
            activated = 4,
            tiled_left = 5,
            tiled_right = 6,
            tiled_top = 7,
            tiled_bottom = 8,
            suspended = 9,
            constrained_left = 10,
            constrained_right = 11,
            constrained_top = 12,
            constrained_bottom = 13,
        };

        pub const WmCapabilities = enum(u32) {
            window_menu = 1,
            maximize = 2,
            fullscreen = 3,
            minimize = 4,
        };

        pub const interface: common.Interface = .{
            .name = "xdg_toplevel",
            .version = 7,
            .method_count = 14,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_parent",
                    .signature = "?o",
                    .types = &.{
                        &Toplevel.interface,
                    },
                },
                .{
                    .name = "set_title",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "set_app_id",
                    .signature = "s",
                    .types = &.{
                        null,
                    },
                },
                .{
                    .name = "show_window_menu",
                    .signature = "ouii",
                    .types = &.{
                        &Wl.Seat.interface,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "move",
                    .signature = "ou",
                    .types = &.{
                        &Wl.Seat.interface,
                        null,
                    },
                },
                .{
                    .name = "resize",
                    .signature = "ouu",
                    .types = &.{
                        &Wl.Seat.interface,
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_max_size",
                    .signature = "ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_min_size",
                    .signature = "ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "set_maximized",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "unset_maximized",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_fullscreen",
                    .signature = "?o",
                    .types = &.{
                        &Wl.Output.interface,
                    },
                },
                .{
                    .name = "unset_fullscreen",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "set_minimized",
                    .signature = "",
                    .types = &.{},
                },
            },
            .event_count = 4,
            .events = &.{
                .{
                    .name = "configure",
                    .signature = "iia",
                    .types = &.{
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "close",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "configure_bounds",
                    .signature = "4ii",
                    .types = &.{
                        null,
                        null,
                    },
                },
                .{
                    .name = "wm_capabilities",
                    .signature = "5a",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

    pub const Popup = opaque {
        const Self = @This();

        const version: u32 = 7;

        pub fn destroy(popup: *Popup) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(popup));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                0,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
            );
        }

        pub fn grab(popup: *Popup, seat: *const Wl.Seat, serial: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(popup));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                1,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                seat,
                serial,
            );
        }

        pub fn reposition(popup: *Popup, positioner: *const Positioner, token: u32) !void {
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(popup));
            _ = inner.wl_proxy.wl_proxy_marshal_flags(
                proxy,
                2,
                null,
                inner.wl_proxy.wl_proxy_get_version(proxy),
                0,
                positioner,
                token,
            );
        }

        const Listener = extern struct {
            configure: ?*const fn (data: ?*anyopaque, popup: *Popup, x: i32, y: i32, width: i32, height: i32) callconv(.c) void,
            popupDone: ?*const fn (data: ?*anyopaque, popup: *Popup) callconv(.c) void,
            repositioned: ?*const fn (data: ?*anyopaque, popup: *Popup, token: u32) callconv(.c) void,
        };

        pub fn addListener(
            self: *Self,
            comptime T: type,
            state: *T,
            comptime handlers: struct {
                configure: ?*const fn (data: *T, popup: *Popup, x: i32, y: i32, width: i32, height: i32) void = null,
                popupDone: ?*const fn (data: *T, popup: *Popup) void = null,
                repositioned: ?*const fn (data: *T, popup: *Popup, token: u32) void = null,
            },
        ) !void {
            const S = struct {
                const listener = Self.Listener{
                    .configure = if (handlers.configure != null) configure else null,
                    .popupDone = if (handlers.popupDone != null) popupDone else null,
                    .repositioned = if (handlers.repositioned != null) repositioned else null,
                };

                fn configure(ptr: ?*anyopaque, popup_: *Popup, x_: i32, y_: i32, width_: i32, height_: i32) callconv(.c) void {
                    if (handlers.configure) |h| {
                        h(@ptrCast(@alignCast(ptr)), popup_, x_, y_, width_, height_);
                    }
                }
                fn popupDone(ptr: ?*anyopaque, popup_: *Popup) callconv(.c) void {
                    if (handlers.popupDone) |h| {
                        h(@ptrCast(@alignCast(ptr)), popup_);
                    }
                }
                fn repositioned(ptr: ?*anyopaque, popup_: *Popup, token_: u32) callconv(.c) void {
                    if (handlers.repositioned) |h| {
                        h(@ptrCast(@alignCast(ptr)), popup_, token_);
                    }
                }
            };
            const proxy: *inner.wl_proxy = @ptrCast(@alignCast(self));
            if (inner.wl_proxy.wl_proxy_add_listener(proxy, @ptrCast(@alignCast(@constCast(&S.listener))), @ptrCast(@alignCast(state))) != 0) {
                return error.AddListenerFailed;
            }
        }

        pub const Error = enum(u32) {
            invalid_grab = 0,
        };

        pub const interface: common.Interface = .{
            .name = "xdg_popup",
            .version = 7,
            .method_count = 3,
            .methods = &.{
                .{
                    .name = "destroy",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "grab",
                    .signature = "ou",
                    .types = &.{
                        &Wl.Seat.interface,
                        null,
                    },
                },
                .{
                    .name = "reposition",
                    .signature = "3ou",
                    .types = &.{
                        &Positioner.interface,
                        null,
                    },
                },
            },
            .event_count = 3,
            .events = &.{
                .{
                    .name = "configure",
                    .signature = "iiii",
                    .types = &.{
                        null,
                        null,
                        null,
                        null,
                    },
                },
                .{
                    .name = "popup_done",
                    .signature = "",
                    .types = &.{},
                },
                .{
                    .name = "repositioned",
                    .signature = "3u",
                    .types = &.{
                        null,
                    },
                },
            },
        };
    }; // Interface

};
