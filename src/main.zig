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
