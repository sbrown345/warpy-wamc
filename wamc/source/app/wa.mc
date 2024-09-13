import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;

typedef ImportMethodType as Method(module_ as Module, field as String) as Array<Number>;
typedef ImportFunctionType as Method(module_ as Module, field as String, mem as Memory, args as Array<Array<Number>>) as Array<Array<Number>>;
typedef StackType as Array<Array<Number>>;
typedef CallStackType as Array<Array<Number or Block or Function>>;
typedef Global as ValueTupleType;
typedef ValueTupleType as [Types, Number, Float];

// var INFO  = false; // informational logging
// var TRACE = false; // trace instructions/stacks
// var DEBUG = false; // verbose logging
var INFO  = true;
var TRACE = true;
var DEBUG = true;
var VALIDATE = true;

function createNaN() as Float {
    var bytes = new [4]b;
    bytes[0] = 0x00;
    bytes[1] = 0x00;
    bytes[2] = 0xC0;
    bytes[3] = 0x7F;
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
}

function createPositiveInfinity() as Float {
    var bytes = new [4]b;
    bytes[0] = 0x00;
    bytes[1] = 0x00;
    bytes[2] = 0x80;
    bytes[3] = 0x7F;
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
}

function createNegativeInfinity() as Float {
    var bytes = new [4]b;
    bytes[0] = 0x00;
    bytes[1] = 0x00;
    bytes[2] = 0x80;
    bytes[3] = 0xFF;
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
}

function do_sort(a as Array) as Array {
    return a.sort(null);
}

var packing_temp = new [8]b;

function unpack_f32(i32 as Number) as Float {
    packing_temp.encodeNumber(i32, Lang.NUMBER_FORMAT_SINT32, { :offset => 0 });
    return packing_temp.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
}

function unpack_f64(i64 as Long) as Double {
    return bitsToDouble(i64);
    // var low = (i64 & 0xFFFFFFFF).toNumber();
    // var high = ((i64 >> 32) & 0xFFFFFFFF).toNumber();
    
    // // Combine low and high into a single float
    // // This will lose precision but is much simpler
    // return low.toFloat() + high.toFloat() * 4294967296.0; // 2^32
}

function pack_f32(f32 as Float) as Number {
    packing_temp.encodeNumber(f32, Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
    return packing_temp.decodeNumber(Lang.NUMBER_FORMAT_SINT32, { :offset => 0 });
}

function pack_f64(f64 as Double) as Long {
    return doubleToBits(f64);
    // var high = Math.floor(f64 / 4294967296.0); // 2^32
    // var low = f64 - (high * 4294967296.0);
    // return (high.toLong() << 32) | (low.toLong() & 0xFFFFFFFF);
}

function bitsToDouble(bits as Long) as Double {
    if (bits == 0 || bits == 0x8000000000000000L) {
        return bits == 0 ? 0.0d : -0.0d;
    }

    var sign = ((bits >> 63) & 1) == 0 ? 1 : -1;
    var exponent = ((bits >> 52) & 0x7FF).toNumber() - 1023;
    var fraction = bits & 0xFFFFFFFFFFFFFL;

    if (exponent == 1024) {
        if (fraction == 0) {
            return sign < 0 ? createNegativeInfinity() : createPositiveInfinity();
        } else {
            return createNaN();
        }
    }

    var result;
    if (exponent == -1023) {
        // Subnormal number
        result = fraction.toDouble() / 4503599627370496.0d * Math.pow(2, -1022);
    } else {
        result = (1.0d + fraction.toDouble() / 4503599627370496.0d) * Math.pow(2, exponent);
    }

    return sign * result;
}

function doubleToBits(d as Double) as Long {
    if (d == 0) {
        return d < 0 ? 0x8000000000000000L : 0;
    } else if (isNaN(d)) {
        return 0x7FF8000000000000L;
    } else if (isInfinite(d)) {
        return d < 0 ? 0xFFF0000000000000L : 0x7FF0000000000000L;
    }

    var sign = d < 0 ? 1L : 0L;
    d = d.abs();
    var exponent = Math.floor(Math.log(d, 2)).toNumber();
    var fraction = d / Math.pow(2, exponent) - 1;

    exponent += 1023; // Bias

    if (exponent <= 0) {
        // Subnormal number
        fraction = d / Math.pow(2, -1022);
        exponent = 0;
    } else if (exponent >= 0x7FF) {
        // Overflow to infinity
        return sign == 1 ? 0xFFF0000000000000L : 0x7FF0000000000000L;
    }

    var bits = (sign << 63) | ((exponent.toLong() & 0x7FF) << 52) | ((fraction * (1L << 52)).toLong() & 0xFFFFFFFFFFFFFL);
    return bits;
}

// function pack_f64(f64 as Double) as Long {
//     packing_temp.encodeNumber(f64, Lang.NUMBER_FORMAT_DOUBLE, { :offset => 0 });
//     var low = packing_temp.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => 0 });
//     var high = packing_temp.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => 4 });
//     return (high.toLong() << 32) | low.toLong();
// }

// function pack_f64(f64 as Float) as Long {
//     packing_temp.encodeNumber(f64.toFloat(), Lang.NUMBER_FORMAT_FLOAT, { :offset => 0 });
//     var low = packing_temp.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => 0 });
//     var high = packing_temp.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => 4 });
//     return (high.toLong() << 32) | low.toLong();
// }


// function unpack_f64(i64 as Long) as Float {
//     var bytes = new [8]b;
//     for (var i = 0; i < 8; i++) {
//         bytes[i] = ((i64 >> (i * 8)) & 0xFF).toNumber();
//     }
    
//     // Extract sign, exponent, and fraction
//     var sign = (bytes[7] & 0x80) != 0 ? -1 : 1;
//     var exponent = ((bytes[7] & 0x7F) << 4) | ((bytes[6] & 0xF0) >> 4);
//     var fraction = 0.0;
    
//     // Calculate fraction
//     for (var i = 0; i < 6; i++) {
//         fraction += bytes[i] * Math.pow(2, -48 + (i * 8));
//     }
//     fraction += (bytes[6] & 0x0F) * Math.pow(2, -4);
    
//     // Handle special cases
//     if (exponent == 0) {
//         if (fraction == 0.0) {
//             return sign * 0.0; // Zero
//         } else {
//             return sign * fraction * Math.pow(2, -1022); // Subnormal
//         }
//     } else if (exponent == 0x7FF) {
//         if (fraction == 0.0) {
//             return sign * Float.INFINITY; // Infinity
//         } else {
//             return Float.NaN; // NaN
//         }
//     }
    
//     // Normal number
//     return sign * (1.0 + fraction) * Math.pow(2, exponent - 1023);
// }

// function pack_f64(f64 as Float) as Long {
//     var bytes = new [8]b;
    
//     if (f64 == 0.0) {
//         return 0; // Positive or negative zero
//     } else if (f64.isNaN()) {
//         return 0x7FF8000000000000; // NaN
//     } else if (!f64.isFinite()) {
//         return f64 < 0 ? 0xFFF0000000000000 : 0x7FF0000000000000; // Infinity
//     }
    
//     var sign = f64 < 0 ? 1 : 0;
//     f64 = f64.abs();
//     var exponent = Math.floor(Math.log(f64, 2));
//     var fraction = f64 / Math.pow(2, exponent) - 1;
    
//     exponent += 1023; // Bias
    
//     if (exponent <= 0) {
//         // Subnormal number
//         fraction = fraction * Math.pow(2, exponent);
//         exponent = 0;
//     } else if (exponent >= 0x7FF) {
//         // Overflow to infinity
//         return sign == 1 ? 0xFFF0000000000000 : 0x7FF0000000000000;
//     }
    
//     // Pack the bytes
//     bytes[7] = (sign << 7) | ((exponent >> 4) & 0x7F);
//     bytes[6] = ((exponent & 0x0F) << 4) | ((fraction * 16) & 0x0F);
//     for (var i = 5; i >= 0; i--) {
//         fraction *= 256;
//         bytes[i] = fraction & 0xFF;
//         fraction -= bytes[i];
//     }
    
//     // Convert bytes to Long
//     var result = 0L;
//     for (var i = 0; i < 8; i++) {
//         result |= (bytes[i].toLong() << (i * 8));
//     }
//     return result;
// }


function intmask(i) {return i;}

function string_to_int(s as String, base as Number) as Number {
    return s.toNumberWithBase(base);
}

function fround(val, digits) {
    var multiplier = Math.pow(10, digits);
    return Math.round(val * multiplier) / multiplier;
}

function float_fromhex(s) {
    System.println("float_fromhex: " + s);
    throw new NotImplementedException();
}

function compareValueType(a as ValueTupleType, b as ValueTupleType) as Boolean {
    if (!(a instanceof Array) || !(b instanceof Array)) {
        System.println("compareValueType: One or both arguments are not arrays");
        return false;
    }

    if (a.size() != 3 || b.size() != 3) {
        System.println("compareValueType: One or both arrays do not have exactly 3 elements");
        return false;
    }

    if (a[0] != b[0]) {
        System.println("compareValueType: Types do not match. a[0]: " + a[0] + ", b[0]: " + b[0]);
        return false;
    }

    if (a[1] != b[1]) {
        System.println("compareValueType: Integer values do not match. a[1]: " + a[1] + ", b[1]: " + b[1]);
        return false;
    }

    if (a[2] != b[2]) {
        System.println("compareValueType: Float values do not match. a[2]: " + a[2] + ", b[2]: " + b[2]);
        return false;
    }

    return true;
}

function assertEqual(expected as ValueTupleType, actual as ValueTupleType) as Boolean {
    if (compareValueType(expected, actual)) {
        return true;
    } else {
        System.println("Assertion failed: expected " + expected + ", but got " + actual);
        return false;
    }
}

function assertTrap(expectedAssertMessage as String, actual as Exception) as Boolean {
    if (!(actual instanceof WAException)) {
        return false;
    }
    if (!actual.toString().equals(expectedAssertMessage)) {
        System.println("Wrong trap message: " + actual + ", expected: " + expectedAssertMessage);
        return false;
    }
    
    return true;
}
function i32(x) { return [I32, x.toNumber(), 0.0]; }
function i64(x) { return [I64, x.toLong(), 0.0]; }
function f32(x) { return [F32, 0, x.toFloat()]; }
function f64(x) { return [F64, 0, x.toDouble()]; }

// ######################################
// # Basic low-level types/classes
// ######################################

class NotImplementedException extends Lang.Exception {
    function initialize() {
        Lang.Exception.initialize();
    }
}
class WAException extends Lang.Exception {
    function initialize(message as String) {
        Lang.Exception.initialize();
        self.mMessage = message;
    }

    function toString() as String {
        return self.mMessage;
    }
}

class ExitException extends Lang.Exception {
    public var code as Number;

    function initialize(code as Number) {
        Lang.Exception.initialize();
        self.code = code;
        self.mMessage = "Exit Exception Code:" + code;
    }
}



class Type {
    public var index as Number;
    public var form as Number;
    public var params as Array<Number>;
    public var results as Array<Number>;
    public var mask as Long;

    function initialize(index as Number, form as Number, params as Array<Number>, results as Array<Number>, mask as Long?) {
        self.index = index;
        self.form = form;
        self.params = params;
        self.results = results;
        self.mask = mask == null ? 0x80 : mask; // default was 0x80 but it wanted to parse the mask
    }

    function toString() as String {
        return "Type(index: " + self.index + ", form: " + self.form + ", params: " + self.params + ", results: " + self.results + ", mask: " + self.mask + ")";
    }
}

class Code {
}

class Block extends Code {
    public var kind as Number;
    public var type as Type;
    public var locals as Array<Number>;
    public var start as Number;
    public var end as Number;
    public var elseAddr as Number;
    public var brAddr as Number;

    function initialize(kind as Number, type as Type, start as Number, end as Number, elseAddr as Number, brAddr as Number) {
        self.kind = kind; // block opcode (0x00 for init_expr)
        self.type = type; // value_type
        self.locals = [];
        self.start = start;
        self.end = end;
        self.elseAddr = elseAddr;
        self.brAddr = brAddr;
    }

    function update(end as Number, brAddr as Number) as Void {
        self.end = end;
        self.brAddr = brAddr;
    }

    function toString() as String {
        return "Block(kind: " + self.kind + ", type: " + self.type + ", start: " + self.start + ", end: " + self.end + ", elseAddr: " + self.elseAddr + ", brAddr: " + self.brAddr + ")";
    }
}

class Function extends Code {
    public var type as Type;
    public var index as Number;
    public var locals as Array<Number>;
    public var start as Number;
    public var end as Number;
    public var elseAddr as Number;
    public var brAddr as Number;

    function initialize(type as Type, index as Number, locals as Array<Number>, start as Number, end as Number, elseAddr as Number, brAddr as Number) {
        self.type = type; // value_type
        self.index = index;
        self.locals = locals;
        self.start = start;
        self.end = end;
        self.elseAddr = elseAddr;
        self.brAddr = brAddr;
    }
    
    function toString() as String {
        return "Function(type: " + self.type + ", index: " + self.index + ", start: " + self.start + ", end: " + self.end + ", elseAddr: " + self.elseAddr + ", brAddr: " + self.brAddr + ")";
    }
}

class FunctionImport extends Code {
    public var type as Type;
    public var module_ as String;
    public var field as String;

    function initialize(type as Type, module_ as String, field as String) {
        self.type = type;  // value_type
        self.module_ = module_;
        self.field = field;
    }

    function toString() as String {
        return "FunctionImport(type: " + self.type + ", module: '" + self.module_ + "', field: '" + self.field + "')";
    }
}


// ####################################
// WebAssembly spec data
// ####################################

const MAGIC as Number = 0x6d736100;
const VERSION as Number = 0x01;  // MVP

const STACK_SIZE as Number = 512; //65536;
const CALLSTACK_SIZE as Number = 512; //8192;

enum Types {
    I32     = 0x7f,  // -0x01
    I64     = 0x7e,  // -0x02
    F32     = 0x7d,  // -0x03
    F64     = 0x7c   // -0x04
}
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
var BLOCK_TYPE as Dictionary<Number, Type> = {
    I32 => new Type(-1, BLOCK, [], [I32], null),
    I64 => new Type(-1, BLOCK, [], [I64], null),
    F32 => new Type(-1, BLOCK, [], [F32], null),
    F64 => new Type(-1, BLOCK, [], [F64], null),
    BLOCK => new Type(-1, BLOCK, [], [], null)
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


// ####################################
// General Functions
// ####################################


function assert(condition as Boolean, message as String) as Void {
    if (!condition) {
        if (message == null) {
            message = "Assertion failed";
        }
        throw new WAException(message);
    }
}


function info(str) {
    if (INFO) {
        System.println(str);
    }
}

function infoWithEnd(str, end) {
    if (INFO) {
        if (end == null) {
            end = "\n";
        }
        System.println(str + end);
    }
}

function debug(str) {
    if (DEBUG) {
        System.println(str);
    }
}

function debugWithEnd(str, end) {
    if (DEBUG) {
        if (end == null) {
            end = "\n";
        }
        System.println(str + end);
    }
}

function join(arr as Array<String>, sep as String) as String {
    if (arr.size() == 0) {
        return "";
    }
    var res = arr[0];
    for (var i = 1; i < arr.size(); i++) {
        res += sep + arr[i];
    }
    return res;
}

function replaceString(original as String, oldSubstring as String, newSubstring as String) as String {
    var result = "";
    var index = original.find(oldSubstring);
    
    while (index != null) {
        result += original.substring(0, index) + newSubstring;
        original = original.substring(index + oldSubstring.length(), original.length());
        index = original.find(oldSubstring);
    }
    
    result += original;
    return result;
}

// math functions

// https://forums.garmin.com/developer/connect-iq/f/discussion/338071/testing-for-nan/1777041#1777041
const FLT_MAX = 3.4028235e38;

function isNaN(x as Float) as Boolean {
    return x != x;
}

function isInfinite(x as Float) as Boolean {
    return (x < -FLT_MAX || FLT_MAX < x);
}


function unpack_nan32(i32) { throw new NotImplementedException(); }
// def unpack_nan32(i32):
//     return struct.unpack('f', struct.pack('I', i32))[0]

function unpack_nan64(i64) { throw new NotImplementedException(); }
// def unpack_nan64(i64):
//     return struct.unpack('d', struct.pack('Q', i64))[0]

function parse_nan(type, arg) {
    if (type == F32) {
        return unpack_nan32(0x7fc00000);
    } else {
        return unpack_nan64(0x7ff8000000000000l);
    }
}

function parse_number(type, arg) as ValueTupleType {
    arg = replaceString(arg, "_", "");
    var v;
    if (type == I32) {
        if (arg.find("0x") != null) {
            v = [I32, string_to_int(arg, 16), 0.0];
        } else if (arg.find("-0x") != null) {
            v = [I32, string_to_int(arg, 16), 0.0];
        } else {
            v = [I32, string_to_int(arg, 10), 0.0];
        }
    } else if (type == I64) {
        if (arg.find("0x") != null) {
            v = [I64, string_to_int(arg, 16), 0.0];
        } else if (arg.find("-0x") != null) {
            v = [I64, string_to_int(arg, 16), 0.0];
        } else {
            v = [I64, string_to_int(arg, 10), 0.0];
        }
    } else if (type == F32) {
        if (arg.find("nan") != null) {
            v = [F32, 0, parse_nan(type, arg)];
        } else if (arg.find("inf") != null) {
            v = [F32, 0, float_fromhex(arg)];
        } else if (arg.find("0x") != null) {
            v = [F32, 0, float_fromhex(arg)];
        } else if (arg.find("-0x") != null) {
            v = [F32, 0, float_fromhex(arg)];
        } else {
            v = [F32, 0, arg.toFloat()];
        }
    } else if (type == F64) {
        if (arg.find("nan") != null) {
            v = [F64, 0, parse_nan(type, arg)];
        } else if (arg.find("inf") != null) {
            v = [F64, 0, float_fromhex(arg)];
        } else if (arg.find("0x") != null) {
            v = [F64, 0, float_fromhex(arg)];
        } else if (arg.find("-0x") != null) {
            v = [F64, 0, float_fromhex(arg)];
        } else {
            v = [F64, 0, arg.toDouble()];
        }
    } else {
        throw new WAException("invalid number " + arg);
    }
    return v;
}

// Integer division that rounds towards 0 (like C)
function idiv_s(a, b) {
    return (a * b > 0) ? (a / b) : (a + (-a % b)) / b;
}

function irem_s(a, b) {
    return (a * b > 0) ? (a % b) : -(-a % b);
}


//

function rotl32(a, cnt) {
    return ((a << (cnt % 0x20)) & 0xffffffff) | (a >> (0x20 - (cnt % 0x20)));
}

function rotr32(a as Number, cnt as Number) as Number {
    var n = a;
    var c = cnt % 32;
    for (var i = 0; i < c; i++) {
        var lowBit = n & 0x1;
        n = (n >> 1) & 0x7FFFFFFF;  // Shift right and clear the sign bit
        if (lowBit) {
            n |= 0x80000000;  // Set the highest bit if the lowest bit was 1
        }
    }
    return n;
}


function rotl64(a, cnt) {
    return ((a << (cnt % 0x40)) & 0xffffffffffffffffl) | (a >> (0x40 - (cnt % 0x40)));
}

function rotr64(a, cnt) {
    return (a >> (cnt % 0x40)) | ((a << (0x40 - (cnt % 0x40))) & 0xffffffffffffffffl);
}

function bytes2uint8(b) {
    return b[0];
}

function bytes2int8(b) {
    var val = b[0];
    return (val & 0x80) ? (val - 0x100) : val;
}

//

function bytes2uint16(b) {
    return (b[1] << 8) + b[0];
}

function bytes2int16(b) {
    var val = (b[1] << 8) + b[0];
    return (val & 0x8000) ? (val - 0x10000) : val;
}

function bytes2uint32(b) {
    return (b[3] << 24) + (b[2] << 16) + (b[1] << 8) + b[0];
}

function uint322bytes(v) {
    return [
        0xff & v,
        0xff & (v >> 8),
        0xff & (v >> 16),
        0xff & (v >> 24)
    ];
}

function bytes2int32(b) {
    var val = (b[3] << 24) + (b[2] << 16) + (b[1] << 8) + b[0];
    return (val & 0x80000000) ? (val - 0x100000000l) : val;
}

function int2uint32(i as Number) as Long {
    if (i < 0) {
        return (i.toLong() + 0x100000000L) & 0xffffffffL;
    } else {
        return i.toLong() & 0xffffffffL;
    }
}

function int2int32(i) {
    // var val = i & 0xffffffff;
    // return (val & 0x80000000) ? (val - 0x100000000) : val;
    var val = i.toNumber() & 0xffffffff;
    return (val & 0x80000000) ? (val | (~0xffffffff)) : val;
}

//

function uint642bytes(v as Long) as Array<Number> {
    if(!(v instanceof Long)) {
        System.println("uint642bytes: input is not a Long");
        v = v.toLong();
    }
    var result = [
        (v & 0xff).toNumber(),
        ((v >> 8) & 0xff).toNumber(),
        ((v >> 16) & 0xff).toNumber(),
        ((v >> 24) & 0xff).toNumber(),
        ((v >> 32) & 0xff).toNumber(),
        ((v >> 40) & 0xff).toNumber(),
        ((v >> 48) & 0xff).toNumber(),
        ((v >> 56) & 0xff).toNumber()
    ];
    // System.println("uint642bytes: input=" + v + ", output=" + result);
    return result;
}

function bytes2uint64(b as ByteArray) as Long {
    var result = (b[7].toLong() << 56) |
           (b[6].toLong() << 48) |
           (b[5].toLong() << 40) |
           (b[4].toLong() << 32) |
           (b[3].toLong() << 24) |
           (b[2].toLong() << 16) |
           (b[1].toLong() << 8) |
           b[0].toLong();
    // System.println("bytes2uint64: input=" + b + ", output=" + result);
    if(!(result instanceof Long)) {
        System.println("bytes2uint64: result is not a Long");
        result = result.toLong();
    }
    return result;
}

function bytes2int64(b) {
    throw new NotImplementedException();
    // var val = ((b[7] << 56) + (b[6] << 48) + (b[5] << 40) + (b[4] << 32) +
    //         (b[3] << 24) + (b[2] << 16) + (b[1] << 8) + b[0]);
    // return (val & 0x8000000000000000l) ? (val - 0x10000000000000000l) : val;
}

//

function int2uint64(i) {
    return i & 0xffffffffffffffffl;
}

function int2int64(i) {
    return i.toLong();
}

// https://en.wikipedia.org/wiki/LEB128
function read_LEB(bytes, pos, maxbits/*=32*/, signed/*=false*/) as [Number, Number or Long] {
    var result = 0L;
    var shift = 0;
    var bcnt = 0;
    var startpos = pos;

    if (maxbits == null) {
        maxbits = 32;
    }

    if (signed == null) {
        signed = false; 
    }

    var byte = 0;
    while (true) {
        byte = bytes[pos];
        pos += 1;
        result |= ((byte & 0x7f).toLong() << shift);
        shift += 7;
        if ((byte & 0x80) == 0) {
            break;
        }
        bcnt += 1;
        if (bcnt > Math.ceil(maxbits / 7.0)) {
            throw new Exception("Unsigned LEB at byte " + startpos + " overflow");
        }
    }
    if (signed && (shift < maxbits) && (byte & 0x40)) {
        result |= ((-1L) << shift);
    }

    // Convert result to Number if maxbits <= 32, otherwise keep it as Long
    var finalResult = (maxbits <= 32) ? result.toNumber() : result;

    return [pos, finalResult];
}

function read_I32(bytes, pos) {
    assert(pos >= 0, null);
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
}

// function read_I64(bytes as ByteArray, pos as Number) as Long {
//     assert(pos >= 0, null);
//     var slice = bytes.slice(pos, pos + 8);
//     System.println("read_I64: pos=" + pos + ", slice=" + slice);
//     return bytes2uint64(slice);
// }

function read_I64(bytes as ByteArray, pos as Number) as Long {
    assert(pos >= 0, null);
    var low = bytes.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => pos });
    var high = bytes.decodeNumber(Lang.NUMBER_FORMAT_UINT32, { :offset => pos + 4 });
    
    var result = (high.toLong() << 32) | (low.toLong() & 0xFFFFFFFF);
    
    // System.println("read_I64: pos=" + pos + ", low=" + low + ", high=" + high + ", result=" + result);
    return result;
}

function read_F32(bytes, pos) {
    assert(pos >= 0, null);
    var num = bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
    if (isNaN(num)) {return num; }
    return fround(num, 5);
}

function read_F64(bytes as ByteArray, pos as Number) as Float {
    assert(pos >= 0, null);
    var long_value = read_I64(bytes, pos);
    return bitsToDouble(long_value);
}

function write_I32(bytes as ByteArray, pos as Number, ival as Number) as Void {
    bytes.encodeNumber(ival, Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
}


// function write_I64(bytes as ByteArray, pos as Number, ival as Long) as Void {
//     System.println("write_I64: pos=" + pos + ", ival=" + ival);
    
//     var byteArray = uint642bytes(ival);
    
//     for (var i = 0; i < 8; i++) {
//         bytes[pos + i] = byteArray[i];
//     }

//     System.println("write_I64: Bytes written: " + bytes.slice(pos, pos + 8));

//     var num = read_I64(bytes, pos);
//     System.println("write_I64: Wrote " + ival + ", read back " + num);
// }

function write_I64(bytes as ByteArray, pos as Number, ival as Long) as Void {
    ival = ival.toLong();

    if (TRACE) {
        System.println("write_I64: pos=" + pos + ", ival=" + ival);
    }
    
    var low = ival.toNumber() & 0xFFFFFFFF;
    var high = (ival >> 32).toNumber() & 0xFFFFFFFF;
    
    bytes.encodeNumber(low, Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
    bytes.encodeNumber(high, Lang.NUMBER_FORMAT_SINT32, { :offset => pos + 4 });


    var readBack = read_I64(bytes, pos);
    if (readBack != ival) {
        System.println("write_I64: Bytes written: " + bytes.slice(pos, pos + 8));
        System.println("write_I64: Wrote " + ival + ", read back " + readBack);
        throw new WAException("write_I64: Wrote " + ival + ", read back " + readBack);
    }
}

function write_F32(bytes as ByteArray, pos as Number, fval as Float) as Void {
    bytes.encodeNumber(fval, Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
}

// function write_F64(bytes as ByteArray, pos as Number, fval as Float) as Void {
//     // Method 1: Split and encode
//     var high = Math.floor(fval / 4294967296.0).toNumber(); // 2^32
//     var low = (fval - (high * 4294967296.0)).toNumber();

//     bytes.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, { :offset => pos });
//     bytes.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, { :offset => pos + 4 });

//     // Method 2: Direct encoding (if available)
//     bytes.encodeNumber(fval, Lang.NUMBER_FORMAT_DOUBLE, { :offset => pos + 8 });

//     // Log the bytes written
//     System.println("Bytes written (Method 1):");
//     for (var i = 0; i < 8; i++) {
//         System.print(bytes[pos + i].format("%02X") + " ");
//     }
//     System.println("");

//     System.println("Bytes written (Method 2):");
//     for (var i = 0; i < 8; i++) {
//         System.print(bytes[pos + 8 + i].format("%02X") + " ");
//     }
//     System.println("");

//     // Read and log results
//     var i64_result1 = read_I64(bytes, pos);
//     var f64_result1 = read_F64(bytes, pos);
//     var i64_result2 = read_I64(bytes, pos + 8);
//     var f64_result2 = read_F64(bytes, pos + 8);

//     System.println("Method 1 - read_I64: " + i64_result1);
//     System.println("Method 1 - read_F64: " + f64_result1);
//     System.println("Method 2 - read_I64: " + i64_result2);
//     System.println("Method 2 - read_F64: " + f64_result2);
// }

function write_F64(bytes as ByteArray, pos as Number, fval as Float) as Void {
    var bits = doubleToBits(fval);
    var low = (bits & 0xFFFFFFFF).toNumber();
    var high = ((bits >> 32) & 0xFFFFFFFF).toNumber();

    bytes.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, { :offset => pos });
    bytes.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, { :offset => pos + 4 });

        // if (TRACE) {
        //     System.println("write_F64: Original value: " + fval + " isNaN:" + isNaN(fval) + " isInfinite:" + isInfinite(fval));
        //     System.println("Bytes written:");
        //     for (var i = 0; i < 8; i++) {
        //         System.print(bytes[pos + i].format("%02X") + " ");
        //     }
        //     System.println("");

        //     var long_value = read_I64(bytes, pos);
        //     var result = bitsToDouble(long_value);
        //     System.println("Read back value: " + result + " isNaN:" + isNaN(result) + " isInfinite:" + isInfinite(result));
        // }
}

// function write_F64(bytes as ByteArray, pos as Number, fval as Float) as Void {
//     // Split the float into two 32-bit parts
//     var high = Math.floor(fval / 4294967296.0).toNumber(); // 2^32
//     var low = (fval - (high * 4294967296.0)).toNumber();

//     // Encode the low 32 bits
//     bytes.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, { :offset => pos });

//     // Encode the high 32 bits
//     bytes.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, { :offset => pos + 4 });
// }


function value_repr(val as Array) as String {
    var vt = val[0];
    var ival = val[1];
    var fval = val[2];
    var vtn = VALUE_TYPE[vt];
    
    if (vtn.equals("i32")) {
        var unsignedVal;
        if (ival instanceof Long) {
            unsignedVal = ival & 0xFFFFFFFFL;
            throw new WAException("unexpected long: " + ival);
        } else {
            unsignedVal = ival < 0 ? (ival.toLong() + 4294967296L) : ival.toLong();
        }
        return Lang.format("$1$:$2$", [unsignedVal.toString(), vtn]);
    } else if (vtn.equals("i64")) {
        return Lang.format("$1$:$2$", [ival.toString(), vtn]);
    } else if (vtn.equals("f32") || vtn.equals("f64")) {
        return Lang.format("$1$:$2$", [fval.format("%.7f"), vtn]);
    } else {
        throw new WAException("unknown value type " + vtn);
    }
}

function type_repr(t as Type) as String {
    var params = [];
    for (var i = 0; i < t.params.size(); i++) {
        params.add("'" + VALUE_TYPE[t.params[i]] + "'");
    }
    var results = [];
    for (var i = 0; i < t.results.size(); i++) {
        results.add("'" + VALUE_TYPE[t.results[i]] + "'");
    }
    return "<index: " + t.index + ", form: " + VALUE_TYPE[t.form] + 
           ", params: " + params + ", results: " + results + 
           ", mask: 0x" + t.mask.format("%x") + ">";
}

function export_repr(e as Export) as String {
    return "<kind: " + EXTERNAL_KIND_NAMES[e.kind] + ", field: '" + e.field + "', index: 0x" + e.index.format("%x") + ">";
}

function funcRepr(f as FunctionImport or Function) as String {
    if (f instanceof FunctionImport) {
        return "<type: 0x" + f.type.index.format("%x") + ", import: '" + f.module_ + "." + f.field + "'>";
    } else if (f instanceof Function) {
        var localTypes = [];
        for (var i = 0; i < f.locals.size(); i++) {
            localTypes.add("'" + VALUE_TYPE[f.locals[i]] + "'");
        }
        return "<type: 0x" + f.type.index.format("%x") + ", locals: " + localTypes + ", start: 0x" + f.start.format("%x") + ", end: 0x" + f.end.format("%x") + ">";
    } else {
        return "Unknown function type";
    }
}

function blockRepr(block as Block or Function) as String {
    if (block instanceof Block) {
        return Lang.format("$1$<0/0->$2$>", [
            BLOCK_NAMES[block.kind],
            block.type.results.size()
        ]);
    } else if (block instanceof Function) {
        return Lang.format("fn$1$<$2$/$3$->$4$>", [
            block.index,
            block.type.params.size(),
            block.locals.size(),
            block.type.results.size()
        ]);
    } else {
        System.println("Unknown block type: " + block);
        return "Unknown block type";
    }
}

function stackRepr(sp as Number, fp as Number, stack as Array) as String {
    var res = [];
    for (var i = 0; i <= sp; i++) {
        if (i == fp) {
            res.add("*");
        }
        res.add(value_repr(stack[i]));
    }
    return "[" + join(res, " ") + "]";
}

function callstackRepr(csp as Number, bs as Array) as String {
    var callstackEntries = [];
    for (var i = 0; i <= csp; i++) {
        var entry = bs[i];
        var blockReprStr = blockRepr(entry[0]);
        var spStr = entry[1].toString();
        var fpStr = entry[2].toString();
        var raStr = "0x" + entry[3].format("%x");
        callstackEntries.add(Lang.format("$1$(sp:$2$/fp:$3$/ra:$4$)", [blockReprStr, spStr, fpStr, raStr]));
    }
    return "[" + join(callstackEntries, " ") + "]";
}

function dump_stacks(sp as Number, stack as Array, fp as Number, csp as Number, callstack as Array) as Void {
    debug("      * stack:     " + stackRepr(sp, fp, stack));
    debug("      * callstack: " + callstackRepr(csp, callstack));
}

function byteCodeRepr(bytes as ByteArray) as String {
    var size = bytes.size();
    if (size == 0) {
        return "[]";
    }
    
    var result = "[" + bytes[0].format("%x");
    for (var i = 1; i < size; i++) {
        result += "," + bytes[i].format("%x");
    }
    return result + "]";
}

function skipImmediates(code as ByteArray, pos as Number) as Array<Number> {
    var opcode = code[pos];
    pos += 1;
    var vals = [];
    var imtype = OPERATOR_INFO[opcode][1];
    if (imtype.equals("varuint1")) {
        var result = read_LEB(code, pos,  1, null);
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("varint32") || imtype.equals("varuint32")) {
        var result = read_LEB(code, pos,  32, null);
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("varuint32+varuint1")) {
        var result = read_LEB(code, pos,  32, null);
        pos = result[0];
        vals.add(result[1]);
        result = read_LEB(code, pos,  1, null);
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("varint64") || imtype.equals("varuint64")) {
        var result = read_LEB(code, pos,  64, null);
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("uint32")) {
        vals.add(read_F32(code, pos));
        pos += 4;
    } else if (imtype.equals("uint64")) {
        vals.add(read_F64(code, pos));
        pos += 8;
    } else if (imtype.equals("block_type")) {
        var result = read_LEB(code, pos,  7, null);  // block type signature
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("memory_immediate")) {
        var result = read_LEB(code, pos,  32, null);  // flags
        pos = result[0];
        vals.add(result[1]);
        result = read_LEB(code, pos,  32, null);  // offset
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("br_table")) {
        var result = read_LEB(code, pos,  32, null);  // target count
        pos = result[0];
        var count = result[1];
        vals.add(count);
        for (var i = 0; i < count; i++) {
            result = read_LEB(code, pos,  32, null);  // target
            pos = result[0];
            vals.add(result[1]);
        }
        result = read_LEB(code, pos,  32, null);  // default target
        pos = result[0];
        vals.add(result[1]);
    } else if (imtype.equals("")) {
        // no immediates
    } else {
        throw new Exception("unknown immediate type " + imtype);
    }
    return [pos, vals];
}

// def find_blocks(code, start, end, block_map):
//     pos = start

//     # stack of blocks with current at top: (opcode, pos) tuples
//     opstack = []

//     #
//     # Build the map of blocks
//     #
//     opcode = 0
//     while pos <= end:
//         opcode = code[pos]
//         #debug("0x%x: %s, opstack: %s" % (
//         #    pos, OPERATOR_INFO[opcode][0],
//         #    ["%d,%s,0x%x" % (o,s.index,p) for o,s,p in opstack]))
//         if   0x02 <= opcode <= 0x04:  # block, loop, if
//             block = Block(opcode, BLOCK_TYPE[code[pos+1]], pos)
//             opstack.append(block)
//             block_map[pos] = block
//         elif 0x05 == opcode:  # mark else positions
//             assert opstack[-1].kind == 0x04, "else not matched with if"
//             opstack[-1].else_addr = pos+1
//         elif 0x0b == opcode:  # end
//             if pos == end: break
//             block = opstack.pop()
//             if block.kind == 0x03:  # loop: label after start
//                 block.update(pos, block.start+2)
//             else:  # block/if: label at end
//                 block.update(pos, pos)
//         pos, _ = skip_immediates(code, pos)

//     assert opcode == 0xb, "function block did not end with 0xb"
//     assert len(opstack) == 0, "function ended in middle of block"

//     #debug("block_map: %s" % block_map)
//     return block_map

function popBlock(stack as StackType, callstack as CallStackType, sp as Number, fp as Number, csp as Number) as Array {
    var block = callstack[csp][0];
    var origSp = callstack[csp][1];
    var origFp = callstack[csp][2];
    var ra = callstack[csp][3];
    csp -= 1;
    var t = block.type;

    // Validate return value if there is one
    if (VALIDATE) {
        if (t.results.size() > 1) {
            throw new WAException("multiple return values unimplemented");
        }
        if (t.results.size() > sp + 1) {
            throw new WAException("stack underflow");
        }
    }

    if (t.results.size() == 1) {
        // Restore main value stack, saving top return value
        var save = stack[sp];
        sp -= 1;
        if (save[0] != t.results[0]) {
            throw new WAException("call signature mismatch: " + VALUE_TYPE[t.results[0]] + " != " + VALUE_TYPE[save[0]] + " (" + value_repr(save) + ")");
        }

        // Restore value stack to original size prior to call/block
        if (origSp < sp) {
            sp = origSp;
        }

        // Put back return value if we have one
        sp += 1;
        stack[sp] = save;
    } else {
        // Restore value stack to original size prior to call/block
        if (origSp < sp) {
            sp = origSp;
        }
    }

    return [block, ra, sp, origFp, csp];
}


function do_call(stack as StackType, callstack as CallStackType, sp as Number, fp as Number, csp as Number, func as Function, pc as Number, indirect as Boolean) as Array<Number> {
    // Push block, stack size and return address onto callstack
    var t = func.type;
    if (TRACE) {
        System.println("do_call: Setting return address to 0x" + pc.format("%x"));
    }
    csp += 1;
    callstack[csp] = [func, sp - t.params.size(), fp, pc];

    // Update the pos/instruction counter to the function
    pc = func.start;
    System.println("do_call: pc: 0x" + pc.format("%x"));

    if (TRACE) {
        info(Lang.format("  Calling function 0x$1$, start: 0x$2$, end: 0x$3$, $4$ locals, $5$ params, $6$ results",
            [func.index.format("%x"), func.start.format("%x"), func.end.format("%x"),
             func.locals.size(), t.params.size(), t.results.size()]));
    }

    // set frame pointer to include parameters
    fp = sp - t.params.size() + 1;

    // push locals (dropping extras)
    for (var lidx = 0; lidx < func.locals.size(); lidx++) {
        var ltype = func.locals[lidx];
        sp += 1;
        stack[sp] = [ltype, 0, 0.0];
    }

    return [pc, sp, fp, csp];
}

function do_callImport(stack as StackType, sp as Number, memory as Memory, importFunction as ImportFunctionType, func as FunctionImport) as Number {
    var t = func.type;

    var args = [] as ValueTupleType;
    var idx;
    for (idx = t.params.size() - 1; idx >= 0; idx--) {
        var arg = stack[sp];
        sp -= 1;
        args.add(arg);
    }

    // if (VALIDATE) {
    //     // make sure args match type signature
    //     for (var idx = 0; idx < t.params.size(); idx++) {
    //         var ptype = t.params[idx];
    //         if (ptype != args[idx][0]) {
    //             throw new WAException("call signature mismatch: " + VALUE_TYPE[ptype] + " != " + VALUE_TYPE[args[idx][0]]);
    //         }
    //     }
    // }

    args = args.reverse();
    var results = importFunction.invoke(func.module_, func.field, memory, args);

    // make sure returns match type signature
    for (idx = 0; idx < t.results.size(); idx++) {
        if (idx < results.size()) {
            var res = results[idx];
            if (t.results[idx] != res[0]) {
                throw new WAException("return signature mismatch");
            }
            sp += 1;
            stack[sp] = res;
        } else {
            throw new WAException("return signature mismatch");
        }
    }

    return sp;
}


// Main loop/JIT



function get_location_str(opcode as Number, pc as Number, code as Array<Number>, function_ as Array, table as Dictionary, block_map as Dictionary) as String {
    return "0x" + pc.format("%x") + " " + OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ")";
}

function get_block(block_map as Dictionary, pc as Number) as Block {
    return block_map[pc];
}

function get_function(function_ as Array, fidx as Number) as Function {
    return function_[fidx];
}

function bound_violation(opcode as Number, addr as Number, pages as Number) as Boolean {
    return addr < 0 || addr + LOAD_SIZE[opcode] > pages * (1 << 16);
}

function get_from_table(table as Dictionary, tidx as Number, tableIndex as Number) as Number {
    var tbl = table[tidx] as Array<Number>;
    if (tableIndex < 0 || tableIndex >= tbl.size()) {
        throw new WAException("undefined element");
    }
    return tbl[tableIndex];
}

function interpret_mvp(module_, 
        // greens
        pc, code, function_, table, block_map, 
        // reds
        memory, sp, stack, fp, csp, callstack
    ) as [Number, Number, Number, Number] {

    var operation_count = 0;

    while (pc < code.size()) {
        if (operation_count > 1000) {
            throw new WAException("max operation_count");
        }

        if (module_.maxAsyncOperations != -1 && operation_count > module_.maxAsyncOperations) {
            return [pc, sp, fp, csp];
        }

        var opcode = code[pc];
        var curPc = pc;
        pc += 1;

        operation_count++;

        if (TRACE) {
            info("operation_count: " + operation_count);
            dump_stacks(sp, stack, fp, csp, callstack);
            var immediates = skipImmediates(code, curPc)[1];
            var immediateParts = [];
            for (var i = 0; i < immediates.size(); i++) {
                if (immediates[i] instanceof Float or immediates[i] instanceof Double) {
                    if (immediates[i].toNumber() == immediates[i]) {
                        immediateParts.add(immediates[i].format("%d"));
                    } else {
                        immediateParts.add(immediates[i].format("%.7f"));
                    }
                } else {
                    immediateParts.add("0x" + immediates[i].format("%x"));
                }
            }
            info("    0x" + curPc.format("%x") + " <0x" + opcode.format("%x") + "/" + OPERATOR_INFO[opcode][0] +
                 (immediates.size() > 0 ? " " : "") +
                 join(immediateParts, ",") + ">");
        }

        // Control flow operators
        if (opcode == 0x00) {  // unreachable
            throw new WAException("unreachable");
        } else if (opcode == 0x01) {  // nop
            // Do nothing
        } else if (opcode == 0x02) {  // block
            var blockType = read_LEB(code, pc,  32, null);
            pc = blockType[0];
            var block = get_block(block_map, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            if (TRACE) { debug("      - block: " + blockRepr(block)); }
        } else if (opcode == 0x03) {  // loop
            var blockType = read_LEB(code, pc,  32, null);
            pc = blockType[0];
            var block = get_block(block_map, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            if (TRACE) { debug("      - block: " + blockRepr(block)); }
        } else if (opcode == 0x04) {  // if
            var blockType = read_LEB(code, pc,  32, null);
            pc = blockType[0];
            var block = get_block(block_map, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            var cond = stack[sp];
            sp -= 1;
            if (!(cond[1] == 1)) {  // if false (I32)
                // branch to else block or after end of if
                if (block.elseAddr == 0) {
                    // no else block so pop if block and skip end
                    csp -= 1;
                    pc = block.brAddr + 1;
                } else {
                    pc = block.elseAddr;
                }
            }
            if (TRACE) {
                debug("      - cond: " + value_repr(cond) + " jump to 0x" + pc.format("%x") + ", block: " + blockRepr(block));
            }
        } else if (opcode == 0x05) {  // else
            var block = callstack[csp][0];
            pc = block.brAddr;
            if (TRACE) {
                debug("      - of " + blockRepr(block) + " jump to 0x" + pc.format("%x"));
            }
        } else if (opcode == 0x0b) {  // end
            var popResult = popBlock(stack, callstack, sp, fp, csp);
            var block = popResult[0];
            var ra = popResult[1];
            sp = popResult[2];
            fp = popResult[3];
            csp = popResult[4];
            if (TRACE) { debug("      - of " + blockRepr(block)); }
            if (block instanceof Function) {
                // Return to return address
                pc = ra;
                if (csp == -1) {
                    // Return to top-level, ignoring return_addr
                    return [pc, sp, fp, csp];
                } else {
                    if (TRACE) {
                        info("  Returning from function 0x" + block.index.format("%x") + " to 0x" + pc.format("%x"));
                    }
                }
            } else if (block instanceof Block && block.kind == 0x00) {
                // this is an init_expr
                return [pc, sp, fp, csp];
            }
            // else: end of block/loop/if, keep going
        } else if (opcode == 0x0c) {  // br
            var brDepth = read_LEB(code, pc,  32, null);
            pc = brDepth[0];
            csp -= brDepth[1];
            var block = callstack[csp][0];
            pc = block.brAddr; // set to end for pop_block
            if (TRACE) { debug("      - to: 0x" + pc.format("%x")); }
        } else if (opcode == 0x0d) {  // br_if
            var brDepth = read_LEB(code, pc,  32, null);
            pc = brDepth[0];
            var cond = stack[sp];
            sp -= 1;
            if (cond[1] == 1) {  // I32
                csp -= brDepth[1];
                var block = callstack[csp][0];
                pc = block.brAddr; // set to end for pop_block
            }
            if (TRACE) {
                debug("      - cond: " + cond[1] + ", to: 0x" + pc.format("%x"));
            }
        } else if (opcode == 0x0e) {  // br_table
            var targetCount = read_LEB(code, pc,  32, null);
            pc = targetCount[0];
            var depths = [];
            for (var c = 0; c < targetCount[1]; c++) {
                var depth = read_LEB(code, pc,  32, null);
                pc = depth[0];
                depths.add(depth[1]);
            }
            var brDepth = read_LEB(code, pc,  32, null);
            pc = brDepth[0];
            var expr = stack[sp];
            sp -= 1;
            if (VALIDATE) { assert(expr[0] == I32, "Expected I32"); }
            var didx = expr[1];  // I32
            if (didx >= 0 && didx < depths.size()) {
                brDepth[1] = depths[didx];
            }
            csp -= brDepth[1];
            var block = callstack[csp][0];
            pc = block.brAddr; // set to end for pop_block
            if (TRACE) {
                debug("      - depths: " + depths + ", didx: " + didx + ", to: 0x" + pc.format("%x"));
            }
        } else if (opcode == 0x0f) {  // return
            // Pop blocks until reach Function signature
            while (csp >= 0) {
                if (callstack[csp][0] instanceof Function) { break; }
                // We don't use pop_block because the end opcode
                // handler will do this for us and catch the return
                // value properly.
                csp -= 1;
            }
            if (VALIDATE) { assert(csp >= 0, "Call stack underflow"); }
            var block = callstack[csp][0];
            if (VALIDATE) { assert(block instanceof Function, "Expected Function"); }
            // Set instruction pointer to end of function
            // The actual pop_block and return is handled by handling
            // the end opcode
            pc = block.end;
            if (TRACE) { debug("      - to 0x" + pc.format("%x")); }
        }

        // Call operators
        else if (opcode == 0x10) {  // call
            var fidx = read_LEB(code, pc,  32, null);
            pc = fidx[0];
            var func = get_function(function_, fidx[1]);

            if (func instanceof FunctionImport) {
                var t = func.type;
                if (TRACE) {
                    var paramTypes = [];
                    for (var i = 0; i < t.params.size(); i++) {
                        paramTypes.add(VALUE_TYPE[t.params[i]]);
                    }
                    debug("      - calling import " + func.module_ + "." + func.field + "(" +
                          join(paramTypes, ",") + ")");
                }
                sp = do_callImport(stack, sp, memory, module_.importFunction, func);
            } else if (func instanceof Function) {
                var callResult = do_call(stack, callstack, sp, fp, csp, func, pc, false);
                pc = callResult[0];
                sp = callResult[1];
                fp = callResult[2];
                csp = callResult[3];
                if (TRACE) { debug("      - calling function fidx: " + fidx[1] + " at: 0x" + pc.format("%x")); }
            }
        } else if (opcode == 0x11) {  // call_indirect
            var tidx = read_LEB(code, pc,  32, null);
            pc = tidx[0];
            var reserved = read_LEB(code, pc,  1, null);
            pc = reserved[0];
            var typeIndexVal = stack[sp];
            sp -= 1;
            if (VALIDATE) { assert(typeIndexVal[0] == I32, "Expected I32"); }
            var tableIndex = typeIndexVal[1];  // I32
            var fidx = get_from_table(table, ANYFUNC, tableIndex);
            if (VALIDATE) { assert(csp < CALLSTACK_SIZE, "call stack exhausted"); }
            var func = get_function(function_, fidx);
            if (VALIDATE && func.type.mask != module_.type[tidx[1]].mask) {
                throw new WAException("indirect call type mismatch (call type " + func.type.index + " and function type " + tidx[1] + " differ");
            }
            var callResult = do_call(stack, callstack, sp, fp, csp, func, pc, true);
            pc = callResult[0];
            sp = callResult[1];
            fp = callResult[2];
            csp = callResult[3];
            if (TRACE) {
                debug("      - table idx: 0x" + tableIndex.format("%x") + ", tidx: 0x" + tidx[1].format("%x") +
                      ", calling function fidx: 0x" + fidx.format("%x") + " at 0x" + pc.format("%x"));
            }
        }

        // Parametric operators
        else if (opcode == 0x1a) {  // drop
            if (TRACE) { debug("      - dropping: " + value_repr(stack[sp])); }
            sp -= 1;
        } else if (opcode == 0x1b) {  // select
            var cond = stack[sp];
            var a = stack[sp-1];
            var b = stack[sp-2];
            sp -= 2;
            if (cond[1] == 1) {  // I32
                stack[sp] = b;
            } else {
                stack[sp] = a;
            }
            if (TRACE) {
                debug("      - cond: 0x" + cond[1].format("%x") + ", selected: " + value_repr(stack[sp]));
            }
        }

        // Variable access
        else if (opcode == 0x20) {  // get_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            sp += 1;
            stack[sp] = stack[fp+arg[1]];
            if (TRACE) { debug("      - got " + value_repr(stack[sp])); }
        } else if (opcode == 0x21) {  // set_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            var val = stack[sp];
            sp -= 1;
            stack[fp+arg[1]] = val;
            if (TRACE) { debug("      - to " + value_repr(val)); }
        } else if (opcode == 0x22) {  // tee_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            var val = stack[sp]; // like set_local but do not pop
            stack[fp+arg[1]] = val;
            if (TRACE) { debug("      - to " + value_repr(val)); }
        } else if (opcode == 0x23) {  // get_global
            var gidx = read_LEB(code, pc,  32, null);
            pc = gidx[0];
            sp += 1;
            stack[sp] = module_.globalList[gidx[1]];
            if (TRACE) { debug("      - got " + value_repr(stack[sp])); }
        } else if (opcode == 0x24) {  // set_global
            var gidx = read_LEB(code, pc,  32, null);
            pc = gidx[0];
            var val = stack[sp];
            sp -= 1;
            module_.globalList[gidx[1]] = val;
            if (TRACE) { debug("      - to " + value_repr(val)); }
        }

        // Memory-related operators

        // Memory load operators

        else if (0x28 <= opcode && opcode <= 0x35) {
            var flags = read_LEB(code, pc, 32, null);
            pc = flags[0];
            var offset = read_LEB(code, pc, 32, null);
            pc = offset[0];
            var addr_val = stack[sp];
            sp -= 1;
            if (flags[1] != 2) {
                if (TRACE) {
                    info("      - unaligned load - flags: 0x" + flags[1].format("%x") +
                         ", offset: 0x" + offset[1].format("%x") + ", addr: 0x" + addr_val[1].format("%x"));
                }
            }
            var addr = addr_val[1] + offset[1];
            if (bound_violation(opcode, addr, memory.pages)) {
                throw new WAException("out of bounds memory access");
            }
            assert(addr >= 0, null);
            var res;
            // TODO: USE byteArray.decodeNumber(format, options)
            if (opcode == 0x28) {  // i32.load
                res = [I32, bytes2uint32(memory.bytes.slice(addr, addr+4)), 0.0];
            } else if (opcode == 0x29) {  // i64.load
                res = [I64, bytes2uint64(memory.bytes.slice(addr, addr+8)), 0.0];
            } else if (opcode == 0x2a) {  // f32.load
                res = [F32, 0, read_F32(memory.bytes, addr)];
            } else if (opcode == 0x2b) {  // f64.load
                res = [F64, 0, read_F64(memory.bytes, addr)];
            } else if (opcode == 0x2c) {  // i32.load8_s
                res = [I32, bytes2int8(memory.bytes.slice(addr, addr+1)), 0.0];
            } else if (opcode == 0x2d) {  // i32.load8_u
                res = [I32, memory.bytes[addr], 0.0];
            } else if (opcode == 0x2e) {  // i32.load16_s
                res = [I32, bytes2int16(memory.bytes.slice(addr, addr+2)), 0.0];
            } else if (opcode == 0x2f) {  // i32.load16_u
                res = [I32, bytes2uint16(memory.bytes.slice(addr, addr+2)), 0.0];
            } else if (opcode == 0x30) {  // i64.load8_s
                res = [I64, bytes2int8(memory.bytes.slice(addr, addr+1)), 0.0];
            } else if (opcode == 0x31) {  // i64.load8_u
                res = [I64, memory.bytes[addr], 0.0];
            } else if (opcode == 0x32) {  // i64.load16_s
                res = [I64, bytes2int16(memory.bytes.slice(addr, addr+2)), 0.0];
            } else if (opcode == 0x33) {  // i64.load16_u
                res = [I64, bytes2uint16(memory.bytes.slice(addr, addr+2)), 0.0];
            } else if (opcode == 0x34) {  // i64.load32_s
                res = [I64, bytes2int32(memory.bytes.slice(addr, addr+4)), 0.0];
            } else if (opcode == 0x35) {  // i64.load32_u
                res = [I64, bytes2uint32(memory.bytes.slice(addr, addr+4)), 0.0];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            sp += 1;
            stack[sp] = res;
            if (TRACE) {
                debug("Memory load: addr=" + addr + ", value=" + value_repr(res));
            }
        }

        // Memory store operators
        else if (0x36 <= opcode && opcode <= 0x3e) {
            var flags = read_LEB(code, pc, 32, null);
            pc = flags[0];
            var offset = read_LEB(code, pc, 32, null);
            pc = offset[0];
            var val = stack[sp];
            sp -= 1;
            var addr_val = stack[sp];
            sp -= 1;
            if (flags[1] != 2) {
                if (TRACE) {
                    info("      - unaligned store - flags: 0x" + flags[1].format("%x") +
                         ", offset: 0x" + offset[1].format("%x") + ", addr: 0x" + addr_val[1].format("%x") +
                         ", val: 0x" + val[1].format("%x"));
                }
            }
            var addr = addr_val[1] + offset[1];
            if (bound_violation(opcode, addr, memory.pages)) {
                throw new WAException("out of bounds memory access");
            }
            assert(addr >= 0, null);
            if (opcode == 0x36) {  // i32.store
                write_I32(memory.bytes, addr, val[1]);
            } else if (opcode == 0x37) {  // i64.store
                write_I64(memory.bytes, addr, val[1]);
            } else if (opcode == 0x38) {  // f32.store
                write_F32(memory.bytes, addr, val[2]);
            } else if (opcode == 0x39) {  // f64.store
                write_F64(memory.bytes, addr, val[2]);
            } else if (opcode == 0x3a) {  // i32.store8
                memory.bytes[addr] = val[1] & 0xff;
            } else if (opcode == 0x3b) {  // i32.store16
                memory.bytes[addr] = val[1] & 0x00ff;
                memory.bytes[addr+1] = (val[1] & 0xff00) >> 8;
            } else if (opcode == 0x3c) {  // i64.store8
                memory.bytes[addr] = val[1] & 0xff;
            } else if (opcode == 0x3d) {  // i64.store16
                memory.bytes[addr] = val[1] & 0x00ff;
                memory.bytes[addr+1] = (val[1] & 0xff00) >> 8;
            } else if (opcode == 0x3e) {  // i64.store32
                memory.bytes[addr] = val[1] & 0x000000ff;
                memory.bytes[addr+1] = (val[1] & 0x0000ff00) >> 8;
                memory.bytes[addr+2] = (val[1] & 0x00ff0000) >> 16;
                memory.bytes[addr+3] = (val[1] & 0xff000000) >> 24;
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }

            if (TRACE) {
                debug("Memory store: addr=" + addr.toString() + ", value=" + value_repr(val));
            }
        }

        // Memory size operators
        else if (opcode == 0x3f) {  // current_memory
            var reserved = read_LEB(code, pc, 1, null);
            pc = reserved[0];
            sp += 1;
            stack[sp] = [I32, module_.memory.pages, 0.0];
            if (TRACE) {
                debug("      - current 0x" + module_.memory.pages.format("%x"));
            }
        } else if (opcode == 0x40) {  // grow_memory
            var reserved = read_LEB(code, pc, 1, null);
            pc = reserved[0];
            var prev_size = module_.memory.pages;
            var delta = stack[sp][1];  // I32
            module_.memory.grow(delta);
            stack[sp] = [I32, prev_size, 0.0];
            debug("      - delta 0x" + delta.format("%x") + ", prev: 0x" + prev_size.format("%x"));
        }


        //
        // Constants
        //
        else if (opcode == 0x41) {  // i32.const
            var result = read_LEB(code, pc, 32, true);
            pc = result[0];
            var val = result[1];
            sp += 1;
            stack[sp] = [I32, val, 0.0];
            if (TRACE) {
                debug("      - " + value_repr(stack[sp]));
            }
        } else if (opcode == 0x42) {  // i64.const
            var result = read_LEB(code, pc, 64, true);
            pc = result[0];
            var val = result[1];
            sp += 1;
            if(!(val instanceof Long)) {
                System.println("i64.const: val is not a Long");
                val = val.toLong();
            }
            stack[sp] = [I64, val, 0.0];
            if (TRACE) {
                debug("      - " + value_repr(stack[sp]));
            }
        } else if (opcode == 0x43) {  // f32.const
            sp += 1;
            stack[sp] = [F32, 0, read_F32(code, pc)];
            pc += 4;
            if (TRACE) {
                debug("      - " + value_repr(stack[sp]));
            }
        } else if (opcode == 0x44) {  // f64.const
            sp += 1;
            stack[sp] = [F64, 0, read_F64(code, pc)];
            pc += 8;
            if (TRACE) {
                debug("      - " + value_repr(stack[sp]));
            }
        }

        //
        // Comparison operators
        //

        // unary
       else if (opcode == 0x45 || opcode == 0x50) {
            var a = stack[sp];
            sp -= 1;
            var res;
            if (opcode == 0x45) { // i32.eqz
                if (VALIDATE) {
                    assert(a[0] == I32, "Expected I32");
                }
                res = [I32, a[1] == 0 ? 1 : 0, 0.0];
            } else { // i64.eqz
                if (VALIDATE) {
                    assert(a[0] == I64, "Expected I64");
                }
                res = [I32, a[1] == 0 ? 1 : 0, 0.0];
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        }
        // binary
        else if (0x46 <= opcode && opcode <= 0x66) {
            var a = stack[sp-1];
            var b = stack[sp];
            sp -= 2;
            var res;
            if (0x46 == opcode) { // i32.eq
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, a[1] == b[1] ? 1 : 0, 0.0];
            } else if (0x47 == opcode) { // i32.ne
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, a[1] != b[1] ? 1 : 0, 0.0];
            } else if (0x48 == opcode) { // i32.lt_s
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2int32(a[1]) < int2int32(b[1]) ? 1 : 0, 0.0];
            } else if (0x49 == opcode) { // i32.lt_u
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2uint32(a[1]) < int2uint32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4a == opcode) { // i32.gt_s
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2int32(a[1]) > int2int32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4b == opcode) { // i32.gt_u
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2uint32(a[1]) > int2uint32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4c == opcode) { // i32.le_s
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2int32(a[1]) <= int2int32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4d == opcode) { // i32.le_u
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2uint32(a[1]) <= int2uint32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4e == opcode) { // i32.ge_s
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2int32(a[1]) >= int2int32(b[1]) ? 1 : 0, 0.0];
            } else if (0x4f == opcode) { // i32.ge_u
                if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, null); }
                res = [I32, int2uint32(a[1]) >= int2uint32(b[1]) ? 1 : 0, 0.0];
            } else if (0x51 == opcode) { // i64.eq
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, a[1] == b[1] ? 1 : 0, 0.0];
            } else if (0x52 == opcode) { // i64.ne
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, a[1] != b[1] ? 1 : 0, 0.0];
            } else if (0x53 == opcode) { // i64.lt_s
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2int64(a[1]) < int2int64(b[1]) ? 1 : 0, 0.0];
            } else if (0x54 == opcode) { // i64.lt_u
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2uint64(a[1]) < int2uint64(b[1]) ? 1 : 0, 0.0];
            } else if (0x55 == opcode) { // i64.gt_s
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2int64(a[1]) > int2int64(b[1]) ? 1 : 0, 0.0];
            } else if (0x56 == opcode) { // i64.gt_u
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2uint64(a[1]) > int2uint64(b[1]) ? 1 : 0, 0.0];
            } else if (0x57 == opcode) { // i64.le_s
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2int64(a[1]) <= int2int64(b[1]) ? 1 : 0, 0.0];
            } else if (0x58 == opcode) { // i64.le_u
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2uint64(a[1]) <= int2uint64(b[1]) ? 1 : 0, 0.0];
            } else if (0x59 == opcode) { // i64.ge_s
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2int64(a[1]) >= int2int64(b[1]) ? 1 : 0, 0.0];
            } else if (0x5a == opcode) { // i64.ge_u
                if (VALIDATE) { assert(a[0] == I64 && b[0] == I64, null); }
                res = [I32, int2uint64(a[1]) >= int2uint64(b[1]) ? 1 : 0, 0.0];
            } else if (0x5b == opcode) { // f32.eq
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] == b[2] ? 1 : 0, 0.0];
            } else if (0x5c == opcode) { // f32.ne
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] != b[2] ? 1 : 0, 0.0];
            } else if (0x5d == opcode) { // f32.lt
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] < b[2] ? 1 : 0, 0.0];
            } else if (0x5e == opcode) { // f32.gt
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] > b[2] ? 1 : 0, 0.0];
            } else if (0x5f == opcode) { // f32.le
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] <= b[2] ? 1 : 0, 0.0];
            } else if (0x60 == opcode) { // f32.ge
                if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
                res = [I32, a[2] >= b[2] ? 1 : 0, 0.0];
            } else if (0x61 == opcode) { // f64.eq
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] == b[2] ? 1 : 0, 0.0];
            } else if (0x62 == opcode) { // f64.ne
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] != b[2] ? 1 : 0, 0.0];
            } else if (0x63 == opcode) { // f64.lt
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] < b[2] ? 1 : 0, 0.0];
            } else if (0x64 == opcode) { // f64.gt
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] > b[2] ? 1 : 0, 0.0];
            } else if (0x65 == opcode) { // f64.le
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] <= b[2] ? 1 : 0, 0.0];
            } else if (0x66 == opcode) { // f64.ge
                if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
                res = [I32, a[2] >= b[2] ? 1 : 0, 0.0];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ", " + value_repr(b) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        }

//         #
//         # Numeric operators
//         #

//         # unary
//         elif opcode in [0x67, 0x68, 0x69, 0x79, 0x7a, 0x7b, 0x8b,
//                         0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x99,
//                         0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f]:
//             a = stack[sp]
//             sp -= 1
//             if   0x67 == opcode: # i32.clz
//                 if VALIDATE: assert a[0] == I32
//                 count = 0
//                 val = a[1]
//                 while count < 32 and (val & 0x80000000) == 0:
//                     count += 1
//                     val = val * 2
//                 res = (I32, count, 0.0)
//             elif 0x68 == opcode: # i32.ctz
//                 if VALIDATE: assert a[0] == I32
//                 count = 0
//                 val = a[1]
//                 while count < 32 and (val % 2) == 0:
//                     count += 1
//                     val = val / 2
//                 res = (I32, count, 0.0)
//             elif 0x69 == opcode: # i32.popcnt
//                 if VALIDATE: assert a[0] == I32
//                 count = 0
//                 val = a[1]
//                 for i in range(32):
//                     if 0x1 & val:
//                         count += 1
//                     val = val / 2
//                 res = (I32, count, 0.0)
//             elif 0x79 == opcode: # i64.clz
//                 if VALIDATE: assert a[0] == I64
//                 val = a[1]
//                 if val < 0:
//                     res = (I64, 0, 0.0)
//                 else:
//                     count = 1
//                     while count < 64 and (val & 0x4000000000000000) == 0:
//                         count += 1
//                         val = val * 2
//                     res = (I64, count, 0.0)
//             elif 0x7a == opcode: # i64.ctz
//                 if VALIDATE: assert a[0] == I64
//                 count = 0
//                 val = a[1]
//                 while count < 64 and (val % 2) == 0:
//                     count += 1
//                     val = val / 2
//                 res = (I64, count, 0.0)
//             elif 0x7b == opcode: # i64.popcnt
//                 if VALIDATE: assert a[0] == I64
//                 count = 0
//                 val = a[1]
//                 for i in range(64):
//                     if 0x1 & val:
//                         count += 1
//                     val = val / 2
//                 res = (I64, count, 0.0)
//             elif 0x8b == opcode: # f32.abs
//                 if VALIDATE: assert a[0] == F32
//                 res = (F32, 0, abs(a[2]))
//             elif 0x8c == opcode: # f32.neg
//                 if VALIDATE: assert a[0] == F32
//                 res = (F32, 0, -a[2])
//             elif 0x8d == opcode: # f32.ceil
//                 if VALIDATE: assert a[0] == F32
//                 res = (F32, 0, math.ceil(a[2]))
//             elif 0x8e == opcode: # f32.floor
//                 if VALIDATE: assert a[0] == F32
//                 res = (F32, 0, math.floor(a[2]))
//             elif 0x8f == opcode: # f32.trunc
//                 if VALIDATE: assert a[0] == F32
//                 if math.isinf(a[2]):
//                     res = (F32, 0, a[2])
//                 elif a[2] > 0:
//                     res = (F32, 0, math.floor(a[2]))
//                 else:
//                     res = (F32, 0, math.ceil(a[2]))
//             elif 0x90 == opcode: # f32.nearest
//                 if VALIDATE: assert a[0] == F32
//                 if a[2] <= 0.0:
//                     res = (F32, 0, math.ceil(a[2]))
//                 else:
//                     res = (F32, 0, math.floor(a[2]))
//             elif 0x91 == opcode: # f32.sqrt
//                 if VALIDATE: assert a[0] == F32
//                 res = (F32, 0, math.sqrt(a[2]))
//             elif 0x99 == opcode: # f64.abs
//                 if VALIDATE: assert a[0] == F64
//                 res = (F64, 0, abs(a[2]))
//             elif  0x9a == opcode: # f64.neg
//                 if VALIDATE: assert a[0] == F64
//                 res = (F64, 0, -a[2])
//             elif 0x9b == opcode: # f64.ceil
//                 if VALIDATE: assert a[0] == F64
//                 res = (F64, 0, math.ceil(a[2]))
//             elif 0x9c == opcode: # f64.floor
//                 if VALIDATE: assert a[0] == F64
//                 res = (F64, 0, math.floor(a[2]))
//             elif 0x9d == opcode: # f64.trunc
//                 if VALIDATE: assert a[0] == F64
//                 if math.isinf(a[2]):
//                     res = (F64, 0, a[2])
//                 elif a[2] > 0:
//                     res = (F64, 0, math.floor(a[2]))
//                 else:
//                     res = (F64, 0, math.ceil(a[2]))
//             elif 0x9e == opcode: # f64.nearest
//                 if VALIDATE: assert a[0] == F64
//                 if a[2] <= 0.0:
//                     res = (F64, 0, math.ceil(a[2]))
//                 else:
//                     res = (F64, 0, math.floor(a[2]))
//             elif  0x9f == opcode: # f64.sqrt
//                 if VALIDATE: assert a[0] == F64
//                 res = (F64, 0, math.sqrt(a[2]))
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s) = %s" % (
//                     value_repr(a), value_repr(res)))
//             sp += 1
//             stack[sp] = res

        // i32 binary
        else if (0x6a <= opcode && opcode <= 0x78) {
            var a = stack[sp-1];
            var b = stack[sp];
            sp -= 2;
            if (VALIDATE) { assert(a[0] == I32 && b[0] == I32, "Expected I32"); }
            var res = [I32, 0, 0.0];
            if (opcode == 0x6a) { // i32.add
                res[1] = int2int32(a[1] + b[1]);
            } else if (opcode == 0x6b) { // i32.sub
                res[1] = a[1] - b[1];
            } else if (opcode == 0x6c) { // i32.mul
                res[1] = int2int32(a[1] * b[1]);
            } else if (opcode == 0x6d) { // i32.div_s
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else if (a[1] == 0x80000000 && b[1] == -1) {
                    throw new WAException("integer overflow");
                } else {
                    res[1] = idiv_s(int2int32(a[1]), int2int32(b[1]));
                }
            } else if (opcode == 0x6e) { // i32.div_u
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res[1] = int2uint32(a[1]) / int2uint32(b[1]);
                }
            } else if (opcode == 0x6f) { // i32.rem_s
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res[1] = irem_s(int2int32(a[1]), int2int32(b[1]));
                }
            } else if (opcode == 0x70) { // i32.rem_u
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res[1] = int2uint32(a[1]) % int2uint32(b[1]);
                }
            } else if (opcode == 0x71) { // i32.and
                res[1] = a[1] & b[1];
            } else if (opcode == 0x72) { // i32.or
                res[1] = a[1] | b[1];
            } else if (opcode == 0x73) { // i32.xor
                res[1] = a[1] ^ b[1];
            } else if (opcode == 0x74) { // i32.shl
                res[1] = a[1] << (b[1] % 0x20);
            } else if (opcode == 0x75) { // i32.shr_s
                res[1] = int2int32(a[1]) >> (b[1] % 0x20);
            } else if (opcode == 0x76) { // i32.shr_u
                res[1] = int2uint32(a[1]) >> (b[1] % 0x20);
            } else if (opcode == 0x77) { // i32.rotl
                res[1] = rotl32(a[1], b[1]);
            } else if (opcode == 0x78) { // i32.rotr
                res[1] = rotr32(a[1], b[1]);
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ", " + value_repr(b) + ") = " + value_repr(res));
            }

            sp += 1;
            stack[sp] = res;
        }

        // i64 binary
        else if (0x7c <= opcode && opcode <= 0x8a) {
            var a = stack[sp-1];
            var b = stack[sp];
            sp -= 2;
            if (VALIDATE) {
                if (a[0] != I64 || b[0] != I64) {
                    throw new WAException("Type mismatch: expected I64");
                }
            }
            var res;
            if (opcode == 0x7c) { // i64.add
                res = [I64, int2int64(a[1] + b[1]), 0.0];
            } else if (opcode == 0x7d) { // i64.sub
                res = [I64, a[1] - b[1], 0.0];
            } else if (opcode == 0x7e) { // i64.mul
                res = [I64, int2int64(a[1] * b[1]), 0.0];
            } else if (opcode == 0x7f) { // i64.div_s
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res = [I64, idiv_s(int2int64(a[1]), int2int64(b[1])), 0.0];
                }
            } else if (opcode == 0x80) { // i64.div_u
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    if (a[1] < 0 && b[1] > 0) {
                        res = [I64, int2uint64(-a[1]) / int2uint64(b[1]), 0.0];
                    } else if (a[1] > 0 && b[1] < 0) {
                        res = [I64, int2uint64(a[1]) / int2uint64(-b[1]), 0.0];
                    } else {
                        res = [I64, int2uint64(a[1]) / int2uint64(b[1]), 0.0];
                    }
                }
            } else if (opcode == 0x81) { // i64.rem_s
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res = [I64, irem_s(int2int64(a[1]), int2int64(b[1])), 0.0];
                }
            } else if (opcode == 0x82) { // i64.rem_u
                if (b[1] == 0) {
                    throw new WAException("integer divide by zero");
                } else {
                    res = [I64, int2uint64(a[1]) % int2uint64(b[1]), 0.0];
                }
            } else if (opcode == 0x83) { // i64.and
                res = [I64, a[1] & b[1], 0.0];
            } else if (opcode == 0x84) { // i64.or
                res = [I64, a[1] | b[1], 0.0];
            } else if (opcode == 0x85) { // i64.xor
                res = [I64, a[1] ^ b[1], 0.0];
            } else if (opcode == 0x86) { // i64.shl
                res = [I64, a[1] << (b[1] % 0x40), 0.0];
            } else if (opcode == 0x87) { // i64.shr_s
                res = [I64, int2int64(a[1]) >> (b[1] % 0x40), 0.0];
            } else if (opcode == 0x88) { // i64.shr_u
                res = [I64, i64_shr_u(a[1], b[1] % 0x40), 0.0];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ", " + value_repr(b) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        }
        // f32 binary operations
        else if (0x92 <= opcode && opcode <= 0x98) {
            var a = stack[sp-1];
            var b = stack[sp];
            sp -= 2;
            if (VALIDATE) { assert(a[0] == F32 && b[0] == F32, null); }
            var res;
            if (opcode == 0x92) { // f32.add
                res = [F32, 0, a[2] + b[2]];
            } else if (opcode == 0x93) { // f32.sub
                res = [F32, 0, a[2] - b[2]];
            } else if (opcode == 0x94) { // f32.mul
                res = [F32, 0, a[2] * b[2]];
            } else if (opcode == 0x95) { // f32.div
                res = [F32, 0, a[2] / b[2]];
            } else if (opcode == 0x96) { // f32.min
                res = [F32, 0, (a[2] < b[2]) ? a[2] : b[2]];
            } else if (opcode == 0x97) { // f32.max
                if (a[2] == 0.0 && b[2] == 0.0) {
                    res = [F32, 0, 0.0];
                } else {
                    res = [F32, 0, (a[2] > b[2]) ? a[2] : b[2]];
                }
            } else if (opcode == 0x98) { // f32.copysign
                res = [F32, 0, (b[2] > 0) ? Math.abs(a[2]) : -Math.abs(a[2])];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ", " + value_repr(b) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        }

        // f64 binary operations
        else if (0xa0 <= opcode && opcode <= 0xa6) {
            var a = stack[sp-1];
            var b = stack[sp];
            sp -= 2;
            if (VALIDATE) { assert(a[0] == F64 && b[0] == F64, null); }
            var res;
            if (opcode == 0xa0) { // f64.add
                res = [F64, 0, a[2] + b[2]];
            } else if (opcode == 0xa1) { // f64.sub
                res = [F64, 0, a[2] - b[2]];
            } else if (opcode == 0xa2) { // f64.mul
                res = [F64, 0, a[2] * b[2]];
            } else if (opcode == 0xa3) { // f64.div
                if (b[2] == 0.0) {
                    var aneg = (a[2].toString().substring(0, 1) == "-");
                    var bneg = (b[2].toString().substring(0, 1) == "-");
                    if ((aneg && !bneg) || (!aneg && bneg)) {
                        res = [F64, 0, createNegativeInfinity()];
                    } else {
                        res = [F64, 0, createPositiveInfinity()];
                    }
                } else {
                    res = [F64, 0, a[2] / b[2]];
                }
            } else if (opcode == 0xa4) { // f64.min
                res = [F64, 0, (a[2] < b[2]) ? a[2] : b[2]];
            } else if (opcode == 0xa5) { // f64.max
                res = [F64, 0, (a[2] > b[2]) ? a[2] : b[2]];
            } else if (opcode == 0xa6) { // f64.copysign
                res = [F64, 0, (b[2] > 0) ? Math.abs(a[2]) : -Math.abs(a[2])];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ", " + value_repr(b) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        }
        // conversion operations
        else if (0xa7 <= opcode && opcode <= 0xbb) {
            var a = stack[sp];
            sp -= 1;
            
            var res;

            // conversion operations
            if (0xa7 == opcode) { // i32.wrap_i64
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [I32, int2int32(a[1]), 0.0];
            } else if (0xa8 == opcode) { // i32.trunc_f32_s
                if (VALIDATE) { assert(a[0] == F32, null); }
                if (isNaN(a[2])) {
                    throw new WAException("invalid conversion to integer");
                } else if (a[2] > 2147483647.0) {
                    throw new WAException("integer overflow");
                } else if (a[2] < -2147483648.0) {
                    throw new WAException("integer overflow");
                }
                res = [I32, a[2].toNumber(), 0.0];
            } else if (0xac == opcode) { // i64.extend_i32_s
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [I64, int2int32(a[1]), 0.0];
            } else if (0xad == opcode) { // i64.extend_i32_u
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [I64, intmask(a[1]), 0.0];
            } else if (0xb0 == opcode) { // i64.trunc_f64_s
                if (VALIDATE) { assert(a[0] == F64, null); }
                if (isNaN(a[2])) {
                    throw new WAException("invalid conversion to integer");
                }
                res = [I64, a[2].toNumber(), 0.0];
            } else if (0xb1 == opcode) { // i64.trunc_f64_u
                if (VALIDATE) { assert(a[0] == F64, null); }
                if (isNaN(a[2])) {
                    throw new WAException("invalid conversion to integer");
                } else if (a[2] <= -1.0) {
                    throw new WAException("integer overflow");
                }
                res = [I64, a[2].toNumber(), 0.0];
            } else if (0xb2 == opcode) { // f32.convert_i32_s
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [F32, 0, a[1].toFloat()];
            } else if (0xb3 == opcode) { // f32.convert_i32_u
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [F32, 0, int2uint32(a[1]).toFloat()];
            } else if (0xb4 == opcode) { // f32.convert_i64_s
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [F32, 0, a[1].toFloat()];
            } else if (0xb5 == opcode) { // f32.convert_i64_u
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [F32, 0, int2uint64(a[1]).toFloat()];
            } else if (0xb7 == opcode) { // f64.convert_i32_s
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [F64, 0, a[1].toDouble()];
            } else if (0xb8 == opcode) { // f64.convert_i32_u
                if (VALIDATE) { assert(a[0] == I32, null); }
                res = [F64, 0, int2uint32(a[1]).toDouble()];
            } else if (0xb9 == opcode) { // f64.convert_i64_s
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [F64, 0, a[1].toDouble()];
            } else if (0xba == opcode) { // f64.convert_i64_u
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [F64, 0, int2uint64(a[1]).toDouble()];
            } else if (0xbb == opcode) { // f64.promote_f32
                if (VALIDATE) { assert(a[0] == F32, null); }
                res = [F64, 0, a[2]];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            
            if (TRACE) {
                debug("      - (" + value_repr(a) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        // reinterpretations
        } else if (0xbc <= opcode && opcode <= 0xbf) {
            var a = stack[sp];
            sp -= 1;

            var res;
            if (0xbc == opcode) { // i32.reinterpret_f32
                if (VALIDATE) { assert(a[0] == F32, null); }
                res = [I32, intmask(pack_f32(a[2])), 0.0];
            } else if (0xbd == opcode) { // i64.reinterpret_f64
                if (VALIDATE) { assert(a[0] == F64, null); }
                res = [I64, intmask(pack_f64(a[2])), 0.0];
            // } else if (0xbe == opcode) { // f32.reinterpret_i32
            //     if (VALIDATE) { assert(a[0] == I32, null); }
            //     res = [F32, 0, unpack_f32(int2int32(a[1]))];
            } else if (0xbf == opcode) { // f64.reinterpret_i64
                if (VALIDATE) { assert(a[0] == I64, null); }
                res = [F64, 0, unpack_f64(int2int64(a[1]))];
            } else {
                throw new WAException(OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ") unimplemented");
            }
            if (TRACE) {
                debug("      - (" + value_repr(a) + ") = " + value_repr(res));
            }
            sp += 1;
            stack[sp] = res;
        } else {
            throw new WAException("unrecognized opcode 0x" + opcode.format("%02x") + " (" + OPERATOR_INFO[opcode][0] + ")");
        }
    }

    return [pc, sp, fp, csp];
}

// ####################################
// Higher level classes
// ####################################

class Reader {
    public var bytes as ByteArray;
    public var pos as Number;

    public function initialize(bytes as ByteArray) {
        self.bytes = bytes;
        self.pos = 0;
    }

    public function readByte() as Number {
        var b = self.bytes[self.pos];
        self.pos++;
        return b;
    }

    public function readWord() as Number {
        throw new NotImplementedException();
        // var w = bytes2uint32(self.bytes.slice(self.pos, self.pos + 4));
        // self.pos += 4;
        // return w;
    }

    public function readBytes(cnt as Number) as ByteArray {
        throw new NotImplementedException();
        // if (VALIDATE) {
        //     if (cnt < 0 || self.pos < 0) {
        //         throw new Lang.Exception("Invalid read parameters");
        //     }
        // }
        // var bytes = self.bytes.slice(self.pos, self.pos + cnt);
        // self.pos += cnt;
        // return bytes;
    }

    public function read_LEB(maxbits as Number, signed as Boolean) as Number {
        throw new NotImplementedException();
        // var result = $.read_LEB(self.bytes, self.pos, maxbits, signed);
        // self.pos = result[0];
        // return result[1];
    }

    public function eof() as Boolean {
        return self.pos >= self.bytes.size();
    }

    public function toString() as String {
        return "Reader(pos: " + self.pos + ", bytes: " + self.bytes.size() + " bytes)";
    }
}

class Memory {
    public var pages as Number;
    public var bytes as ByteArray;

    public function initialize(pages as Number, initialBytes as ByteArray or Null) {
        System.println("memory pages: " + pages);
        self.pages = pages;
        if (initialBytes != null) {
            self.bytes = initialBytes;
            var remainingSize = (pages * (1 << 16)) - initialBytes.size();
            if (remainingSize > 0) {
                self.bytes.addAll(new [remainingSize]b);
            }
        } else {
            self.bytes = new [pages * (1 << 16)]b;
        }
    }

    public function grow(pages as Number) as Void {
        self.pages += pages.toNumber();
        var additionalBytes = new [pages.toNumber() * (1 << 16)]b;
        self.bytes.addAll(additionalBytes);
    }

    public function readByte(pos as Number) as Number {
        return self.bytes[pos];
    }

    public function writeByte(pos as Number, val as Number) as Void {
        self.bytes[pos] = val;
    }

    public function write(offset as Number, data as ByteArray) as Void {
        if (offset + data.size() > self.bytes.size()) {
            throw new WAException("Write operation exceeds memory bounds");
        }
        
        // If writing at the end, we can use addAll for efficiency
        if (offset == self.bytes.size()) {
            self.bytes.addAll(data);
        } else {
            // Otherwise, we need to overwrite existing bytes
            for (var i = 0; i < data.size(); i++) {
                self.bytes[offset + i] = data[i];
            }
        }

        var endOffset = offset + data.size();
        self.bytes = self.bytes.slice(0, offset).addAll(data).addAll(self.bytes.slice(endOffset, null));

    }

    public function toString() as String {
        return "Memory(pages: " + self.pages + ", bytes: " + self.bytes.size() + " bytes)";
    }
}

class Import {
    public var module_ as String;
    public var field as String;
    public var kind as Number;
    public var type as Number;
    public var elementType as Number;
    public var initial as Number;
    public var maximum as Number;
    public var globalType as Number;
    public var mutability as Number;

    public function initialize(module_ as String, field as String, kind as Number, type as Number, 
                               elementType as Number, initial as Number, maximum as Number, 
                               globalType as Number, mutability as Number) {
        self.module_ = module_;
        self.field = field;
        self.kind = kind;
        self.type = type; // Function
        self.elementType = elementType; // Table
        self.initial = initial; // Table & Memory
        self.maximum = maximum; // Table & Memory
        self.globalType = globalType; // Global
        self.mutability = mutability; // Global
    }

    public function toString() as String {
        return "Import(module: '" + self.module_ + "', field: '" + self.field + "', kind: " + self.kind + ")";
    }
}

class Export {
    public var field as String;
    public var kind as Number;
    public var index as Number;

    public function initialize(field as String, kind as Number, index as Number) {
        self.field = field;
        self.kind = kind;
        self.index = index;
    }

    public function toString() as String {
        return "Export(field: '" + self.field + "', kind: " + self.kind + ", index: " + self.index + ")";
    }
}


class Module {
    private var data as ByteArray;
    private var rdr as Reader;
    // private var importValue as ImportMethodType;
    var importFunction as ImportFunctionType;

    // Sections
    private var type as Array<Type>;
    private var import_list as Array<Import>;
    var function_ as Array<Function>;
    // private var fnImportCnt as Number;
    private var table as Dictionary<Number, Array<Number>>;
    private var exportList as Array<Export>;
    private var exportMap as Dictionary<String, Export>;
    private var globalList as Array<Global>;

    public var memory as Memory;

    // // block/loop/if blocks {start addr: Block, ...}
    private var block_map as Dictionary<Number, Block>;

    // Execution state
    var sp as Number;
    private var fp as Number;
    var stack as StackType;
    private var csp as Number;
    private var callstack as CallStackType;
    public var start_function as Number = -1;
    
    public function initialize(
            data as ByteArray, 
            // importValue as ImportMethodType, 
            importFunction as ImportFunctionType, 
            memory as Memory?,
            types as Array<Type>,
            // functions as ImportMethodType, 
            functions as Array<Function>,
            tables as Dictionary<Number, Array<Number>>,
            globals as Array<Global>,
            exports as Array<Export>,
            exportMap as Dictionary<String, Export>,
            blockMap as Dictionary<Number, Block>
            ) {
        self.data = data;
        self.rdr = new Reader(data);
        // self.importValue = importValue;
        self.importFunction = importFunction;

        // Initialize sections
        self.type = types;
        self.import_list = []; // not implemented (doesn't seem nessasary)
        self.function_ = functions;
        // self.fnImportCnt = 0;
        self.table = tables;//{ANYFUNC => []};
        self.exportList = exports;
        self.exportMap = exportMap;
        self.globalList = globals;

        if (memory != null) {
            self.memory = memory;
        } else {
            self.memory = new Memory(1);  // default to 1 page
        }

        self.block_map = blockMap;

        // Initialize execution state
        self.sp = -1;
        self.fp = -1;
        self.stack = new [STACK_SIZE];
        for (var i = 0; i < STACK_SIZE; i++) {
            self.stack[i] = [0x00, 0, 0.0];
        }
        self.csp = -1;
        var block = new Block(0x00, BLOCK_TYPE[I32], 0, 0, 0, 0);
        self.callstack = new [CALLSTACK_SIZE];
        for (var i = 0; i < CALLSTACK_SIZE; i++) {
            self.callstack[i] = [block, -1, -1, 0];
        }
        self.start_function = -1;

        // readMagic();
        // readVersion();
        // readSections();

        // dump();

        // // Run the start function if set
        // if (self.start_function >= 0) {
        //     var fidx = self.start_function;
        //     var func = self.function_[fidx];
        //     System.println("Running start function 0x" + fidx.format("%x"));
        //     if (TRACE) {
        //         dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        //     }
        //     if (func instanceof FunctionImport) {
        //         sp = do_callImport(self.stack, self.sp, self.memory, self.importFunction, func);
        //     } else if (func instanceof Function) {
        //         var result = do_call(self.stack, self.callstack, self.sp, self.fp, self.csp, func, self.rdr.bytes.size());
        //         self.rdr.pos = result[0];
        //         self.sp = result[1];
        //         self.fp = result[2];
        //         self.csp = result[3];
        //     }
        //     interpret();
        // }
    }

    public function dump() as Void {
        // debug("module bytes: " + byteCodeRepr(self.rdr.bytes));
        info("");

        info("Types:");
        for (var i = 0; i < self.type.size(); i++) {
            info("  0x" + i.format("%x") + " " + type_repr(self.type[i]));
        }

        info("Imports:");
        // these havn't been added
        for (var i = 0; i < self.import_list.size(); i++) {
            var imp = self.import_list[i];
            if (imp.kind == 0x0) {  // Function
                info("  0x" + i.format("%x") + " [type: " + imp.type + ", '" + imp.module_ + "." + imp.field + "', kind: " + 
                      EXTERNAL_KIND_NAMES[imp.kind] + " (" + imp.kind + ")]");
            } else if (imp.kind == 0x1 || imp.kind == 0x2) {  // Table & Memory
                info("  0x" + i.format("%x") + " ['" + imp.module_ + "." + imp.field + "', kind: " + 
                      EXTERNAL_KIND_NAMES[imp.kind] + " (" + imp.kind + "), initial: " + imp.initial + ", maximum: " + imp.maximum + "]");
            } else if (imp.kind == 0x3) {  // Global
                info("  0x" + i.format("%x") + " ['" + imp.module_ + "." + imp.field + "', kind: " + 
                      EXTERNAL_KIND_NAMES[imp.kind] + " (" + imp.kind + "), type: " + imp.globalType + ", mutability: " + imp.mutability + "]");
            }
        }

        info("Functions:");
        for (var i = 0; i < self.function_.size(); i++) {
            info("  0x" + i.format("%x") + " " + funcRepr(self.function_[i]));
        }
        info("Tables:");
        if (self.table != null && self.table.size() > 0) {
            var keys = self.table.keys();
            for (var i = 0; i < keys.size(); i++) {
                var key = keys[i];
                var entries = self.table[key];
                var entryStrings = [];
                for (var j = 0; j < entries.size(); j++) {
                    entryStrings.add("0x" + entries[j].format("%x"));
                }
                info("  0x" + key.format("%x") + " -> [" + join(entryStrings, ",") + "]");
            }
        } else {
            info("  No tables defined");
        }

        info("Memory:");
        if (self.memory.pages > 0) {
            for (var r = 0; r < 10; r++) {
                var hexValues = [];
                for (var j = 0; j < 16; j++) {
                    var byteValue = self.memory.bytes[r * 16 + j];
                    hexValues.add(hexpad(byteValue, 2));
                }
                info("  0x" + hexpad(r * 16, 3) + " [" + join(hexValues, ",") + "]");
            }
        }

        info("Global:");
        for (var i = 0; i < self.globalList.size(); i++) {
            info("  0x" + i + " [" + value_repr(self.globalList[i]) + "]");
        }

        info("Exports:");
        for (var i = 0; i < self.exportList.size(); i++) {
            info("  0x" + i.format("%x") + " " + export_repr(self.exportList[i]));
        }
        info("");

        var blockKeys = self.block_map.keys();
        blockKeys.sort(null);
        var blockMapStrings = [];
        for (var i = 0; i < blockKeys.size(); i++) {
            var k = blockKeys[i];
            var bl = self.block_map[k];
            blockMapStrings.add("'" + blockRepr(bl) + "[0x" + bl.start.format("%x") + "->0x" + bl.end.format("%x") + "]'");
        }
        info("block_map: [" + join(blockMapStrings, ", ") + "]");
        info("");
    }

    function hexpad(x as Number, cnt as Number) as String {
        return x.format("%0" + cnt + "x");
    }        

    public function interpret() as Void {
        info("interpret: pc: 0x" + self.rdr.pos.format("%x"));
        var result = interpret_mvp(self,
            // Greens
            self.rdr.pos, self.rdr.bytes, self.function_,
            self.table, self.block_map,
            // Reds
            self.memory, self.sp, self.stack, self.fp, self.csp,
            self.callstack);
        
        self.rdr.pos = result[0];
        self.sp = result[1];
        self.fp = result[2];
        self.csp = result[3];
    }

    // async interpretation
    private var interpretTimer as Timer.Timer?;
    private var interpretCallback as Method(ValueTupleType)?;
    var maxAsyncOperations = -1;

    function isAsyncRunning() as Boolean {
        return self.interpretTimer != null;
    }

    private function interpretAndFinish(callback as Method(ValueTupleType), maxOps as Number) as Void {
        if (self.interpretTimer != null) {
            return; // Prevent running more than one interpretation
        }
        self.maxAsyncOperations = maxOps;
        self.interpretCallback = callback;
        self.interpret();
        if (self.csp == -1) {
            self.finishInterpretation();
        } else {
            // Start a timer that will call continueInterpretation every 50ms (minimum time value)
            self.interpretTimer = new Timer.Timer();
            self.interpretTimer.start(method(:continueInterpretation), 50, false);
        }
    }

    function continueInterpretation() as Void {
        if (self.interpretTimer == null) {
            return; // Prevent running more than one interpretation
        }
        self.interpret();
        if (self.csp == -1) {
            self.finishInterpretation();
        } else {
            // Restart the timer for the next interpretation step
            self.interpretTimer.start(method(:continueInterpretation), 50, false);
        }
    }

    private function finishInterpretation() as Void {
        if (self.interpretTimer != null) {
            self.interpretTimer.stop();
            self.interpretTimer = null;
        }
        
        if (self.interpretCallback != null) {
            var returnValue = self.getReturnValue();
            self.interpretCallback.invoke(returnValue);
            self.interpretCallback = null;
        }

        self.maxAsyncOperations = -1;
    }

    private function getReturnValue() as ValueTupleType {
    if (self.sp >= 0) {
        var ret = self.stack[self.sp];
        self.sp--;
        return ret;
    } else {
        return [I32, 0, 0.0] as ValueTupleType; // Default return value if stack is empty
        }
    }

    // run functions
    public function runCatchTrap(fname as String, args as ValueTupleType) as ValueTupleType or WAException {
        try {
            var printReturn = false;
            var returnValue = true;
            return self.runWithArgs(fname, args, printReturn, returnValue) as ValueTupleType;
        } catch (e instanceof WAException) {
            return e;
        }        
    }

    public function run(fname as String, args as ValueTupleType) as ValueTupleType {
        var printReturn = false;
        var returnValue = true;
        return self.runWithArgs(fname, args, printReturn, returnValue);
    }
    
    // dont really want to start it immediately when creating the module
    // but we need to set the start function somewhere
    public function runStartFunction() as ValueTupleType {
        // Run the start function if set
        if (self.start_function >= 0) {
            var fidx = self.start_function;
            var func = self.function_[fidx];
            info(Lang.format("Running start function 0x$1$", [fidx.format("%x")]));
            if (TRACE) {
                dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
            }
            if (func instanceof FunctionImport) {
                self.sp = do_callImport(self.stack, self.sp, self.memory, self.import_function, func);
            } else if (func instanceof Function) {
                var result = do_call(self.stack, self.callstack, self.sp, self.fp, self.csp, func, self.rdr.bytes.size(), false);
                self.rdr.pos = result[0];
                self.sp = result[1];
                self.fp = result[2];
                self.csp = result[3];
            }
            self.interpret();



            if (TRACE) {
                dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
            }
            var targs = [];
            if (self.sp >= 0) {
                var ret = self.stack[self.sp];
                self.sp--;
                System.println("Start function: (" + Lang.format("$1$", [join(targs, ", ")]) + ") = " + value_repr(ret));
                return ret;
            } else {
                System.println("Start function:" + "(" + Lang.format("$1$", [join(targs, ", ")]) + ")");
            }
            return 0;
        }
    }

    // watchdog workaround: max ops per timer call
    public function runStartFunctionAsync(maxAsyncOps as Number, callback as Method(ValueTupleType)) as Void {
        // Run the start function if set
        if (self.start_function >= 0) {
            var fidx = self.start_function;
            var func = self.function_[fidx];
            info(Lang.format("Running start function 0x$1$", [fidx.format("%x")]));
            if (TRACE) {
                dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
            }
            if (func instanceof FunctionImport) {
                self.sp = do_callImport(self.stack, self.sp, self.memory, self.importFunction, func);
                self.interpretAndFinish(callback, maxAsyncOps);
            } else if (func instanceof Function) {
                var result = do_call(self.stack, self.callstack, self.sp, self.fp, self.csp, func, self.rdr.bytes.size(), false);
                self.rdr.pos = result[0];
                self.sp = result[1];
                self.fp = result[2];
                self.csp = result[3];
                self.interpretAndFinish(callback, maxAsyncOps);
            } else {
                self.finalizeStartFunction(callback);
            }
        } else {
            self.finalizeStartFunction(callback);
        }
    }

    private function finalizeStartFunction(callback as Method(ValueTupleType)) as Void {
        if (TRACE) {
            dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        }
        var targs = [];
        var ret;
        if (self.sp >= 0) {
            ret = self.stack[self.sp];
            self.sp--;
            System.println("Start function: (" + Lang.format("$1$", [join(targs, ", ")]) + ") = " + value_repr(ret));
        } else {
            System.println("Start function: (" + Lang.format("$1$", [join(targs, ", ")]) + ")");
            ret = [I32, 0, 0.0] as ValueTupleType; // Default return value if stack is empty
        }
        callback.invoke(ret);
    }

    public function runWithArgs(fname as String?, args as ValueTupleType, printReturn as Boolean, returnValue as Boolean) as Number | ValueTupleType {
        // Reset stacks
        self.sp = -1;
        self.fp = -1;
        self.csp = -1;

        var fidx = fname != null ? self.exportMap[fname].index : self.start_function;

        // Check arg type
        var tparams = self.function_[fidx].type.params;
        if (tparams.size() != args.size()) {
            throw new WAException("arg count mismatch " + tparams.size() + " != " + args.size());
        }
        for (var idx = 0; idx < args.size(); idx++) {
            if (tparams[idx] != args[idx][0]) {
                throw new WAException("arg type mismatch " + tparams[idx] + " != " + args[idx][0]);
            }
            self.sp++;
            self.stack[self.sp] = args[idx];
        }

        System.println("Running function '" + fname + "' (0x" + fidx.format("%x") + ")");
        if (TRACE) {
            dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        }
        var result = do_call(self.stack, self.callstack, self.sp, self.fp, self.csp, self.function_[fidx], 0, false);
        self.rdr.pos = result[0];
        self.sp = result[1];
        self.fp = result[2];
        self.csp = result[3];

        interpret();
        if (TRACE) {
            dump_stacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        }
        var targs = [];
        for (var i = 0; i < args.size(); i++) {
            targs.add(value_repr(args[i]));
        }
        if (self.sp >= 0) {
            var ret = self.stack[self.sp];
            self.sp--;
            System.println(fname + "(" + Lang.format("$1$", [join(targs, ", ")]) + ") = " + value_repr(ret));
            if (printReturn) {
                System.println(value_repr(ret));
            }
            if (returnValue) {
                return ret;
            }
        } else {
            System.println(fname + "(" + Lang.format("$1$", [join(targs, ", ")]) + ")");
        }
        return 0;
    }

    public function toString() as String {
        return "Module(types: " + self.type.size() + ", functions: " + self.function_.size() + ", exports: " + self.exportList.size() + ")";
    }
}

// ######################################
// # Imported functions points
// ######################################


// def readline(prompt):
//     res = ''
//     sys.stdout.write(prompt)
//     sys.stdout.flush()
//     while True:
//         buf = sys.stdin.readline()
//         if not buf: raise EOFError()
//         res += buf
//         if res[-1] == '\n': return res[:-1]

// def get_string(mem, addr):
//     slen = 0
//     assert addr >= 0
//     while mem.bytes[addr+slen] != 0: slen += 1
//     bytes_data = mem.bytes[addr:addr+slen]
//     return bytes(bytes_data).decode('utf-8')

// def put_string(mem, addr, string):
//     pos = addr
//     bytes_data = string.encode('utf-8')
//     for i in range(len(bytes_data)):
//         mem.bytes[pos] = bytes_data[i]
//         pos += 1
//     mem.bytes[pos] = 0  # zero terminated
//     return pos

// #
// # Imports (global values and functions)

// IMPORT_VALUES = {
//     "spectest.global_i32": (I32, 666, 666.6),
//     "env.memoryBase":      (I32, 0, 0.0)
// }

// def import_value(module, field):
//     iname = "%s.%s" % (module, field)
//     #return (I32, 377, 0.0)
//     if iname in IMPORT_VALUES:
//         return IMPORT_VALUES[iname]
//     else:
//         raise Exception("global import %s not found" % (iname))

// def spectest_print(mem, args):
//     if len(args) == 0: return []
//     assert len(args) == 1
//     assert args[0][0] == I32
//     val = args[0][1]
//     res = ""
//     while val > 0:
//         res = res + chr(val & 0xff)
//         val = val>>8
//     print("%s '%s'" % (value_repr(args[0]), res))
//     return []

// def env_printline(mem, args):
//     string = get_string(mem, args[0][1])
//     os.write(1, string.encode('utf-8'))
//     return [(I32, 1, 1.0)]

// def env_readline(mem, args):
//     prompt = get_string(mem, args[0][1])
//     buf = args[1][1]        # I32
//     max_length = args[2][1] # I32

//     try:
//         str = readline(prompt)
//         max_length -= 1
//         assert max_length >= 0
//         str = str[0:max_length]
//         put_string(mem, buf, str)
//         return [(I32, buf, 0.0)]
//     except EOFError:
//         return [(I32, 0, 0.0)]

// def env_read_file(mem, args):
//     path = get_string(mem, args[0][1])
//     buf = args[1][1]
//     with open(path, 'r', encoding='utf-8') as file:
//         content = file.read()
//     slen = put_string(mem, buf, content)
//     return [(I32, slen, 0.0)]

// def env_get_time_ms(mem, args):
//     # subtract 30 years to make sure it fits into i32 without wrapping
//     # or becoming negative
//     return [(I32, int(time.time()*1000 - 0x38640900), 0.0)]

var host_output = "";
function host_putchar(mem as Memory, args as ValueTupleType) as ValueTupleType {
    if (args.size() != 1) {
        throw new WAException("Invalid number of arguments");
    }
    
    if (args[0][0] != I32) {
        throw new WAException("Invalid argument type");
    }
    var charCode = args[0][1];
    terminal.putChar(charCode);
    // System.println("host_putchar: " + charCode);
    // System.print(charCode.toChar().toString());
    host_output += charCode.toChar().toString();
    return [[I32, charCode, 0.0]];
}


function import_function(module_ as Module, field as String, mem as Memory, args as ValueTupleType) as ValueTupleType {
    var fname = module_ + "." + field;
//     if fname in ["spectest.print", "spectest.print_i32"]:
//         return spectest_print(mem, args)
//     elif fname == "env.printline":
//         return env_printline(mem, args)
//     elif fname == "env.readline":
//         return env_readline(mem, args)
//     elif fname == "env.read_file":
//         return env_read_file(mem, args)
//     elif fname == "env.get_time_ms":
//         return env_get_time_ms(mem, args)
//     elif fname == "env.exit":
//         raise ExitException(args[0][1])
    if (fname.equals("host.putchar")) {
        return host_putchar(mem, args);
    } else {
        throw new WAException("function import " + fname + " not found");
    }
}

// def parse_command(module, args):
//     fname = args[0]
//     args = args[1:]
//     run_args = []
//     fidx = module.export_map[fname].index
//     tparams = module.function[fidx].type.params
//     for idx, arg in enumerate(args):
//         arg = args[idx].lower()
//         assert isinstance(arg, str)
//         run_args.append(parse_number(tparams[idx], arg))
//     return fname, run_args

// def usage(argv):
//     print("%s [--repl] [--argv] [--memory-pages PAGES] WASM [ARGS...]" % argv[0])

// ######################################
// # Entry points
// ######################################


// def entry_point(argv):
//     try:
//         # Argument handling
//         repl = False
//         argv_mode = False
//         memory_pages = 1
//         fname = None
//         args = []
//         run_args = []
//         idx = 1
//         while idx < len(argv):
//             arg = argv[idx]
//             idx += 1
//             if arg == "--help":
//                 usage(argv)
//                 return 1
//             elif arg == "--repl":
//                 repl = True
//             elif arg == "--argv":
//                 argv_mode = True
//                 memory_pages = 256
//             elif arg == "--memory-pages":
//                 memory_pages = int(argv[idx])
//                 idx += 1
//             elif arg == "--":
//                 continue
//             elif arg.startswith('--'):
//                 print("Unknown option '%s'" % arg)
//                 usage(argv)
//                 return 2
//             else:
//                 args.append(arg)
//         with open(args[0], 'rb') as file:
//             wasm = file.read()
//         args = args[1:]

//         #
//         mem = Memory(memory_pages)

//         if argv_mode:
//             # Convert args into C argv style array of strings and
//             # store at the beginning of memory. This must be before
//             # the module is initialized so that we can properly set
//             # the memoryBase global before it is imported.
//             args.insert(0, argv[0])
//             string_next = (len(args) + 1) * 4
//             for i, arg in enumerate(args):
//                 slen = put_string(mem, string_next, arg)
//                 write_I32(mem.bytes, i*4, string_next) # zero terminated
//                 string_next += slen

//             # Set memoryBase to next 64-bit aligned address
//             string_next += (8 - (string_next % 8))
//             IMPORT_VALUES['env.memoryBase'] = (I32, string_next, 0.0)


//         m = Module(wasm, import_value, import_function, mem)

//         if argv_mode:
//             fname = "_main"
//             fidx = m.export_map[fname].index
//             arg_count = len(m.function[fidx].type.params)
//             if arg_count == 2:
//                 run_args = [(I32, len(args), 0.0), (I32, 0, 0.0)]
//             elif arg_count == 0:
//                 run_args = []
//             else:
//                 raise Exception("_main has %s args, should have 0 or 2" %
//                         arg_count)
//         else:
//             # Convert args to expected numeric type. This must be
//             # after the module is initialized so that we know what
//             # types the arguments are
//             fname, run_args = parse_command(m, args)

//         if '__post_instantiate' in m.export_map:
//             m.run('__post_instantiate', [])

//         if not repl:

//             # Invoke one function and exit
//             try:
//                 return m.run(fname, run_args, not argv_mode)
//             except WAException as e:
//                 os.write(2, "".join(traceback.format_exception(*sys.exc_info())))
//                 os.write(2, "%s\n" % e.message)
//                 return 1
//         else:
//             # Simple REPL
//             while True:
//                 try:
//                     line = readline("webassembly> ")
//                     if line == "": continue

//                     fname, run_args = parse_command(m, line.split(' '))
//                     res = m.run(fname, run_args, True)
//                     if not res == 0:
//                         return res

//                 except WAException as e:
//                     os.write(2, "Exception: %s\n" % e.message)
//                 except EOFError as e:
//                     break

//     except WAException as e:
//         sys.stderr.write("".join(traceback.format_exception(*sys.exc_info())))
//         sys.stderr.write("Exception: %s\n" % str(e))
//     except ExitException as e:
//         return e.code
//     except Exception as e:
//         sys.stderr.write("".join(traceback.format_exception(*sys.exc_info())))
//         return 1

//     return 0

// def target(*args):
//     return entry_point

// if __name__ == '__main__':
//     sys.exit(entry_point(sys.argv))