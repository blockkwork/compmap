# CompMap
Compile time hash map that supports keys and values of different data types


## 📦 Installing
### 1. Download [compmap](https://raw.githubusercontent.com/blockkwork/compmap/main/src/hashmap.zig)
### 2. Copy the code to a zig file (example hmap.zig)
### 3. Add import to your code:
```zig
const hmap = @import("hmap.zig")
```

**also see [usage](#🚀-usage)**


## 💡 Info
| Data type   | Key                        | Value        |
|-------------|----------------------------|--------------|
| u8          | Works                      | Works        |
| u16         | Works                      | Works        |
| u32         | Works                      | Works        |
| u64         | Works                      | Works        |
| u128        | Works                      | Works        |
| []u8        | Works                      | Works        |
| []const u8  | Works                      | Works        |
| Signed int  |   -                        | -            |

## 🚀 Usage
```zig
var hmap = try hashmap.HashMap(u64, u64).init();
defer hmap.deinit();

// 123 - key
// 900 - value
hmap.put(123, 900);
hmap.put(321, 100);

hmap.del(123);
std.debug.print("{}", .{hmap.get(321).?}); // output: 100

```

### Compmap with `[]const u8` type

```zig
var hmap = try hashmap.HashMap([]const u8, u32).init();
defer hmap.deinit();

hmap.put("compmap", 900);
hmap.put("hello", 777);

// get value
const result = hmap.get("hello");
std.debug.print("{}\n", .{result.?}); // output: 777

try hmap.clear(.{}); // delete all buckets
```
