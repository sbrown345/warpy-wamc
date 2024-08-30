import Toybox.Lang;
import Toybox.System;

const MAGIC as Number = 0x6d736100;
const VERSION as Number = 0x01;  // MVP

const STACK_SIZE as Number = 32; //65536;
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
    0x00 => ["unreachable", ""],
    0x01 => ["nop", ""],
    0x02 => ["block", "block_type"],
    0x03 => ["loop", "block_type"],
    0x04 => ["if", "block_type"],
    0x05 => ["else", ""],
    0x06 => ["RESERVED", ""],
    0x07 => ["RESERVED", ""],
    0x08 => ["RESERVED", ""],
    0x09 => ["RESERVED", ""],
    0x0a => ["RESERVED", ""],
    0x0b => ["end", ""],
    0x0c => ["br", "varuint32"],
    0x0d => ["br_if", "varuint32"],
    0x0e => ["br_table", "br_table"],
    0x0f => ["return", ""],

    // Call operators
    0x10 => ["call", "varuint32"],
    0x11 => ["call_indirect", "varuint32+varuint1"],

    0x12 => ["RESERVED", ""],
    0x13 => ["RESERVED", ""],
    0x14 => ["RESERVED", ""],
    0x15 => ["RESERVED", ""],
    0x16 => ["RESERVED", ""],
    0x17 => ["RESERVED", ""],
    0x18 => ["RESERVED", ""],
    0x19 => ["RESERVED", ""],

    // Parametric operators
    0x1a => ["drop", ""],
    0x1b => ["select", ""],

    0x1c => ["RESERVED", ""],
    0x1d => ["RESERVED", ""],
    0x1e => ["RESERVED", ""],
    0x1f => ["RESERVED", ""],

    // Variable access
    0x20 => ["get_local", "varuint32"],
    0x21 => ["set_local", "varuint32"],
    0x22 => ["tee_local", "varuint32"],
    0x23 => ["get_global", "varuint32"],
    0x24 => ["set_global", "varuint32"],

    0x25 => ["RESERVED", ""],
    0x26 => ["RESERVED", ""],
    0x27 => ["RESERVED", ""],

    // Memory-related operators
    0x28 => ["i32.load", "memory_immediate"],
    0x29 => ["i64.load", "memory_immediate"],
    0x2a => ["f32.load", "memory_immediate"],
    0x2b => ["f64.load", "memory_immediate"],
    0x2c => ["i32.load8_s", "memory_immediate"],
    0x2d => ["i32.load8_u", "memory_immediate"],
    0x2e => ["i32.load16_s", "memory_immediate"],
    0x2f => ["i32.load16_u", "memory_immediate"],
    0x30 => ["i64.load8_s", "memory_immediate"],
    0x31 => ["i64.load8_u", "memory_immediate"],
    0x32 => ["i64.load16_s", "memory_immediate"],
    0x33 => ["i64.load16_u", "memory_immediate"],
    0x34 => ["i64.load32_s", "memory_immediate"],
    0x35 => ["i64.load32_u", "memory_immediate"],
    0x36 => ["i32.store", "memory_immediate"],
    0x37 => ["i64.store", "memory_immediate"],
    0x38 => ["f32.store", "memory_immediate"],
    0x39 => ["f64.store", "memory_immediate"],
    0x3a => ["i32.store8", "memory_immediate"],
    0x3b => ["i32.store16", "memory_immediate"],
    0x3c => ["i64.store8", "memory_immediate"],
    0x3d => ["i64.store16", "memory_immediate"],
    0x3e => ["i64.store32", "memory_immediate"],
    0x3f => ["current_memory", "varuint1"],
    0x40 => ["grow_memory", "varuint1"],

    // Constants
    0x41 => ["i32.const", "varint32"],
    0x42 => ["i64.const", "varint64"],
    0x43 => ["f32.const", "uint32"],
    0x44 => ["f64.const", "uint64"],

    // Comparison operators
    0x45 => ["i32.eqz", ""],
    0x46 => ["i32.eq", ""],
    0x47 => ["i32.ne", ""],
    0x48 => ["i32.lt_s", ""],
    0x49 => ["i32.lt_u", ""],
    0x4a => ["i32.gt_s", ""],
    0x4b => ["i32.gt_u", ""],
    0x4c => ["i32.le_s", ""],
    0x4d => ["i32.le_u", ""],
    0x4e => ["i32.ge_s", ""],
    0x4f => ["i32.ge_u", ""],

    0x50 => ["i64.eqz", ""],
    0x51 => ["i64.eq", ""],
    0x52 => ["i64.ne", ""],
    0x53 => ["i64.lt_s", ""],
    0x54 => ["i64.lt_u", ""],
    0x55 => ["i64.gt_s", ""],
    0x56 => ["i64.gt_u", ""],
    0x57 => ["i64.le_s", ""],
    0x58 => ["i64.le_u", ""],
    0x59 => ["i64.ge_s", ""],
    0x5a => ["i64.ge_u", ""],

    0x5b => ["f32.eq", ""],
    0x5c => ["f32.ne", ""],
    0x5d => ["f32.lt", ""],
    0x5e => ["f32.gt", ""],
    0x5f => ["f32.le", ""],
    0x60 => ["f32.ge", ""],

    0x61 => ["f64.eq", ""],
    0x62 => ["f64.ne", ""],
    0x63 => ["f64.lt", ""],
    0x64 => ["f64.gt", ""],
    0x65 => ["f64.le", ""],
    0x66 => ["f64.ge", ""],

    // Numeric operators
    0x67 => ["i32.clz", ""],
    0x68 => ["i32.ctz", ""],
    0x69 => ["i32.popcnt", ""],
    0x6a => ["i32.add", ""],
    0x6b => ["i32.sub", ""],
    0x6c => ["i32.mul", ""],
    0x6d => ["i32.div_s", ""],
    0x6e => ["i32.div_u", ""],
    0x6f => ["i32.rem_s", ""],
    0x70 => ["i32.rem_u", ""],
    0x71 => ["i32.and", ""],
    0x72 => ["i32.or", ""],
    0x73 => ["i32.xor", ""],
    0x74 => ["i32.shl", ""],
    0x75 => ["i32.shr_s", ""],
    0x76 => ["i32.shr_u", ""],
    0x77 => ["i32.rotl", ""],
    0x78 => ["i32.rotr", ""],

    0x79 => ["i64.clz", ""],
    0x7a => ["i64.ctz", ""],
    0x7b => ["i64.popcnt", ""],
    0x7c => ["i64.add", ""],
    0x7d => ["i64.sub", ""],
    0x7e => ["i64.mul", ""],
    0x7f => ["i64.div_s", ""],
    0x80 => ["i64.div_u", ""],
    0x81 => ["i64.rem_s", ""],
    0x82 => ["i64.rem_u", ""],
    0x83 => ["i64.and", ""],
    0x84 => ["i64.or", ""],
    0x85 => ["i64.xor", ""],
    0x86 => ["i64.shl", ""],
    0x87 => ["i64.shr_s", ""],
    0x88 => ["i64.shr_u", ""],
    0x89 => ["i64.rotl", ""],
    0x8a => ["i64.rotr", ""],

    0x8b => ["f32.abs", ""],
    0x8c => ["f32.neg", ""],
    0x8d => ["f32.ceil", ""],
    0x8e => ["f32.floor", ""],
    0x8f => ["f32.trunc", ""],
    0x90 => ["f32.nearest", ""],
    0x91 => ["f32.sqrt", ""],
    0x92 => ["f32.add", ""],
    0x93 => ["f32.sub", ""],
    0x94 => ["f32.mul", ""],
    0x95 => ["f32.div", ""],
    0x96 => ["f32.min", ""],
    0x97 => ["f32.max", ""],
    0x98 => ["f32.copysign", ""],

    0x99 => ["f64.abs", ""],
    0x9a => ["f64.neg", ""],
    0x9b => ["f64.ceil", ""],
    0x9c => ["f64.floor", ""],
    0x9d => ["f64.trunc", ""],
    0x9e => ["f64.nearest", ""],
    0x9f => ["f64.sqrt", ""],
    0xa0 => ["f64.add", ""],
    0xa1 => ["f64.sub", ""],
    0xa2 => ["f64.mul", ""],
    0xa3 => ["f64.div", ""],
    0xa4 => ["f64.min", ""],
    0xa5 => ["f64.max", ""],
    0xa6 => ["f64.copysign", ""],

    // Conversions
    0xa7 => ["i32.wrap_i64", ""],
    0xa8 => ["i32.trunc_f32_s", ""],
    0xa9 => ["i32.trunc_f32_u", ""],
    0xaa => ["i32.trunc_f64_s", ""],
    0xab => ["i32.trunc_f64_u", ""],

    0xac => ["i64.extend_i32_s", ""],
    0xad => ["i64.extend_i32_u", ""],
    0xae => ["i64.trunc_f32_s", ""],
    0xaf => ["i64.trunc_f32_u", ""],
    0xb0 => ["i64.trunc_f64_s", ""],
    0xb1 => ["i64.trunc_f64_u", ""],

    0xb2 => ["f32.convert_i32_s", ""],
    0xb3 => ["f32.convert_i32_u", ""],
    0xb4 => ["f32.convert_i64_s", ""],
    0xb5 => ["f32.convert_i64_u", ""],
    0xb6 => ["f32.demote_f64", ""],

    0xb7 => ["f64.convert_i32_s", ""],
    0xb8 => ["f64.convert_i32_u", ""],
    0xb9 => ["f64.convert_i64_s", ""],
    0xba => ["f64.convert_i64_u", ""],
    0xbb => ["f64.promote_f32", ""],

    // Reinterpretations
    0xbc => ["i32.reinterpret_f32", ""],
    0xbd => ["i64.reinterpret_f64", ""],
    0xbe => ["f32.reinterpret_i32", ""],
    0xbf => ["f64.reinterpret_i64", ""]
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