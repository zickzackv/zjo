const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ValueTree = std.json.ValueTree;
const Value = std.json.Value;
const stdin = &std.io.getStdIn().inStream();

const args = @import("args");

const BUFFSIZE = 2048;

var arena = ArenaAllocator.init(std.heap.page_allocator);

///Either array or object json document.
const Document = union(enum) {
    const Self = @This();
    
    array: Value,
    object: Value,

    /// initialize as array document
    pub fn array_init() Self {
        var value = Value{ .Array = std.json.Array.init(&arena.allocator) };
        return Document {
            .array = value
        };
    }

    /// Initialize as object document
    pub fn object_init() Self {
        var value = Value{ .Object = std.json.ObjectMap.init(&arena.allocator) };
        
        return Self{
            .object = value
        };
    }
    
    /// Adds new element to the document
    pub fn push_element(self: *Self, string: []const u8) !void {
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

    /// prints Document outstream
    fn print(self: Self, outstream: var) !void {
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

    /// prints Document to stdout!
    fn printStdOut(self: Self) !void {
        var outstream = std.io.getStdOut().outStream();
        try self.print(outstream);
    }


    /// String representation of the document
    /// caller ownes the string!
    fn stringify(self: Self) ![]u8 {
        var x = std.ArrayList(u8).init(&arena.allocator);
        var stream = x.outStream();
        var writer = std.json.writeStream(stream, 10);
        _ = try self.print(stream);
        return x.toOwnedSlice();
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
    var stdout = std.io.getStdOut().outStream();

    var cli = try args.parseForCurrentProcess(struct {
        @"object": bool = false,
        @"array": bool = false, 
        help: bool = false,

        pub const shorthands = .{
            .a = "array",
            .o = "object",
            .h = "help",
        };
    }, &arena.allocator);
    defer cli.deinit();

    if (cli.options.help) {
        try stdout.print(
            "{} [--help] [--object] [--array] [ARG]...\n",
            .{std.fs.path.basename(cli.executable_name.?)},
        );
        try stdout.writeAll(@embedFile("cli.help.txt"));

        return;
    }
    
    var document = if (cli.options.array) Document.array_init() else Document.object_init();
    for (cli.positionals) |arg| {
        _ = try document.push_element(arg);
    }

    var string = try document.stringify();
    defer arena.allocator.free(string);

    try stdout.writeAll(string);
}


const testing = std.testing;
const assert = std.debug.assert;

test "parse json"  {
    const allocator = std.testing.allocator;
    var arena  = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var p = std.json.Parser.init(&arena.allocator, false);

    {
        defer p.reset();
        const s = \\""
        ;
        var j = try p.parse(s);
    }

    {
        defer p.reset();
        const s = \\ "quoted=string"
        ;
        var j = try p.parse(s);
        assert(j.root == .String);
    }
    {
        defer p.reset();
        const s = \\ 1231233
        ;
        var j = try p.parse(s);
        assert(j.root == .Integer);
    }
    {
        defer p.reset();
        const s = \\ "123"
        ;
        var j = try p.parse(s);
        assert(j.root == .String);
    }

}
