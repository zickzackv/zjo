const std = @import("std");

const stdin = &std.io.getStdIn().inStream();

const BUFFSIZE = 2048;


/// reading from stdin and returning an array of characters (string).
fn readStdin(alloc: *std.mem.Allocator) ![]u8 {
    var read_buffer: [BUFFSIZE]u8 = undefined;
    var input_buffer = std.ArrayList(u8).init(alloc);
    defer input_buffer.deinit();

    var read_size = try stdin.readAll(&read_buffer);

    while (read_size > 0): (read_size = try stdin.readAll(&read_buffer)) {
        try input_buffer.insertSlice(input_buffer.items.len, read_buffer[0..read_size]);
    }
    return input_buffer.toOwnedSlice();
}

/// Returning the unprocessed argument from the command line
fn readArgs(alloc: *std.mem.Allocator) ![][]u8 {
    const args = std.process.argsAlloc(alloc) catch |err| {
        std.debug.warn("Out of memory: {}\n", .{err});
        return error.OutOfMemory;
    };

    return args;
}

/// toy function!
fn createJson(allocator: *std.mem.Allocator) !std.json.Value {
    var value = std.json.Value{ .Object = std.json.ObjectMap.init(allocator) };
    _ = try value.Object.put("String", std.json.Value{ .String = "This is a String" });
    _ = try value.Object.put("Integer", std.json.Value{ .Integer = @intCast(i64, 10) });
    _ = try value.Object.put("Float", std.json.Value{ .Float = 3.14 });

    return value;
}


pub fn main() anyerror!void {
    // create allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var args = try readArgs(allocator);
    var x = try readStdin(allocator);

    std.debug.warn("x: {}", .{x});
    for (args[1..]) |arg| {
        std.debug.warn("arg: {}\n", .{arg});
    }

    var js = try createJson(allocator);
    var writer = std.json.writeStream(std.io.getStdOut().outStream(), 10);
    try writer.emitJson(js);
}

fn fromEqual(allocator: *std.mem.Allocator, keyValue: [] const u8) !std.json.Value {
    var js = std.json.Value{ .Object = std.json.ObjectMap.init(allocator) };
    var segments: std.mem.TokenIterator = std.mem.tokenize(keyValue, "=:");
    var key = segments.next().?;
    var value = segments.rest();

    _ = try js.Object.put(key, std.json.Value{ .String = value });

    return js;
}

const testing = std.testing;

test "key value separation" {
    const allocator = std.testing.allocator;
    var v = try fromEqual(std.testing.allocator, "key=value");
    defer v.Object.deinit();

    v.dump();
    std.debug.warn("value: {}\n", .{ v.Object.getValue("key") });
}
