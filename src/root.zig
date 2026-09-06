const std = @import("std");
const Type = std.builtin.Type;
const Enum = Type.Enum;
const EnumField = Type.EnumField;
const Allocator = std.mem.Allocator;

fn validateAlphabet(comptime symbols: []const u8) void {
    const size = symbols.len;
    if (size == 0) @compileError("alphabet cannot be empty");

    for (symbols, 0..) |c, i| {
        for (symbols[i + 1 ..], i + 1..) |d, j| {
            if (c == d)
                @compileError(std.fmt.comptimePrint(
                    "Duplicate character at indices {} and {}.",
                    .{ i, j },
                ));
        }
    }
}

pub fn Alphabet(comptime symbols: []const u8) type {
    validateAlphabet(symbols);

    const size = symbols.len;

    const TagInt = @Int(.unsigned, std.math.log2_int_ceil(usize, size)); // size <= 2^tag_type.bits

    const field_names: [size][]const u8 = blk: {
        var res: [size][]const u8 = undefined;
        for (symbols, 0..) |elem, i| {
            res[i] = &.{elem};
        }
        break :blk res;
    };

    const field_values: [size]TagInt = blk: {
        var res: [size]TagInt = undefined;
        for (res, 0..) |_, i| {
            res[i] = i;
        }
        break :blk res;
    };

    // - fromChar, intoChar - both based on a table lookup and symbols

    return struct {
        pub const Symbol: type = @Enum(TagInt, .exhaustive, &field_names, &field_values);

        const Self = @This();

        pub fn toChar(symbol: Symbol) u8 {
            return symbols[@intFromEnum(symbol)];
        }

        pub fn fromChar(char: u8) error{InvalidCharacter}!Symbol {
            inline for (symbols, 0..) |elem, i| {
                if (char == elem) return @enumFromInt(i);
            }
            return error.InvalidCharacter;
        }
    };
}
