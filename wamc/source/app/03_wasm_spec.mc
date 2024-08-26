import Toybox.Lang;
import Toybox.System;

const MAGIC as Number = 0x6d736100;
const VERSION as Number = 0x01;  // MVP

const STACK_SIZE as Number = 65536;
const CALLSTACK_SIZE as Number = 8192;

const I32 as Number = 0x7f;      // -0x01
const I64 as Number = 0x7e;      // -0x02
const F32 as Number = 0x7d;      // -0x03
const F64 as Number = 0x7c;      // -0x04
const ANYFUNC as Number = 0x70;  // -0x10
const FUNC as Number = 0x60;     // -0x20
const BLOCK as Number = 0x40;    // -0x40

var VALUE_TYPE as Dictionary<Number, String> = {
    I32 => "i32",
    I64 => "i64",
    F32 => "f32",
    F64 => "f64",
    ANYFUNC => "anyfunc",
    FUNC => "func",
    BLOCK => "block_type"
};

// Note: MonkeyC doesn't have a direct equivalent to Python's complex types like Type.
// We'll represent BLOCK_TYPE as a simple dictionary for this example.
var BLOCK_TYPE as Dictionary = {
    I32 => {"blockType" => BLOCK, "inputTypes" => [], "outputTypes" => [I32]},
    I64 => {"blockType" => BLOCK, "inputTypes" => [], "outputTypes" => [I64]},
    F32 => {"blockType" => BLOCK, "inputTypes" => [], "outputTypes" => [F32]},
    F64 => {"blockType" => BLOCK, "inputTypes" => [], "outputTypes" => [F64]},
    BLOCK => {"blockType" => BLOCK, "inputTypes" => [], "outputTypes" => []}
};

var BLOCK_NAMES as Dictionary<Number, String> = {
    0x00 => "fn",
    0x02 => "block",
    0x03 => "loop",
    0x04 => "if",
    0x05 => "else"
};

var EXTERNAL_KIND_NAMES as Dictionary<Number, String> = {
    0x0 => "Function",
    0x1 => "Table",
    0x2 => "Memory",
    0x3 => "Global"
};

var SECTION_NAMES as Dictionary<Number, String> = {
    0 => "Custom",
    1 => "Type",
    2 => "Import",
    3 => "Function",
    4 => "Table",
    5 => "Memory",
    6 => "Global",
    7 => "Export",
    8 => "Start",
    9 => "Element",
    10 => "Code",
    11 => "Data"
};

var OPERATOR_INFO as Dictionary = {
    // Control flow operators
    0x00 => {"name" => "unreachable", "immediate" => ""},
    0x01 => {"name" => "nop", "immediate" => ""},
    0x02 => {"name" => "block", "immediate" => "block_type"},
    0x03 => {"name" => "loop", "immediate" => "block_type"},
    0x04 => {"name" => "if", "immediate" => "block_type"},
    0x05 => {"name" => "else", "immediate" => ""},
    0x06 => {"name" => "RESERVED", "immediate" => ""},
    0x07 => {"name" => "RESERVED", "immediate" => ""},
    0x08 => {"name" => "RESERVED", "immediate" => ""},
    0x09 => {"name" => "RESERVED", "immediate" => ""},
    0x0a => {"name" => "RESERVED", "immediate" => ""},
    0x0b => {"name" => "end", "immediate" => ""},
    0x0c => {"name" => "br", "immediate" => "varuint32"},
    0x0d => {"name" => "br_if", "immediate" => "varuint32"},
    0x0e => {"name" => "br_table", "immediate" => "br_table"},
    0x0f => {"name" => "return", "immediate" => ""},

    // Call operators
    0x10 => {"name" => "call", "immediate" => "varuint32"},
    0x11 => {"name" => "call_indirect", "immediate" => "varuint32+varuint1"},

    0x12 => {"name" => "RESERVED", "immediate" => ""},
    0x13 => {"name" => "RESERVED", "immediate" => ""},
    0x14 => {"name" => "RESERVED", "immediate" => ""},
    0x15 => {"name" => "RESERVED", "immediate" => ""},
    0x16 => {"name" => "RESERVED", "immediate" => ""},
    0x17 => {"name" => "RESERVED", "immediate" => ""},
    0x18 => {"name" => "RESERVED", "immediate" => ""},
    0x19 => {"name" => "RESERVED", "immediate" => ""},

    // Parametric operators
    0x1a => {"name" => "drop", "immediate" => ""},
    0x1b => {"name" => "select", "immediate" => ""},

    0x1c => {"name" => "RESERVED", "immediate" => ""},
    0x1d => {"name" => "RESERVED", "immediate" => ""},
    0x1e => {"name" => "RESERVED", "immediate" => ""},
    0x1f => {"name" => "RESERVED", "immediate" => ""},

    // Variable access
    0x20 => {"name" => "get_local", "immediate" => "varuint32"},
    0x21 => {"name" => "set_local", "immediate" => "varuint32"},
    0x22 => {"name" => "tee_local", "immediate" => "varuint32"},
    0x23 => {"name" => "get_global", "immediate" => "varuint32"},
    0x24 => {"name" => "set_global", "immediate" => "varuint32"},

    0x25 => {"name" => "RESERVED", "immediate" => ""},
    0x26 => {"name" => "RESERVED", "immediate" => ""},
    0x27 => {"name" => "RESERVED", "immediate" => ""},

    // Memory-related operators
    0x28 => {"name" => "i32.load", "immediate" => "memory_immediate"},
    0x29 => {"name" => "i64.load", "immediate" => "memory_immediate"},
    0x2a => {"name" => "f32.load", "immediate" => "memory_immediate"},
    0x2b => {"name" => "f64.load", "immediate" => "memory_immediate"},
    0x2c => {"name" => "i32.load8_s", "immediate" => "memory_immediate"},
    0x2d => {"name" => "i32.load8_u", "immediate" => "memory_immediate"},
    0x2e => {"name" => "i32.load16_s", "immediate" => "memory_immediate"},
    0x2f => {"name" => "i32.load16_u", "immediate" => "memory_immediate"},
    0x30 => {"name" => "i64.load8_s", "immediate" => "memory_immediate"},
    0x31 => {"name" => "i64.load8_u", "immediate" => "memory_immediate"},
    0x32 => {"name" => "i64.load16_s", "immediate" => "memory_immediate"},
    0x33 => {"name" => "i64.load16_u", "immediate" => "memory_immediate"},
    0x34 => {"name" => "i64.load32_s", "immediate" => "memory_immediate"},
    0x35 => {"name" => "i64.load32_u", "immediate" => "memory_immediate"},
    0x36 => {"name" => "i32.store", "immediate" => "memory_immediate"},
    0x37 => {"name" => "i64.store", "immediate" => "memory_immediate"},
    0x38 => {"name" => "f32.store", "immediate" => "memory_immediate"},
    0x39 => {"name" => "f64.store", "immediate" => "memory_immediate"},
    0x3a => {"name" => "i32.store8", "immediate" => "memory_immediate"},
    0x3b => {"name" => "i32.store16", "immediate" => "memory_immediate"},
    0x3c => {"name" => "i64.store8", "immediate" => "memory_immediate"},
    0x3d => {"name" => "i64.store16", "immediate" => "memory_immediate"},
    0x3e => {"name" => "i64.store32", "immediate" => "memory_immediate"},
    0x3f => {"name" => "current_memory", "immediate" => "varuint1"},
    0x40 => {"name" => "grow_memory", "immediate" => "varuint1"},

    // Constants
    0x41 => {"name" => "i32.const", "immediate" => "varint32"},
    0x42 => {"name" => "i64.const", "immediate" => "varint64"},
    0x43 => {"name" => "f32.const", "immediate" => "uint32"},
    0x44 => {"name" => "f64.const", "immediate" => "uint64"},

    // Comparison operators
    0x45 => {"name" => "i32.eqz", "immediate" => ""},
    0x46 => {"name" => "i32.eq", "immediate" => ""},
    0x47 => {"name" => "i32.ne", "immediate" => ""},
    0x48 => {"name" => "i32.lt_s", "immediate" => ""},
    0x49 => {"name" => "i32.lt_u", "immediate" => ""},
    0x4a => {"name" => "i32.gt_s", "immediate" => ""},
    0x4b => {"name" => "i32.gt_u", "immediate" => ""},
    0x4c => {"name" => "i32.le_s", "immediate" => ""},
    0x4d => {"name" => "i32.le_u", "immediate" => ""},
    0x4e => {"name" => "i32.ge_s", "immediate" => ""},
    0x4f => {"name" => "i32.ge_u", "immediate" => ""},

    0x50 => {"name" => "i64.eqz", "immediate" => ""},
    0x51 => {"name" => "i64.eq", "immediate" => ""},
    0x52 => {"name" => "i64.ne", "immediate" => ""},
    0x53 => {"name" => "i64.lt_s", "immediate" => ""},
    0x54 => {"name" => "i64.lt_u", "immediate" => ""},
    0x55 => {"name" => "i64.gt_s", "immediate" => ""},
    0x56 => {"name" => "i64.gt_u", "immediate" => ""},
    0x57 => {"name" => "i64.le_s", "immediate" => ""},
    0x58 => {"name" => "i64.le_u", "immediate" => ""},
    0x59 => {"name" => "i64.ge_s", "immediate" => ""},
    0x5a => {"name" => "i64.ge_u", "immediate" => ""},

    0x5b => {"name" => "f32.eq", "immediate" => ""},
    0x5c => {"name" => "f32.ne", "immediate" => ""},
    0x5d => {"name" => "f32.lt", "immediate" => ""},
    0x5e => {"name" => "f32.gt", "immediate" => ""},
    0x5f => {"name" => "f32.le", "immediate" => ""},
    0x60 => {"name" => "f32.ge", "immediate" => ""},

    0x61 => {"name" => "f64.eq", "immediate" => ""},
    0x62 => {"name" => "f64.ne", "immediate" => ""},
    0x63 => {"name" => "f64.lt", "immediate" => ""},
    0x64 => {"name" => "f64.gt", "immediate" => ""},
    0x65 => {"name" => "f64.le", "immediate" => ""},
    0x66 => {"name" => "f64.ge", "immediate" => ""},

    // Numeric operators
    0x67 => {"name" => "i32.clz", "immediate" => ""},
    0x68 => {"name" => "i32.ctz", "immediate" => ""},
    0x69 => {"name" => "i32.popcnt", "immediate" => ""},
    0x6a => {"name" => "i32.add", "immediate" => ""},
    0x6b => {"name" => "i32.sub", "immediate" => ""},
    0x6c => {"name" => "i32.mul", "immediate" => ""},
    0x6d => {"name" => "i32.div_s", "immediate" => ""},
    0x6e => {"name" => "i32.div_u", "immediate" => ""},
    0x6f => {"name" => "i32.rem_s", "immediate" => ""},
    0x70 => {"name" => "i32.rem_u", "immediate" => ""},
    0x71 => {"name" => "i32.and", "immediate" => ""},
    0x72 => {"name" => "i32.or", "immediate" => ""},
    0x73 => {"name" => "i32.xor", "immediate" => ""},
    0x74 => {"name" => "i32.shl", "immediate" => ""},
    0x75 => {"name" => "i32.shr_s", "immediate" => ""},
    0x76 => {"name" => "i32.shr_u", "immediate" => ""},
    0x77 => {"name" => "i32.rotl", "immediate" => ""},
    0x78 => {"name" => "i32.rotr", "immediate" => ""},

    0x79 => {"name" => "i64.clz", "immediate" => ""},
    0x7a => {"name" => "i64.ctz", "immediate" => ""},
    0x7b => {"name" => "i64.popcnt", "immediate" => ""},
    0x7c => {"name" => "i64.add", "immediate" => ""},
    0x7d => {"name" => "i64.sub", "immediate" => ""},
    0x7e => {"name" => "i64.mul", "immediate" => ""},
    0x7f => {"name" => "i64.div_s", "immediate" => ""},
    0x80 => {"name" => "i64.div_u", "immediate" => ""},
    0x81 => {"name" => "i64.rem_s", "immediate" => ""},
    0x82 => {"name" => "i64.rem_u", "immediate" => ""},
    0x83 => {"name" => "i64.and", "immediate" => ""},
    0x84 => {"name" => "i64.or", "immediate" => ""},
    0x85 => {"name" => "i64.xor", "immediate" => ""},
    0x86 => {"name" => "i64.shl", "immediate" => ""},
    0x87 => {"name" => "i64.shr_s", "immediate" => ""},
    0x88 => {"name" => "i64.shr_u", "immediate" => ""},
    0x89 => {"name" => "i64.rotl", "immediate" => ""},
    0x8a => {"name" => "i64.rotr", "immediate" => ""},

    0x8b => {"name" => "f32.abs", "immediate" => ""},
    0x8c => {"name" => "f32.neg", "immediate" => ""},
    0x8d => {"name" => "f32.ceil", "immediate" => ""},
    0x8e => {"name" => "f32.floor", "immediate" => ""},
    0x8f => {"name" => "f32.trunc", "immediate" => ""},
    0x90 => {"name" => "f32.nearest", "immediate" => ""},
    0x91 => {"name" => "f32.sqrt", "immediate" => ""},
    0x92 => {"name" => "f32.add", "immediate" => ""},
    0x93 => {"name" => "f32.sub", "immediate" => ""},
    0x94 => {"name" => "f32.mul", "immediate" => ""},
    0x95 => {"name" => "f32.div", "immediate" => ""},
    0x96 => {"name" => "f32.min", "immediate" => ""},
    0x97 => {"name" => "f32.max", "immediate" => ""},
    0x98 => {"name" => "f32.copysign", "immediate" => ""},

    0x99 => {"name" => "f64.abs", "immediate" => ""},
    0x9a => {"name" => "f64.neg", "immediate" => ""},
    0x9b => {"name" => "f64.ceil", "immediate" => ""},
    0x9c => {"name" => "f64.floor", "immediate" => ""},
    0x9d => {"name" => "f64.trunc", "immediate" => ""},
    0x9e => {"name" => "f64.nearest", "immediate" => ""},
    0x9f => {"name" => "f64.sqrt", "immediate" => ""},
    0xa0 => {"name" => "f64.add", "immediate" => ""},
    0xa1 => {"name" => "f64.sub", "immediate" => ""},
    0xa2 => {"name" => "f64.mul", "immediate" => ""},
    0xa3 => {"name" => "f64.div", "immediate" => ""},
    0xa4 => {"name" => "f64.min", "immediate" => ""},
    0xa5 => {"name" => "f64.max", "immediate" => ""},
    0xa6 => {"name" => "f64.copysign", "immediate" => ""},

    // Conversions
    0xa7 => {"name" => "i32.wrap_i64", "immediate" => ""},
    0xa8 => {"name" => "i32.trunc_f32_s", "immediate" => ""},
    0xa9 => {"name" => "i32.trunc_f32_u", "immediate" => ""},
    0xaa => {"name" => "i32.trunc_f64_s", "immediate" => ""},
    0xab => {"name" => "i32.trunc_f64_u", "immediate" => ""},

    0xac => {"name" => "i64.extend_i32_s", "immediate" => ""},
    0xad => {"name" => "i64.extend_i32_u", "immediate" => ""},
    0xae => {"name" => "i64.trunc_f32_s", "immediate" => ""},
    0xaf => {"name" => "i64.trunc_f32_u", "immediate" => ""},
    0xb0 => {"name" => "i64.trunc_f64_s", "immediate" => ""},
    0xb1 => {"name" => "i64.trunc_f64_u", "immediate" => ""},

    0xb2 => {"name" => "f32.convert_i32_s", "immediate" => ""},
    0xb3 => {"name" => "f32.convert_i32_u", "immediate" => ""},
    0xb4 => {"name" => "f32.convert_i64_s", "immediate" => ""},
    0xb5 => {"name" => "f32.convert_i64_u", "immediate" => ""},
    0xb6 => {"name" => "f32.demote_f64", "immediate" => ""},

    0xb7 => {"name" => "f64.convert_i32_s", "immediate" => ""},
    0xb8 => {"name" => "f64.convert_i32_u", "immediate" => ""},
    0xb9 => {"name" => "f64.convert_i64_s", "immediate" => ""},
    0xba => {"name" => "f64.convert_i64_u", "immediate" => ""},
    0xbb => {"name" => "f64.promote_f32", "immediate" => ""},

    // Reinterpretations
    0xbc => {"name" => "i32.reinterpret_f32", "immediate" => ""},
    0xbd => {"name" => "i64.reinterpret_f64", "immediate" => ""},
    0xbe => {"name" => "f32.reinterpret_i32", "immediate" => ""},
    0xbf => {"name" => "f64.reinterpret_i64", "immediate" => ""}
};

var LOAD_SIZE as Dictionary<Number> = {
    0x28 => 4,
    0x29 => 8,
    0x2a => 4,
    0x2b => 8,
    0x2c => 1,
    0x2d => 1,
    0x2e => 2,
    0x2f => 2,
    0x30 => 1,
    0x31 => 1,
    0x32 => 2,
    0x33 => 2,
    0x34 => 4,
    0x35 => 4,
    0x36 => 4,
    0x37 => 8,
    0x38 => 4,
    0x39 => 8,
    0x3a => 1,
    0x3b => 2,
    0x3c => 1,
    0x3d => 2,
    0x3e => 4,
    0x40 => 1,
    0x41 => 2,
    0x42 => 1,
    0x43 => 2,
    0x44 => 4
};