//
// testing reading from stdin.
//

const std = @import("std");
const stdin = std.io.getStdIn().inStream();
const Allocator = std.mem.Allocator;

const BUFSIZ = 8192;

// use zig's std lib for reading lines.
// line length is limited to buffer length
// append line to the ArrayList
fn readLines(allocator: *Allocator) !std.ArrayList([]u8) {
    var array = std.ArrayList([]u8).init(allocator);
    var buffer: [BUFSIZ]u8 = undefined;

    while (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |line| {
        var copy = try std.mem.dupe(allocator, u8, line);
        _ = try array.append(copy);
    }

    return array;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().outStream();

    var x = try readLines(std.heap.page_allocator);
    for (x.items) |l| {
        try stdout.print("{}\n", .{l});
    }
}
