const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ValueTree = std.json.ValueTree;
const Value = std.json.Value;
const stdin = &std.io.getStdIn().inStream();
const BUFFSIZE = 2048;

var a = ArenaAllocator.init(std.heap.page_allocator);

///Either array or object json document.
const Document = union(enum) {
    const Self = @This();
    
    array: Value,
    object: Value,

    /// initialize as array document
    pub fn array_init() Self {
        var value = Value{ .Array = std.json.Array.init(&a.allocator) };
        return Document {
            .array = value
        };
    }

    /// Initialize as object document
    pub fn object_init() Self {
        var value = Value{ .Object = std.json.ObjectMap.init(&a.allocator) };
        
        return Self{
            .object = value
        };
    }
    
    /// Adds new element to the document
    pub fn push_element(self: *Self, string: []u8) !void {
        switch (self.*) {
            Self.array => |*array| {
                try self.appendToArray(string);
            },
            Self.object => |*object|{
                try self.appendToObject(string);
            },
            else => unreachable
        }
    }

    /// prints Document to stdout!
    fn print(self: Self) !void {
        var outstream = std.io.getStdOut().outStream();
        var writer = std.json.writeStream(outstream, 10);

        switch(self) {
            Self.array => |array| {
               _ = try writer.emitJson(array);
            },
            Self.object => |object| {
                _ = try writer.emitJson(object);
            }
        }
    }

    /// adding elements to the array document
    fn appendToArray(self: *Self, string: []const u8) !void {
        var value = std.json.Value{ .String = string };
        _ = try self.array.Array.append(value);
    }

    /// adds new element to the object document
    fn appendToObject(self: *Self, keyValue: [] const u8) !void {

        var segments: std.mem.TokenIterator = std.mem.tokenize(keyValue, "=:");
        var key: []const u8 =  undefined;
        var value: []const u8 = undefined;
        
        if (segments.next()) |k| {
            key = k;
        }

        value = segments.rest();
        
        _ = try self.object.Object.put(key, std.json.Value{ .String = value });

        return;
    }

    
};


/// Returning the unprocessed argument from the command line
fn readArgs(alloc: *std.mem.Allocator) ![][]u8 {
    const args = std.process.argsAlloc(alloc) catch |err| {
        std.debug.warn("Out of memory: {}\n", .{err});
        return error.OutOfMemory;
    };

    return args;
}

fn readLines(allocator: *Allocator) !std.ArrayList([]u8) {
    var array = std.ArrayList([]u8).init(allocator);
    var buffer : [BUFSIZ]u8 = undefined;

    while (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |line| {
        var copy = try std.mem.dupe(allocator, u8, line);
        _ =  try array.append(copy);
    }

    return array;
}

pub fn main() anyerror!void {
    // create allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var document01 = Document.array_init();
    var document02 = Document.object_init();

    var args = try readArgs(&a.allocator);
    for (args[1..]) |arg| {
        try document01.push_element(arg);
        try document02.push_element(arg);
    }

    try document01.print();
    try document02.print();
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
