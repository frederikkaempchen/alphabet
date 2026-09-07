# alphabet
a neat way to create a minimal symbol enum (an alphabet) from a string (the symbols of the alphabet)

```zig
pub fn Alphabet(comptime symbols: []const u8) type {
  return struct {
    pub const Symbol = @Enum(...);
    
    pub fn fromChar(char: u8) Symbol {...};

    pub fn toChar(symbol: Symbol) u8 {...};

    pub fn extendWith(comptime new_symbols: []const u8) type {...};
  }
}
```

## usecases
this library was originally created as a way to abstracto from different bioinformatic alphabets - amino acids or nucleotides for example.
```zig
pub const Nucleotide = Alphabet("ACTG");
const A = Alphabet.Symbol.0;
const a_char = Alphabet.toChar(A);
```

## implementation
the way this is done results in the following enum for the upper example (not exactly):
```zig
pub const Symbol = enum(u3) { // the integer type is the minimal size integer type for all symbols to fit into the enum
  A = 0, // no reordering here, same sequence as the input string
  C = 1,
  T = 2,
  G = 3,
}
  
```

this leads to some nice conversion tricks continuing the usecase example - might be useful for some:
```zig
pub const NucleotideAlignment = Nucleaotide.extendWith(&.{'-'});

const AAlign: NucleotideAligment.Symbol = @enumFromInt(@intFromEnum(A));
  
```
