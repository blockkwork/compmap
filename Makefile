build:
	zig build && ./zig-out/bin/hashmap
clear_cache:
	rm -rf zig-cache
tests:
	zig test src/hashmap_test.zig