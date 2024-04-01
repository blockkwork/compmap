const std = @import("std");
const hashmap = @import("hashmap.zig");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    try ex2();
}

fn ex2() !void {
    var hmap = try hashmap.HashMap([]const u8, u32).init();
    defer hmap.deinit();

    // put value
    // 123 - key
    // 900 - value
    hmap.put("compmap", 900);
    hmap.put("hello", 777);

    // get value
    const result = hmap.get("hello");
    std.debug.print("{}\n", .{result.?}); // output: 777

    try hmap.clear(.{}); // delete all buckets
}
