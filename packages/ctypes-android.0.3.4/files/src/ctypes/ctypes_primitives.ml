open Primitives
let sizeof : type a. a prim -> int = function
 | Char -> 1
 | Schar -> 1
 | Uchar -> 1
 | Short -> 2
 | Int -> 4
 | Long -> 4
 | Llong -> 8
 | Ushort -> 2
 | Uint -> 4
 | Ulong -> 4
 | Ullong -> 8
 | Size_t -> 4
 | Int8_t -> 1
 | Int16_t -> 2
 | Int32_t -> 4
 | Int64_t -> 8
 | Uint8_t -> 1
 | Uint16_t -> 2
 | Uint32_t -> 4
 | Uint64_t -> 8
 | Camlint -> 4
 | Nativeint -> 4
 | Float -> 4
 | Double -> 8
 | Complex32 -> 8
 | Complex64 -> 16
let alignment : type a. a prim -> int = function
 | Char -> 1
 | Schar -> 1
 | Uchar -> 1
 | Short -> 2
 | Int -> 4
 | Long -> 4
 | Llong -> 8
 | Ushort -> 2
 | Uint -> 4
 | Ulong -> 4
 | Ullong -> 8
 | Size_t -> 4
 | Int8_t -> 1
 | Int16_t -> 2
 | Int32_t -> 4
 | Int64_t -> 8
 | Uint8_t -> 1
 | Uint16_t -> 2
 | Uint32_t -> 4
 | Uint64_t -> 8
 | Camlint -> 4
 | Nativeint -> 4
 | Float -> 4
 | Double -> 8
 | Complex32 -> 4
 | Complex64 -> 8
let name : type a. a prim -> string = function
 | Char -> "char"
 | Schar -> "signed char"
 | Uchar -> "unsigned char"
 | Short -> "short"
 | Int -> "int"
 | Long -> "long"
 | Llong -> "long long"
 | Ushort -> "unsigned short"
 | Uint -> "unsigned int"
 | Ulong -> "unsigned long"
 | Ullong -> "unsigned long long"
 | Size_t -> "size_t"
 | Int8_t -> "int8_t"
 | Int16_t -> "int16_t"
 | Int32_t -> "int32_t"
 | Int64_t -> "int64_t"
 | Uint8_t -> "uint8_t"
 | Uint16_t -> "uint16_t"
 | Uint32_t -> "uint32_t"
 | Uint64_t -> "uint64_t"
 | Camlint -> "camlint"
 | Nativeint -> "intnat"
 | Float -> "float"
 | Double -> "double"
 | Complex32 -> "float _Complex"
 | Complex64 -> "double _Complex"
let pointer_size = 4
let pointer_alignment = 4
