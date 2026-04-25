// Generated from the protocol XML file. DO NOT EDIT.

const std = @import("std");
const mem = std.mem;

const inner = @import("client.zig");
const common = @import("common.zig");

const Client = @This();

pub const Wl = struct {
    pub const Display = opaque {
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            invalid_object = 0,
            invalid_method = 1,
            no_memory = 2,
            implementation = 3,
        };

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
            return @ptrCast(@alignCast(id));
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
        const version: u32 = 1;

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
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

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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

        pub const Error = enum(u32) {
            invalid_finish = 0,
            invalid_action_mask = 1,
            invalid_action = 2,
            invalid_offer = 3,
        };

        const interface: common.Interface = .{
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

        pub const Error = enum(u32) {
            invalid_action_mask = 0,
            invalid_source = 1,
        };

        const interface: common.Interface = .{
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

        pub const Error = enum(u32) {
            role = 0,
            used_source = 1,
        };

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
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
        };

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            role = 0,
        };

        const interface: common.Interface = .{
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
        };

        pub const Transient = enum(u32) {
            inactive = 1,
        };

        pub const FullscreenMethod = enum(u32) {
            default = 0,
            scale = 1,
            driver = 2,
            fill = 3,
        };

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            invalid_scale = 0,
            invalid_transform = 1,
            invalid_size = 2,
            invalid_offset = 3,
            defunct_role_object = 4,
            no_buffer = 5,
        };

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
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
            );

            if (id == null) return error.MarshalFailed;
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

        pub const Capability = enum(u32) {
            pointer = 1,
            keyboard = 2,
            touch = 4,
        };

        pub const Error = enum(u32) {
            missing_capability = 0,
        };

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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

        pub const KeymapFormat = enum(u32) {
            no_keymap = 0,
            xkb_v1 = 1,
        };

        pub const KeyState = enum(u32) {
            released = 0,
            pressed = 1,
            repeated = 2,
        };

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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
        };

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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
            );

            if (id == null) return error.MarshalFailed;
            return @ptrCast(@alignCast(id));
        }

        pub const Error = enum(u32) {
            bad_surface = 0,
            bad_parent = 1,
        };

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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

        const interface: common.Interface = .{
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
