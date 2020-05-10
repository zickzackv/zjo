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

fn createArrayDocument(arena: *std.heap.ArenaAllocator) std.json.ValueTree {
    return std.json.ValueTree{
        .arena = arena.*,
        .root = std.json.Value{ .Array = std.json.Array.init(&arena.allocator) }
    };
}

fn createObjectDocument(arena: *std.heap.ArenaAllocator) std.json.ValueTree {
    return std.json.ValueTree{
        .arena = arena.*,
        .root = std.json.Value{ .Object = std.json.ObjectMap.init(&arena.allocator) }
    };
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


fn appendToArray(tree: *std.json.ValueTree, string: []const u8) !void {
    var value = std.json.Value{ .String = string };
    _ = try tree.root.Array.append(value);
    return;
}

fn appendToObject(tree: *std.json.ValueTree, keyValue: [] const u8) !void {

    var segments: std.mem.TokenIterator = std.mem.tokenize(keyValue, "=:");
    var key: []const u8 =  undefined;
    var value: []const u8 = undefined;
    
    if (segments.next()) |k| {
        key = k;
    }

    value = segments.rest();
    
    _ = try tree.root.Object.put(key, std.json.Value{ .String = value });

    return;
}

pub fn main() anyerror!void {
    // create allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    var arrayDoc = createArrayDocument(&arena);
    var objectDoc = createObjectDocument(&arena);
    
    var args = try readArgs(allocator);
    for (args[1..]) |arg| {
        try appendToObject(&objectDoc, arg);
    }

    
//     try appendToArray(&arrayDoc, "literal String");
//     try appendToArray(&arrayDoc, "another String");

//     try appendToObject(&objectDoc, "key=value");
//     try appendToObject(&objectDoc, "key2=ovalue");
//     try appendToObject(&objectDoc, "key3=':ovalue'");
//     try appendToObject(&objectDoc, "key4='oval=ue'");
    
//     var outstream = std.io.getStdOut().outStream();
//     var writer = std.json.writeStream(outstream, 10);

//     try outstream.print("\n", .{});
//     try writer.emitJson(arrayDoc.root);
//     try outstream.print("\n", .{});
//     try writer.emitJson(objectDoc.root);
//     try outstream.print("\n", .{});
}


const testing = std.testing;
const assert = std.debug.assert;


test "allocate root element" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

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
        var jsDoc = std.json.ValueTree {
            .arena = arena,
            .root = std.json.Value{ .Array = std.ArrayList(std.json.Value).init(allocator) }
        };

        _ = try appendToArray(&jsDoc, "literal String");

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

test "parse json"  {
    const allocator = std.testing.allocator;
    var arena  = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    {
        var p = std.json.Parser.init(&arena.allocator, false);
        const s = " \"quoted=string\" ";

        var j = try p.parse(s);
        assert(j.root == .String);
    }
    {
        var p = std.json.Parser.init(&arena.allocator, false);
        const s = " 1231233 ";
        var j = try p.parse(s);
        assert(j.root == .Integer);
    }
}
    
// test "read stdin and parse" {
//     const allocator = std.teting.allocator;
//     var arena = std.heap.ArenaAlloctor.init(allocator);
//     defer arena.deinit();

//     {

    

// }
