const hashmap = @import("hashmap.zig");
const testing = @import("std").testing;
const RndGen = std.rand.DefaultPrng;
const std = @import("std");

test "delete_string" {
    var t = try hashmap.HashMap([]const u8, u64).init();
    defer t.deinit();

    for (0..10000) |x| {
        const k = try randomSlice(std.heap.page_allocator, std.crypto.random, u8, 10);
        t.put(k, @intCast(x * 2));
        t.del(k);
        try testing.expect(t.get(k) == null);
    }
}

test "delete" {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();

    for (1..10000) |x| {
        t.put(@intCast(x), @intCast(x * 2));
        t.del(@intCast(x));
        try testing.expect(t.get(@intCast(x)) == null);
    }

    // t.del(3316);
    // std.debug.print("{any}\n", .{t.get(3316)});
}

test "delete_second_case" {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();

    for (0..10000) |x| {
        t.put(@intCast(x), @intCast(x * 2));
        t.del(@intCast(x));
    }

    for (0..10000) |x| {
        try testing.expect(t.get(@intCast(x)) == null);
    }
}

test "delete_third_case" {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();
    t.del(10);
    t.put(10, 30);
    t.del(10);
}

test "collision_u64" {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();

    for (0..100000) |x| {
        t.put(@intCast(x), @intCast(x * 2));
        try testing.expect(t.get(@intCast(x)).? == x * 2);
    }
}

test "clear" {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();

    for (0..1000) |x| {
        t.put(@intCast(x), @intCast(x * 2));
        try testing.expect(t.get(@intCast(x)).? == x * 2);
    }

    try t.clear(.{});

    for (0..1000) |x| {
        if (t.get(@as(u64, @intCast(x))) != null) @panic("t.get(@as(u64, @intCast(x))) != null");
    }

    try t.clear(.{ .set_default_capacity = true });
    try testing.expect(t.buckets.len == 2 << 13);
}

test "collision_i32" {
    var t = try hashmap.HashMap(u32, u32).init();
    defer t.deinit();

    for (0..100000) |x| {
        t.put(@intCast(x), @intCast(x * 2));
        try testing.expect(t.get(@intCast(x)).? == x * 2);
    }
}
test "collision_string" {
    var t = try hashmap.HashMap([]u8, i32).init();
    defer t.deinit();

    for (0..10000) |x| {
        const k = try randomSlice(std.heap.page_allocator, std.crypto.random, u8, 10);
        t.put(k, @intCast(x * 2));
        try testing.expect(t.get(k).? == x * 2);
        // defer testing.allocator.free(k); // memory leak
    }
}

// https://github.com/nektro/zig-extras/blob/master/src/randomSlice.zig
const alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";
pub fn randomSlice(alloc: std.mem.Allocator, rand: std.rand.Random, comptime T: type, len: usize) ![]T {
    var buf = try alloc.alloc(T, len);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = alphabet[rand.int(u8) % alphabet.len];
    }
    return buf;
}
