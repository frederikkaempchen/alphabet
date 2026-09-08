const std = @import("std");
const testing = std.testing;
const Type = std.builtin.Type;
const Enum = Type.Enum;
const EnumField = Type.EnumField;
const Allocator = std.mem.Allocator;

/// checks that ther is at least one symbol and that all symbols are unique
fn validateAlphabet(comptime symbols: []const u8) void {
    const size = symbols.len;
    if (size == 0) @compileError("alphabet cannot be empty");

    for (symbols, 0..) |c, i| {
        for (symbols[i + 1 ..], i + 1..) |d, j| {
            if (c == d) {
                const markers: [j + 1]u8 = .{' '} ** i ++ .{'^'} ++ .{' '} ** (j - i - 1) ++ .{'^'};
                @compileError(std.fmt.comptimePrint(
                    \\Duplicate character at indices {} and {}.
                    \\symbols: {s}
                    \\         {s}
                , .{ i, j, symbols, markers }));
            }
        }
    }
}

/// creates a minimal sized enum(u<minimal size>) with the symbols as field names
/// each symbol is assigned its index in the symbols slice as value
pub fn Alphabet(comptime symbols: []const u8) type {
    validateAlphabet(symbols);

    const size = symbols.len;

    const tag_int_bits = @max(1, std.math.log2_int_ceil(usize, size)); // 1 <= size <= 2^tag_type.bits
    const TagInt = @Int(.unsigned, tag_int_bits);

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

    return struct {
        /// enum of the alphabets symbols
        /// fields: name = symbols[i] , value = i
        /// tag int is u<minimal size>
        pub const Symbol: type = @Enum(TagInt, .exhaustive, &field_names, &field_values);

        const Self = @This();

        pub fn toChar(symbol: Symbol) u8 {
            return symbols[@intFromEnum(symbol)];
        }

        pub fn fromChar(char: u8) error{InvalidCharacter}!Symbol {
            const table: [256]?Symbol = comptime blk: {
                var result: [256]?Symbol = .{null} ** 256;
                for (symbols, 0..) |s, i| {
                    result[s] = @enumFromInt(i);
                }

                break :blk result;
            };

            if (table[char]) |sym| return sym else return error.InvalidCharacter;
        }

        /// returns a new alphabet, with the passed symbols appended to this alphabets symbols: `Alphabet(symbols ++ new_symbols)`
        /// conversion between this alphabet and the returned alphabet is possible for all shared symbols
        pub fn extendWith(comptime new_symbols: []const u8) type {
            for (new_symbols, 0..) |new_symbol, i| {
                for (symbols, 0..) |symbol, j| {
                    if (new_symbol == symbol) {
                        const i_marker: [i + 1]u8 = .{' '} ** i ++ .{'^'};
                        const j_marker: [j + 1]u8 = .{' '} ** j ++ .{'^'};

                        @compileError(std.fmt.comptimePrint(
                            \\The symbol {c} at index {} of the new_symbols already exists in Alphabet symbols at index {}.
                            \\Alphabet symbols: {s}
                            \\                  {s}
                            \\new_symbols:      {s}
                            \\                  {s}
                        , .{ new_symbol, j, i, symbols, j_marker, new_symbols, i_marker }));
                    }
                }
            }
            return Alphabet(symbols ++ new_symbols);
        }

        /// returns uint<tag int bits of Symbol enum * len>
        pub fn PackedInt(comptime len: usize) type {
            return @Int(.unsigned, tag_int_bits * len);
        }

        /// returns the smallest single integer representation of a slice of symbols
        pub inline fn pack(comptime len: usize, slice: *const [len]Symbol) PackedInt(len) {
            var x: PackedInt(len) = @intFromEnum(slice[0]);
            inline for (slice[1..]) |elem| {
                x = (x << tag_int_bits) | @intFromEnum(elem);
            }
            return x;
        }
    };
}

test "extend with a many symbols" {
    const Base = Alphabet("ACTGN");
    const AlignmentBase = Base.extendWith("BLzuipqwert");
    try testing.expectEqual(@intFromEnum(try AlignmentBase.fromChar('A')), @intFromEnum(try Base.fromChar('A')));
}

test "int from slice" {
    const Base = Alphabet("ACTGN"); // 3 bits
    const word: [5]Base.Symbol = .{ .A, .C, .T, .G, .N }; // 5*3 = 15
    const w_int = Base.intFromSlice(5, &word);
    try testing.expectEqual(@TypeOf(w_int), @Int(.unsigned, 15));
}
