const std = @import("std");

// var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const ClearOptions = struct {
    set_default_capacity: bool = false,
};

fn Bucket(key: type, value: type) type {
    return struct {
        key: key,
        value: value,
        found: bool = false,
    };
}

pub fn HashMap(comptime T: type, comptime T2: type) type {
    return struct {
        const Self = @This();
        buckets: []Bucket(T, T2),
        allocator: std.mem.Allocator,
        used_buckets: i64 = 0,
        capacity: usize,

        pub fn init() !Self {
            const capacity: usize = 2 << 13; // default capacity

            // const allocator = gpa.allocator();
            const allocator = std.heap.page_allocator;
            const buckets = try allocator.alloc(Bucket(T, T2), capacity);

            return .{
                .buckets = buckets,
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buckets);
            self.* = undefined;
        }

        /// for debugging only
        fn buckets_print(self: *Self) void {
            for (self.buckets) |x| {
                switch (@TypeOf(x.key)) {
                    []const u8, []u8 => {
                        if (x.found)
                            std.debug.print("key: {s}\tvalue:{}\n", .{ x.key, x.value });
                    },
                    u8, u16, u32, u64, u128 => {
                        if (x.key > 100000) {
                            continue;
                        }
                        std.debug.print("key: {}\tvalue:{}\n", .{ x.key, x.value });
                    },
                    else => {},
                }
                // std.debug.print("key: {}\tvalue:{}\n", .{ x.key, x.value });
            }
        }

        pub fn clear(
            self: *Self,
            options: ClearOptions,
        ) !void {
            var capacity: usize = 0;

            if (options.set_default_capacity) capacity = 2 << 13 else capacity = @intCast(self.buckets.len);
            // self.buckets_print();
            self.used_buckets = 0;
            self.allocator.free(self.buckets);
            self.buckets = try self.allocator.alloc(Bucket(T, T2), capacity);
            self.capacity = capacity;
            // std.debug.print("AFTER\n", .{});
            // self.buckets_print();
        }

        pub fn del(
            self: *Self,
            K: T,
        ) void {
            const key = self.hash(K);

            switch (@TypeOf(K)) {
                u8, u16, u32, u64, u128 => {
                    if (key == 0) {
                        if (self.buckets[key].found) {
                            for (key..key + self.buckets.len) |x| {
                                if (self.buckets.len == x) break;
                                const b = self.buckets[x];
                                if (b.found) {
                                    if (key == x) {
                                        if (b.found) self.buckets[x] = self.buckets[x + 1];
                                    }
                                }
                            }
                        }
                        return;
                    }
                    if (self.buckets[key].found) {
                        for (key..key + self.buckets.len) |x| {
                            if (self.buckets.len == x) break;
                            const b = self.buckets[x - 1];
                            if (b.found) {
                                if (key == x - 1) {
                                    self.buckets[x - 1] = self.buckets[x];
                                }
                            }
                        }
                    }
                },
                []const u8, []u8 => {
                    if (self.buckets[key].found) {
                        for (key..key + self.buckets.len) |x| {
                            if (self.buckets.len == x) break;
                            const b = self.buckets[x - 1];
                            if (b.found) {
                                if (key == x - 1) {
                                    self.buckets[x - 1] = self.buckets[x];
                                }
                            }
                        }
                    }
                },
                else => {
                    @compileError(std.fmt.comptimePrint("Unsupported key type: {}", .{@TypeOf(K)}));
                },
            }
        }
        pub fn put(
            self: *Self,
            K: T,
            V: T2,
        ) void {
            self.realloc() catch {};

            const key = self.hash(K);

            // std.debug.print("hash value {s} - {}\n", .{ K, key });

            if (self.buckets[key].found) { // collision
                // std.debug.print("\ncollision: {} - {}. Found key: {}\n", .{ K, key, self.buckets[key].key });
                var coll_key: usize = key + 1;
                if (self.buckets[coll_key].found) {
                    coll_key += 1;
                }

                // std.debug.print("collision key: {}\n", .{coll_key});

                self.buckets[coll_key].key = K;
                self.buckets[coll_key].value = V;
                self.buckets[coll_key].found = true;
                self.used_buckets += 1;
                return;
                //
            }
            self.buckets[key].key = K;
            self.buckets[key].value = V;
            self.buckets[key].found = true;
            self.used_buckets += 1;
        }

        pub fn get(self: *Self, K: T) ?T2 {
            const key = self.hash(K);

            // std.debug.print("hash value {} - {}\n", .{ K, key });

            if (self.buckets[key].found and eql(self.buckets[key].key, K)) {
                return self.buckets[key].value;
            }

            for (0..key + self.buckets.len) |x| {
                if (self.buckets.len == x) break;
                if (eql(self.buckets[x].key, K)) return self.buckets[x].value;
            }

            return null;
        }

        fn realloc(self: *Self) !void {
            if (@divTrunc(self.used_buckets, @as(i64, @intCast(self.capacity))) * 100 >= 70) {
                // std.debug.print("Realloc\n", .{});
                self.buckets = try self.allocator.realloc(self.buckets, self.capacity * 2);
                self.capacity *= 2;
            }
        }

        fn hash(self: *Self, K: T) usize {
            var x: i64 = 0;

            switch (@TypeOf(K)) {
                u8, u16, u32, u64, u128 => {
                    x = h(@intCast(K), self.buckets.len);
                },
                []const u8, []u8 => {
                    var s_sum: i64 = 0;
                    for (0..K.len) |j| {
                        s_sum += @intCast(K[j] * (j + 1));
                    }
                    x = h(s_sum, self.buckets.len);
                },
                else => {
                    @compileError(std.fmt.comptimePrint("Unsupported key type: {}", .{@TypeOf(K)}));
                },
            }

            return @as(usize, @intCast(x));
            // return @as(usize, @intCast(@mod(x, @as(i128, @intCast(self.buckets.len)))));
        }
    };
}

fn h(key: i64, cap: usize) i64 {
    const A: f32 = 0.6180339887;
    return @as(i32, @intFromFloat(@as(f32, @floatFromInt(@as(i32, @intCast(cap)))) * ((@as(f32, @floatFromInt(key)) * A) - @as(f32, @floatFromInt(@as(i32, @intFromFloat(@as(f32, @floatFromInt(key)) * A)))))));
}

fn eql(A: anytype, B: anytype) bool {
    switch (@TypeOf(A)) {
        []const u8, []u8 => {
            return std.mem.eql(u8, A, B);
        },
        else => {
            return A == B;
        },
    }
}
