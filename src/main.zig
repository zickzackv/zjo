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
   //var x = try readStdin(allocator);

    //std.debug.warn("x: {}", .{x});
    for (args[1..]) |arg| {
        std.debug.warn("arg: {}\n", .{arg});
    }
    
    var jsDoc = std.json.ValueTree{
        .arena = arena,
        .root = std.json.Value{ .Array = std.json.Array.init(allocator) }
    };
            
    try toArray(&jsDoc, "literal String");

    var js = try createJson(allocator);
    var writer = std.json.writeStream(std.io.getStdOut().outStream(), 10);
    try writer.emitJson(js);
    try writer.emitJson(jsDoc.root);
    
}

fn toHashMap(allocator: *std.mem.Allocator, keyValue: [] const u8) !std.json.Value {
    var js = std.json.Value{ .Object = std.json.ObjectMap.init(allocator) };
    var segments: std.mem.TokenIterator = std.mem.tokenize(keyValue, "=:");
    var key: []const u8 =  undefined;
    var value: []const u8 = undefined;
    
    if (segments.next()) |k| {
        key = k;
    }

    value = segments.rest();
    
    _ = try js.Object.put(key, std.json.Value{ .String = value });

    return js;
}


fn toArray(tree: *std.json.ValueTree, string: []const u8) !void {
    var allocator = &tree.arena.allocator;
    var value = std.json.Value{ .String = string };
    _ = try tree.root.Array.append(value);
    return;
}


const testing = std.testing;
const assert = std.debug.assert;


test "allocate root element" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    {
        const jsonDoc = std.json.ValueTree {
            .arena = arena,
            .root  = @as(std.json.Value, .Null)
        };

        // only works because Value is a tagged union.
        assert(@enumToInt(jsonDoc.root) == 0);        
    }

    {
        const jsonDoc = std.json.ValueTree {
            .arena = arena,
            .root  = std.json.Value{ .Bool = true }
        };
        assert(@enumToInt(jsonDoc.root) == 1);        
    }

    {
        const jsDoc = std.json.ValueTree {
            .arena = arena,
            .root = std.json.Value{ .Array = std.ArrayList(std.json.Value).init(std.heap.page_allocator) }
        };

        _ = try toArray(&jsDoc, "literal String");

        jsDoc.root.dump();
        std.debug.warn("TEST", .{});
    }
}


test "key value separation" {
    const allocator = std.testing.allocator;
    {
        var value = try toHashMap(allocator, "key=value");
        defer value.Object.deinit();
        const object = value.Object;

        var buffer: [15]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        try value.jsonStringify(.{}, fbs.outStream());
        testing.expectEqualSlices(u8, fbs.getWritten(), "{\"key\":\"value\"}");
    }

    {
        var value = try toHashMap(allocator, "key=value=value");
        const object = value.Object;
        defer value.Object.deinit();

        var buffer: [30]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buffer);
        try value.jsonStringify(.{}, fbs.outStream());
        testing.expectEqualSlices(u8, fbs.getWritten(), "{\"key\":\"value=value\"}");
    }

}
