const std = @import("std");
const hashmap = @import("hashmap.zig");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var t = try hashmap.HashMap(u64, u64).init();
    defer t.deinit();

    t.put(3316, 329);
    t.put(732, 300);

    const res = t.get(3316);
    std.debug.print("{?}\n", .{res});

    const res2 = t.get(732);
    std.debug.print("{?}\n", .{res2});
}
