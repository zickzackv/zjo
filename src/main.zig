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

fn read_args(alloc: *std.mem.Allocator) ![][]u8 {
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

    var args = try read_args(allocator);
    var x = try read_stdin(allocator);

    std.debug.warn("x: {}", .{x});
    for (args[1..]) |arg| {
        std.debug.warn("arg: {}\n", .{arg});
    }

}
