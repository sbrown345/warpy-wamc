import Toybox.Lang;
import Toybox.System;

typedef ImportMethodType as Method(module_ as Module, field as String) as Array<Number>;
typedef ImportFunctionType as Method(module_ as Module, field as String, mem as Memory, args as Array<Array<Number>>) as Array<Array<Number>>;
typedef StackType as Array<Array<Number>>;
typedef CallStackType as Array<Array<Number or Block or Function>>;
typedef Global as ValueTupleType;
typedef ValueTupleType as [Number, Number, Float];

// var INFO  = false; // informational logging
// var TRACE = false; // trace instructions/stacks
// var DEBUG = false; // verbose logging
var INFO  = true;
var TRACE = true;
var DEBUG = true;
var VALIDATE = true;


function do_sort(a as Array) as Array {
    return a.sort(null);
}

// def unpack_f32(i32):
//     return struct.unpack('f', struct.pack('i', i32))[0]
// def unpack_f64(i64):
//     return struct.unpack('d', struct.pack('q', i64))[0]
// def pack_f32(f32):
//     return struct.unpack('i', struct.pack('f', f32))[0]
// def pack_f64(f64):
//     return struct.unpack('q', struct.pack('d', f64))[0]

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
    public var mask as Number;

    function initialize(index as Number, form as Number, params as Array<Number>, results as Array<Number>, mask as Number) {
        self.index = index;
        self.form = form;
        self.params = params;
        self.results = results;
        self.mask = mask; // default was 0x80
    }

    function toString() as String {
        return "Type(index: " + self.index + ", form: " + self.form + ", params: " + self.params + ", results: " + self.results + ", mask: " + self.mask + ")";
    }
}

class Code {
}

class Block extends Code {
    public var kind as Number;
    public var type as Number;
    public var locals as Array<Number>;
    public var start as Number;
    public var end as Number;
    public var elseAddr as Number;
    public var brAddr as Number;

    function initialize(kind as Number, type as Number, start as Number) {
        self.kind = kind; // block opcode (0x00 for init_expr)
        self.type = type; // value_type
        self.locals = [];
        self.start = start;
        self.end = 0;
        self.elseAddr = 0;
        self.brAddr = 0;
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
const FLT_MAX = 3.4028235e38f;

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

function rotr32(a, cnt) {
    return (a >> (cnt % 0x20)) | ((a << (0x20 - (cnt % 0x20))) & 0xffffffff);
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

function int2uint32(i) {
    return i & 0xffffffff;
}

function int2int32(i) {
    // var val = i & 0xffffffff;
    // return (val & 0x80000000) ? (val - 0x100000000) : val;
    var val = i.toNumber() & 0xffffffff;
    return (val & 0x80000000) ? (val | (~0xffffffff)) : val;
}

//

function bytes2uint64(b) {
    return ((b[7] << 56) + (b[6] << 48) + (b[5] << 40) + (b[4] << 32) +
            (b[3] << 24) + (b[2] << 16) + (b[1] << 8) + b[0]);
}

function uint642bytes(v) {
    return [
        0xff & v,
        0xff & (v >> 8),
        0xff & (v >> 16),
        0xff & (v >> 24),
        0xff & (v >> 32),
        0xff & (v >> 40),
        0xff & (v >> 48),
        0xff & (v >> 56)
    ];
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
    throw new NotImplementedException();
    // var val = i & 0xffffffffffffffffl;
    // return (val & 0x8000000000000000l) ? (val - 0x10000000000000000l) : val;
}

// https://en.wikipedia.org/wiki/LEB128
function read_LEB(bytes, pos, maxbits/*=32*/, signed/*=false*/) as [Number, Number] {
    var result = 0;
    var shift = 0;
    var bcnt = 0;
    var startpos = pos;

    if(maxbits == null) {
        maxbits = 32;
    }

    if(signed == null) {
        signed = false; 
    }

    var byte = 0;
    while (true) {
        byte = bytes[pos];
        pos += 1;
        result |= ((byte & 0x7f) << shift);
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
        result |= - (1 << shift);
    }
    return [pos, result];
}

function read_I32(bytes, pos) {
    assert(pos >= 0, null);
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
}

function read_I64(bytes, pos) {
    assert(pos >= 0, null);
    return bytes2uint64(bytes.slice(pos, pos + 8));
}

function read_F32(bytes, pos) {
    assert(pos >= 0, null);
    var num = bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
    if (isNaN(num)) {return num; }
    return fround(num, 5);
}

function read_F64(bytes, pos) {
    assert(pos >= 0, null);
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
}

function write_I32(bytes as ByteArray, pos as Number, ival as Number) as Void {
    bytes.encodeNumber(ival, Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
}

function write_I64(bytes as ByteArray, pos as Number, ival as Number) as Void {
    throw new NotImplementedException();
    // bytes[pos:pos + 8] = uint642bytes(ival);
}

function write_F32(bytes as ByteArray, pos as Number, fval as Float) as Void {
    bytes.encodeNumber(fval, Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
}

function write_F64(bytes as ByteArray, pos as Number, fval as Float) as Void {
    throw new NotImplementedException();
    // var ival = intmask(pack_f64(fval));
    // bytes[pos:pos + 8] = uint642bytes(ival);
}


function value_repr(val as Array) as String {
    var vt = val[0];
    var ival = val[1];
    var fval = val[2];
    var vtn = VALUE_TYPE[vt];
    
    if (vtn.equals("i32") || vtn.equals("i64")) {
        return Lang.format("0x$1$:$2$", [ival.format("%x"), vtn]);
    } else if (vtn.equals("f32") || vtn.equals("f64")) {
        var str = fval.format("%.7f");
        if (str.find(".") == -1) {
            return Lang.format("$1$:$2$", [fval.format("%f"), vtn]);
        } else {
            return Lang.format("$1$:$2$", [str, vtn]);
        }
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
            localTypes.add(VALUE_TYPE[f.locals[i]]);
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

function dumpStacks(sp as Number, stack as Array, fp as Number, csp as Number, callstack as Array) as Void {
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


function doCall(stack as StackType, callstack as CallStackType, sp as Number, fp as Number, csp as Number, func as Function, pc as Number, indirect as Boolean) as Array<Number> {
    // Push block, stack size and return address onto callstack
    var t = func.type;
    csp += 1;
    callstack[csp] = [func, sp - t.params.size(), fp, pc];

    // Update the pos/instruction counter to the function
    pc = func.start;

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

function doCallImport(stack as StackType, sp as Number, memory as Memory, importFunction as ImportFunctionType, func as FunctionImport) as Number {
    var t = func.type;

    var args = [] as Array<Array<Number>>;
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



function getLocationStr(opcode as Number, pc as Number, code as Array<Number>, function_ as Array, table as Dictionary, blockMap as Dictionary) as String {
    return "0x" + pc.format("%x") + " " + OPERATOR_INFO[opcode][0] + "(0x" + opcode.format("%x") + ")";
}

function getBlock(blockMap as Dictionary, pc as Number) as Block {
    return blockMap[pc];
}

function getFunction(function_ as Array, fidx as Number) as Function {
    return function_[fidx];
}

function boundViolation(opcode as Number, addr as Number, pages as Number) as Boolean {
    return addr < 0 || addr + LOAD_SIZE[opcode] > pages * (1 << 16);
}

function getFromTable(table as Dictionary, tidx as Number, tableIndex as Number) as Number {
    var tbl = table[tidx] as Array<Number>;
    if (tableIndex < 0 || tableIndex >= tbl.size()) {
        throw new WAException("undefined element");
    }
    return tbl[tableIndex];
}

function interpretMvp(module_, 
        // greens
        pc, code, function_, table, blockMap, 
        // reds
        memory, sp, stack, fp, csp, callstack
    ) as [Number, Number, Number, Number] {
    while (pc < code.size()) {
        var opcode = code[pc];
        var curPc = pc;
        pc += 1;

        if (TRACE) {
            dumpStacks(sp, stack, fp, csp, callstack);
            var immediates = skipImmediates(code, curPc)[1];
            var immediateParts = [];
            for (var i = 0; i < immediates.size(); i++) {
                immediateParts.add("0x" + immediates[i].format("%x"));
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
            var block = getBlock(blockMap, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            if (TRACE) { debug("      - block: " + blockRepr(block)); }
        } else if (opcode == 0x03) {  // loop
            var blockType = read_LEB(code, pc,  32, null);
            pc = blockType[0];
            var block = getBlock(blockMap, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            if (TRACE) { debug("      - block: " + blockRepr(block)); }
        } else if (opcode == 0x04) {  // if
            var blockType = read_LEB(code, pc,  32, null);
            pc = blockType[0];
            var block = getBlock(blockMap, curPc);
            csp += 1;
            callstack[csp] = [block, sp, fp, 0];
            var cond = stack[sp];
            sp -= 1;
            if (!cond[1]) {  // if false (I32)
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
            if (cond[1]) {  // I32
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
            var func = getFunction(function_, fidx[1]);

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
                sp = doCallImport(stack, sp, memory, module_.importFunction, func);
            } else if (func instanceof Function) {
                var callResult = doCall(stack, callstack, sp, fp, csp, func, pc);
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
            var fidx = getFromTable(table, ANYFUNC, tableIndex);
            if (VALIDATE) { assert(csp < CALLSTACK_SIZE, "call stack exhausted"); }
            var func = getFunction(function_, fidx);
            if (VALIDATE && func.type.mask != module_.type[tidx[1]].mask) {
                throw new WAException("indirect call type mismatch (call type " + func.type.index + " and function type " + tidx[1] + " differ");
            }
            var callResult = doCall(stack, callstack, sp, fp, csp, func, pc, true);
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
            if (cond[1]) {  // I32
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

//         elif 0x28 <= opcode <= 0x35:
//             pc, flags = read_LEB(code, pc,  32, null)
//             pc, offset = read_LEB(code, pc,  32, null)
//             addr_val = stack[sp]
//             sp -= 1
//             if flags != 2:
//                 if TRACE:
//                     info("      - unaligned load - flags: 0x%x,"
//                          " offset: 0x%x, addr: 0x%x" % (
//                              flags, offset, addr_val[1]))
//             addr = addr_val[1] + offset
//             if bound_violation(opcode, addr, memory.pages):
//                 raise WAException("out of bounds memory access")
//             assert addr >= 0
//             if   0x28 == opcode:  # i32.load
//                 res = (I32, bytes2uint32(memory.bytes[addr:addr+4]), 0.0)
//             elif 0x29 == opcode:  # i64.load
//                 res = (I64, bytes2uint64(memory.bytes[addr:addr+8]), 0.0)
//             elif 0x2a == opcode:  # f32.load
//                 res = (F32, 0, read_F32(memory.bytes, addr))
//             elif 0x2b == opcode:  # f64.load
//                 res = (F64, 0, read_F64(memory.bytes, addr))
//             elif 0x2c == opcode:  # i32.load8_s
//                 res = (I32, bytes2int8(memory.bytes[addr:addr+1]), 0.0)
//             elif 0x2d == opcode:  # i32.load8_u
//                 res = (I32, memory.bytes[addr], 0.0)
//             elif 0x2e == opcode:  # i32.load16_s
//                 res = (I32, bytes2int16(memory.bytes[addr:addr+2]), 0.0)
//             elif 0x2f == opcode:  # i32.load16_u
//                 res = (I32, bytes2uint16(memory.bytes[addr:addr+2]), 0.0)
//             elif 0x30 == opcode:  # i64.load8_s
//                 res = (I64, bytes2int8(memory.bytes[addr:addr+1]), 0.0)
//             elif 0x31 == opcode:  # i64.load8_u
//                 res = (I64, memory.bytes[addr], 0.0)
//             elif 0x32 == opcode:  # i64.load16_s
//                 res = (I64, bytes2int16(memory.bytes[addr:addr+2]), 0.0)
//             elif 0x33 == opcode:  # i64.load16_u
//                 res = (I64, bytes2uint16(memory.bytes[addr:addr+2]), 0.0)
//             elif 0x34 == opcode:  # i64.load32_s
//                 res = (I64, bytes2int32(memory.bytes[addr:addr+4]), 0.0)
//             elif 0x35 == opcode:  # i64.load32_u
//                 res = (I64, bytes2uint32(memory.bytes[addr:addr+4]), 0.0)
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             sp += 1
//             stack[sp] = res

//         # Memory store operators
//         elif 0x36 <= opcode <= 0x3e:
//             pc, flags = read_LEB(code, pc,  32, null)
//             pc, offset = read_LEB(code, pc,  32, null)
//             val = stack[sp]
//             sp -= 1
//             addr_val = stack[sp]
//             sp -= 1
//             if flags != 2:
//                 if TRACE:
//                     info("      - unaligned store - flags: 0x%x,"
//                          " offset: 0x%x, addr: 0x%x, val: 0x%x" % (
//                              flags, offset, addr_val[1], val[1]))
//             addr = addr_val[1] + offset
//             if bound_violation(opcode, addr, memory.pages):
//                 raise WAException("out of bounds memory access")
//             assert addr >= 0
//             if   0x36 == opcode:  # i32.store
//                 write_I32(memory.bytes, addr, val[1])
//             elif 0x37 == opcode:  # i64.store
//                 write_I64(memory.bytes, addr, val[1])
//             elif 0x38 == opcode:  # f32.store
//                 write_F32(memory.bytes, addr, val[2])
//             elif 0x39 == opcode:  # f64.store
//                 write_F64(memory.bytes, addr, val[2])
//             elif 0x3a == opcode:  # i32.store8
//                 memory.bytes[addr] = val[1] & 0xff
//             elif 0x3b == opcode:  # i32.store16
//                 memory.bytes[addr]   =  val[1] & 0x00ff
//                 memory.bytes[addr+1] = (val[1] & 0xff00)>>8
//             elif 0x3c == opcode:  # i64.store8
//                 memory.bytes[addr]   =  val[1] & 0xff
//             elif 0x3d == opcode:  # i64.store16
//                 memory.bytes[addr]   =  val[1] & 0x00ff
//                 memory.bytes[addr+1] = (val[1] & 0xff00)>>8
//             elif 0x3e == opcode:  # i64.store32
//                 memory.bytes[addr]   =  val[1] & 0x000000ff
//                 memory.bytes[addr+1] = (val[1] & 0x0000ff00)>>8
//                 memory.bytes[addr+2] = (val[1] & 0x00ff0000)>>16
//                 memory.bytes[addr+3] = (val[1] & 0xff000000)>>24
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))

//         # Memory size operators
//         elif 0x3f == opcode:  # current_memory
//             pc, reserved = read_LEB(code, pc,  1, null)
//             sp += 1
//             stack[sp] = (I32, module_.memory.pages, 0.0)
//             if TRACE:
//                 debug("      - current 0x%x" % module_.memory.pages)
//         elif 0x40 == opcode:  # grow_memory
//             pc, reserved = read_LEB(code, pc,  1, null)
//             prev_size = module_.memory.pages
//             delta = stack[sp][1]  # I32
//             module_.memory.grow(delta)
//             stack[sp] = (I32, prev_size, 0.0)
//             debug("      - delta 0x%x, prev: 0x%x" % (
//                 delta, prev_size))

//         #
//         # Constants
//         #
//         elif 0x41 == opcode:  # i32.const
//             pc, val = read_LEB(code, pc, 32, signed=True)
//             sp += 1
//             stack[sp] = (I32, val, 0.0)
//             if TRACE: debug("      - %s" % value_repr(stack[sp]))
//         elif 0x42 == opcode:  # i64.const
//             pc, val = read_LEB(code, pc, 64, signed=True)
//             sp += 1
//             stack[sp] = (I64, val, 0.0)
//             if TRACE: debug("      - %s" % value_repr(stack[sp]))
//         elif 0x43 == opcode:  # f32.const
//             sp += 1
//             stack[sp] = (F32, 0, read_F32(code, pc))
//             pc += 4
//             if TRACE: debug("      - %s" % value_repr(stack[sp]))
//         elif 0x44 == opcode:  # f64.const
//             sp += 1
//             stack[sp] = (F64, 0, read_F64(code, pc))
//             pc += 8
//             if TRACE: debug("      - %s" % value_repr(stack[sp]))

//         #
//         # Comparison operators
//         #

//         # unary
//         elif opcode in [0x45, 0x50]:
//             a = stack[sp]
//             sp -= 1
//             if   0x45 == opcode: # i32.eqz
//                 if VALIDATE: assert a[0] == I32
//                 res = (I32, a[1] == 0, 0.0)
//             elif 0x50 == opcode: # i64.eqz
//                 if VALIDATE: assert a[0] == I64
//                 res = (I32, a[1] == 0, 0.0)
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s) = %s" % (
//                     value_repr(a), value_repr(res)))
//             sp += 1
//             stack[sp] = res

//         # binary
//         elif 0x46 <= opcode <= 0x66:
//             a, b = stack[sp-1], stack[sp]
//             sp -= 2
//             if   0x46 == opcode: # i32.eq
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, a[1] == b[1], 0.0)
//             elif 0x47 == opcode: # i32.ne
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, a[1] != b[1], 0.0)
//             elif 0x48 == opcode: # i32.lt_s
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2int32(a[1]) < int2int32(b[1]), 0.0)
//             elif 0x49 == opcode: # i32.lt_u
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2uint32(a[1]) < int2uint32(b[1]), 0.0)
//             elif 0x4a == opcode: # i32.gt_s
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2int32(a[1]) > int2int32(b[1]), 0.0)
//             elif 0x4b == opcode: # i32.gt_u
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2uint32(a[1]) > int2uint32(b[1]), 0.0)
//             elif 0x4c == opcode: # i32.le_s
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2int32(a[1]) <= int2int32(b[1]), 0.0)
//             elif 0x4d == opcode: # i32.le_u
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2uint32(a[1]) <= int2uint32(b[1]), 0.0)
//             elif 0x4e == opcode: # i32.ge_s
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2int32(a[1]) >= int2int32(b[1]), 0.0)
//             elif 0x4f == opcode: # i32.ge_u
//                 if VALIDATE: assert a[0] == I32 and b[0] == I32
//                 res = (I32, int2uint32(a[1]) >= int2uint32(b[1]), 0.0)
//             elif 0x51 == opcode: # i64.eq
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, a[1] == b[1], 0.0)
//             elif 0x52 == opcode: # i64.ne
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, a[1] != b[1], 0.0)
//             elif 0x53 == opcode: # i64.lt_s
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2int64(a[1]) < int2int64(b[1]), 0.0)
//             elif 0x54 == opcode: # i64.lt_u
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2uint64(a[1]) < int2uint64(b[1]), 0.0)
//             elif 0x55 == opcode: # i64.gt_s
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2int64(a[1]) > int2int64(b[1]), 0.0)
//             elif 0x56 == opcode: # i64.gt_u
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2uint64(a[1]) > int2uint64(b[1]), 0.0)
//             elif 0x57 == opcode: # i64.le_s
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2int64(a[1]) <= int2int64(b[1]), 0.0)
//             elif 0x58 == opcode: # i64.le_u
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2uint64(a[1]) <= int2uint64(b[1]), 0.0)
//             elif 0x59 == opcode: # i64.ge_s
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2int64(a[1]) >= int2int64(b[1]), 0.0)
//             elif 0x5a == opcode: # i64.ge_u
//                 if VALIDATE: assert a[0] == I64 and b[0] == I64
//                 res = (I32, int2uint64(a[1]) >= int2uint64(b[1]), 0.0)
//             elif 0x5b == opcode: # f32.eq
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] == b[2], 0.0)
//             elif 0x5c == opcode: # f32.ne
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] != b[2], 0.0)
//             elif 0x5d == opcode: # f32.lt
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] < b[2], 0.0)
//             elif 0x5e == opcode: # f32.gt
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] > b[2], 0.0)
//             elif 0x5f == opcode: # f32.le
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] <= b[2], 0.0)
//             elif 0x60 == opcode: # f32.ge
//                 if VALIDATE: assert a[0] == F32 and b[0] == F32
//                 res = (I32, a[2] >= b[2], 0.0)
//             elif 0x61 == opcode: # f64.eq
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] == b[2], 0.0)
//             elif 0x62 == opcode: # f64.ne
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] != b[2], 0.0)
//             elif 0x63 == opcode: # f64.lt
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] < b[2], 0.0)
//             elif 0x64 == opcode: # f64.gt
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] > b[2], 0.0)
//             elif 0x65 == opcode: # f64.le
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] <= b[2], 0.0)
//             elif 0x66 == opcode: # f64.ge
//                 if VALIDATE: assert a[0] == F64 and b[0] == F64
//                 res = (I32, a[2] >= b[2], 0.0)
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s, %s) = %s" % (
//                     value_repr(a), value_repr(b), value_repr(res)))
//             sp += 1
//             stack[sp] = res

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

//         # i64 binary
//         elif 0x7c <= opcode <= 0x8a:
//             a, b = stack[sp-1], stack[sp]
//             sp -= 2
//             if VALIDATE: assert a[0] == I64 and b[0] == I64
//             if   0x7c == opcode: # i64.add
//                 res = (I64, int2int64(a[1] + b[1]), 0.0)
//             elif 0x7d == opcode: # i64.sub
//                 res = (I64, a[1] - b[1], 0.0)
//             elif 0x7e == opcode: # i64.mul
//                 res = (I64, int2int64(a[1] * b[1]), 0.0)
//             elif 0x7f == opcode: # i64.div_s
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
// #                elif a[1] == 0x8000000000000000 and b[1] == -1:
// #                    raise WAException("integer overflow")
//                 else:
//                     res = (I64, idiv_s(int2int64(a[1]), int2int64(b[1])), 0.0)
//             elif 0x80 == opcode: # i64.div_u
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     if a[1] < 0 and b[1] > 0:
//                         res = (I64, int2uint64(-a[1]) / int2uint64(b[1]), 0.0)
//                     elif a[1] > 0 and b[1] < 0:
//                         res = (I64, int2uint64(a[1]) / int2uint64(-b[1]), 0.0)
//                     else:
//                         res = (I64, int2uint64(a[1]) / int2uint64(b[1]), 0.0)
//             elif 0x81 == opcode: # i64.rem_s
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     res = (I64, irem_s(int2int64(a[1]), int2int64(b[1])), 0.0)
//             elif 0x82 == opcode: # i64.rem_u
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     res = (I64, int2uint64(a[1]) % int2uint64(b[1]), 0.0)
//             elif 0x83 == opcode: # i64.and
//                 res = (I64, a[1] & b[1], 0.0)
//             elif 0x84 == opcode: # i64.or
//                 res = (I64, a[1] | b[1], 0.0)
//             elif 0x85 == opcode: # i64.xor
//                 res = (I64, a[1] ^ b[1], 0.0)
//             elif 0x86 == opcode: # i64.shl
//                 res = (I64, a[1] << (b[1] % 0x40), 0.0)
//             elif 0x87 == opcode: # i64.shr_s
//                 res = (I64, int2int64(a[1]) >> (b[1] % 0x40), 0.0)
//             elif 0x88 == opcode: # i64.shr_u
//                 res = (I64, int2uint64(a[1]) >> (b[1] % 0x40), 0.0)
// #            elif 0x89 == opcode: # i64.rotl
// #                res = (I64, rotl64(a[1], b[1]), 0.0)
// #            elif 0x8a == opcode: # i64.rotr
// #                res = (I64, rotr64(a[1], b[1]), 0.0)
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s, %s) = %s" % (
//                     value_repr(a), value_repr(b), value_repr(res)))
//             sp += 1
//             stack[sp] = res

//         # f32 binary operations
//         elif 0x92 <= opcode <= 0x98:
//             a, b = stack[sp-1], stack[sp]
//             sp -= 2
//             if VALIDATE: assert a[0] == F32 and b[0] == F32
//             if   0x92 == opcode: # f32.add
//                 res = (F32, 0, a[2] + b[2])
//             elif 0x93 == opcode: # f32.sub
//                 res = (F32, 0, a[2] - b[2])
//             elif 0x94 == opcode: # f32.mul
//                 res = (F32, 0, a[2] * b[2])
//             elif 0x95 == opcode: # f32.div
//                 res = (F32, 0, a[2] / b[2])
//             elif 0x96 == opcode: # f32.min
//                 if a[2] < b[2]:
//                     res = (F32, 0, a[2])
//                 else:
//                     res = (F32, 0, b[2])
//             elif 0x97 == opcode: # f32.max
//                 if a[2] == b[2] == 0.0:
//                     res = (F32, 0, 0.0)
//                 elif a[2] > b[2]:
//                     res = (F32, 0, a[2])
//                 else:
//                     res = (F32, 0, b[2])
//             elif 0x98 == opcode: # f32.copysign
//                 if b[2] > 0:
//                     res = (F32, 0, abs(a[2]))
//                 else:
//                     res = (F32, 0, -abs(a[2]))
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s, %s) = %s" % (
//                     value_repr(a), value_repr(b), value_repr(res)))
//             sp += 1
//             stack[sp] = res

//         # f64 binary operations
//         elif 0xa0 <= opcode <= 0xa6:
//             a, b = stack[sp-1], stack[sp]
//             sp -= 2
//             if VALIDATE: assert a[0] == F64 and b[0] == F64
//             if   0xa0 == opcode: # f64.add
//                 res = (F64, 0, a[2] + b[2])
//             elif 0xa1 == opcode: # f64.sub
//                 res = (F64, 0, a[2] - b[2])
//             elif 0xa2 == opcode: # f64.mul
//                 res = (F64, 0, a[2] * b[2])
//             elif 0xa3 == opcode: # f64.div
//                 if b[2] == 0.0:
//                     aneg = str(a[2])[0] == '-'
//                     bneg = str(b[2])[0] == '-'
//                     if (aneg and not bneg) or (not aneg and bneg):
//                         res = (F64, 0, float_fromhex('-inf'))
//                     else:
//                         res = (F64, 0, float_fromhex('inf'))
//                 else:
//                     res = (F64, 0, a[2] / b[2])
//             elif 0xa4 == opcode: # f64.min
//                 if a[2] < b[2]:
//                     res = (F64, 0, a[2])
// # Adding the 0.0 checks causes this error during compilation:
// #   File "/opt/pypy/rpython/jit/codewriter/assembler.py", line 230, in check_result
// #       assert self.count_regs['int'] + len(self.constants_i) <= 256

// #                elif b[2] == 0.0:
// #                    if str(a[2])[0] == '-':
// #                        res = (F64, 0, a[2])
// #                    else:
// #                        res = (F64, 0, b[2])
//                 else:
//                     res = (F64, 0, b[2])
//             elif 0xa5 == opcode: # f64.max
//                 if a[2] > b[2]:
//                     res = (F64, 0, a[2])
// #                elif b[2] == 0.0:
// #                    if str(a[2])[0] == '-':
// #                        res = (F64, 0, b[2])
// #                    else:
// #                        res = (F64, 0, a[2])
//                 else:
//                     res = (F64, 0, b[2])
//             elif 0xa6 == opcode: # f64.copysign
//                 if b[2] > 0:
//                     res = (F64, 0, abs(a[2]))
//                 else:
//                     res = (F64, 0, -abs(a[2]))
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s, %s) = %s" % (
//                     value_repr(a), value_repr(b), value_repr(res)))
//             sp += 1
//             stack[sp] = res

//         ## conversion operations
//         elif 0xa7 <= opcode <= 0xbb:
//             a = stack[sp]
//             sp -= 1

//             # conversion operations
//             if   0xa7 == opcode: # i32.wrap_i64
//                 if VALIDATE: assert a[0] == I64
//                 res = (I32, int2int32(a[1]), 0.0)
//             elif 0xa8 == opcode: # i32.trunc_f32_s
//                 if VALIDATE: assert a[0] == F32
//                 if math.isnan(a[2]):
//                     raise WAException("invalid conversion to integer")
//                 elif a[2] > 2147483647.0:
//                     raise WAException("integer overflow")
//                 elif a[2] < -2147483648.0:
//                     raise WAException("integer overflow")
//                 res = (I32, int(a[2]), 0.0)
// #            elif 0xa9 == opcode: # i32.trunc_f32_u
// #                if VALIDATE: assert a[0] == F32
// #                if math.isnan(a[2]):
// #                    raise WAException("invalid conversion to integer")
// #                elif a[2] > 4294967295.0:
// #                    raise WAException("integer overflow")
// #                elif a[2] <= -1.0:
// #                    raise WAException("integer overflow")
// #                res = (I32, int(a[2]), 0.0)
// #            elif 0xaa == opcode: # i32.trunc_f64_s
// #                if VALIDATE: assert a[0] == F64
// #                if math.isnan(a[2]):
// #                    raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**31-1:
// #                    raise WAException("integer overflow")
// #                elif a[2] < -2**31:
// #                    raise WAException("integer overflow")
// #                res = (I32, int(a[2]), 0.0)
// #            elif 0xab == opcode: # i32.trunc_f64_u
// #                if VALIDATE: assert a[0] == F64
// #                debug("*** a[2]: %s" % a[2])
// #                if math.isnan(a[2]):
// #                    raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**32-1:
// #                    raise WAException("integer overflow")
// #                elif a[2] <= -1.0:
// #                    raise WAException("integer overflow")
// #                res = (I32, int(a[2]), 0.0)
//             elif 0xac == opcode: # i64.extend_i32_s
//                 if VALIDATE: assert a[0] == I32
//                 res = (I64, int2int32(a[1]), 0.0)
//             elif 0xad == opcode: # i64.extend_i32_u
//                 if VALIDATE: assert a[0] == I32
//                 res = (I64, intmask(a[1]), 0.0)
// #            elif 0xae == opcode: # i64.trunc_f32_s
// #                if VALIDATE: assert a[0] == F32
// #                if math.isnan(a[2]):
// #                    raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**63-1:
// #                    raise WAException("integer overflow")
// #                elif a[2] < -2**63:
// #                    raise WAException("integer overflow")
// #                res = (I64, int(a[2]), 0.0)
// #            elif 0xaf == opcode: # i64.trunc_f32_u
// #                if VALIDATE: assert a[0] == F32
// #                if math.isnan(a[2]):
// #                    raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**63-1:
// #                    raise WAException("integer overflow")
// #                elif a[2] <= -1.0:
// #                    raise WAException("integer overflow")
// #                res = (I64, int(a[2]), 0.0)
//             elif 0xb0 == opcode: # i64.trunc_f64_s
//                 if VALIDATE: assert a[0] == F64
//                 if math.isnan(a[2]):
//                     raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**63-1:
// #                    raise WAException("integer overflow")
// #                elif a[2] < -2**63:
// #                    raise WAException("integer overflow")
//                 res = (I64, int(a[2]), 0.0)
//             elif 0xb1 == opcode: # i64.trunc_f64_u
//                 if VALIDATE: assert a[0] == F64
//                 if math.isnan(a[2]):
//                     raise WAException("invalid conversion to integer")
// #                elif a[2] > 2**63-1:
// #                    raise WAException("integer overflow")
//                 elif a[2] <= -1.0:
//                     raise WAException("integer overflow")
//                 res = (I64, int(a[2]), 0.0)
//             elif 0xb2 == opcode: # f32.convert_i32_s
//                 if VALIDATE: assert a[0] == I32
//                 res = (F32, 0, float(a[1]))
//             elif 0xb3 == opcode: # f32.convert_i32_u
//                 if VALIDATE: assert a[0] == I32
//                 res = (F32, 0, float(int2uint32(a[1])))
//             elif 0xb4 == opcode: # f32.convert_i64_s
//                 if VALIDATE: assert a[0] == I64
//                 res = (F32, 0, float(a[1]))
//             elif 0xb5 == opcode: # f32.convert_i64_u
//                 if VALIDATE: assert a[0] == I64
//                 res = (F32, 0, float(int2uint64(a[1])))
// #            elif 0xb6 == opcode: # f32.demote_f64
// #                if VALIDATE: assert a[0] == F64
// #                res = (F32, 0, unpack_f32(pack_f32(a[2])))
//             elif 0xb7 == opcode: # f64.convert_i32_s
//                 if VALIDATE: assert a[0] == I32
//                 res = (F64, 0, float(a[1]))
//             elif 0xb8 == opcode: # f64.convert_i32_u
//                 if VALIDATE: assert a[0] == I32
//                 res = (F64, 0, float(int2uint32(a[1])))
//             elif 0xb9 == opcode: # f64.convert_i64_s
//                 if VALIDATE: assert a[0] == I64
//                 res = (F64, 0, float(a[1]))
//             elif 0xba == opcode: # f64.convert_i64_u
//                 if VALIDATE: assert a[0] == I64
//                 res = (F64, 0, float(int2uint64(a[1])))
//             elif 0xbb == opcode: # f64.promote_f32
//                 if VALIDATE: assert a[0] == F32
//                 res = (F64, 0, a[2])
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s) = %s" % (
//                     value_repr(a), value_repr(res)))
//             sp += 1
//             stack[sp] = res

//         ## reinterpretations
//         elif 0xbc <= opcode <= 0xbf:
//             a = stack[sp]
//             sp -= 1

//             if   0xbc == opcode: # i32.reinterpret_f32
//                 if VALIDATE: assert a[0] == F32
//                 res = (I32, intmask(pack_f32(a[2])), 0.0)
//             elif 0xbd == opcode: # i64.reinterpret_f64
//                 if VALIDATE: assert a[0] == F64
//                 res = (I64, intmask(pack_f64(a[2])), 0.0)
// #            elif 0xbe == opcode: # f32.reinterpret_i32
// #                if VALIDATE: assert a[0] == I32
// #                res = (F32, 0, unpack_f32(int2int32(a[1])))
//             elif 0xbf == opcode: # f64.reinterpret_i64
//                 if VALIDATE: assert a[0] == I64
//                 res = (F64, 0, unpack_f64(int2int64(a[1])))
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s) = %s" % (
//                     value_repr(a), value_repr(res)))
//             sp += 1
//             stack[sp] = res
        else {
            throw new WAException("unrecognized opcode 0x" + opcode.format("%x"));
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
    private var importFunction as ImportFunctionType;

    // Sections
    private var type as Array<Type>;
    private var importList as Array<Import>;
    var function_ as Array<Function>;
    // private var fnImportCnt as Number;
    private var table as Dictionary<Number, Array<Number>>;
    private var exportList as Array<Export>;
    private var exportMap as Dictionary<String, Export>;
    private var globalList as Array<Global>;

    private var memory as Memory;

    // // block/loop/if blocks {start addr: Block, ...}
    private var blockMap as Dictionary<Number, Block>;

    // Execution state
    var sp as Number;
    private var fp as Number;
    var stack as StackType;
    private var csp as Number;
    private var callstack as CallStackType;
    private var startFunction as Number;

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
            exportMap as Dictionary<String, Export>
            ) {
        self.data = data;
        self.rdr = new Reader(data);
        // self.importValue = importValue;
        self.importFunction = importFunction;

        // Initialize sections
        self.type = types;
        self.importList = [];
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

        self.blockMap = {};

        // Initialize execution state
        self.sp = -1;
        self.fp = -1;
        self.stack = new [STACK_SIZE];
        for (var i = 0; i < STACK_SIZE; i++) {
            self.stack[i] = [0x00, 0, 0.0];
        }
        self.csp = -1;
        var block = new Block(0x00, BLOCK_TYPE[I32], 0);
        self.callstack = new [CALLSTACK_SIZE];
        for (var i = 0; i < CALLSTACK_SIZE; i++) {
            self.callstack[i] = [block, -1, -1, 0];
        }
        self.startFunction = -1;

        // readMagic();
        // readVersion();
        // readSections();

        dump();

        // // Run the start function if set
        // if (self.startFunction >= 0) {
        //     var fidx = self.startFunction;
        //     var func = self.function_[fidx];
        //     System.println("Running start function 0x" + fidx.format("%x"));
        //     if (TRACE) {
        //         dumpStacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        //     }
        //     if (func instanceof FunctionImport) {
        //         sp = doCallImport(self.stack, self.sp, self.memory, self.importFunction, func);
        //     } else if (func instanceof Function) {
        //         var result = doCall(self.stack, self.callstack, self.sp, self.fp, self.csp, func, self.rdr.bytes.size());
        //         self.rdr.pos = result[0];
        //         self.sp = result[1];
        //         self.fp = result[2];
        //         self.csp = result[3];
        //     }
        //     interpret();
        // }
    }

    public function dump() as Void {
        debug("module bytes: " + byteCodeRepr(self.rdr.bytes));
        info("");

        info("Types:");
        for (var i = 0; i < self.type.size(); i++) {
            info("  0x" + i.format("%x") + " " + type_repr(self.type[i]));
        }

        info("Imports:");
        for (var i = 0; i < self.importList.size(); i++) {
            var imp = self.importList[i];
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
                    entryStrings.add(entries[j].format("%x"));
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

        var blockKeys = self.blockMap.keys();
        blockKeys.sort(null);
        var blockMapStrings = [];
        for (var i = 0; i < blockKeys.size(); i++) {
            var k = blockKeys[i];
            var bl = self.blockMap[k];
            blockMapStrings.add(blockRepr(bl) + "[0x" + bl.start.format("%x") + "->0x" + bl.end.format("%x") + "]");
        }
        info("block_map: [" + join(blockMapStrings, ", ") + "]");
        info("");
    }

    function hexpad(x as Number, cnt as Number) as String {
        return x.format("%0" + cnt + "x");
    }

    public function interpret() as Void {
        var result = interpretMvp(self,
            // Greens
            self.rdr.pos, self.rdr.bytes, self.function_,
            self.table, self.blockMap,
            // Reds
            self.memory, self.sp, self.stack, self.fp, self.csp,
            self.callstack);
        
        self.rdr.pos = result[0];
        self.sp = result[1];
        self.fp = result[2];
        self.csp = result[3];
    }

    public function run(fname as String, args as Array<Array<Number>>, printReturn as Boolean, returnValue as Boolean) as Number | ValueTupleType {
        // Reset stacks
        self.sp = -1;
        self.fp = -1;
        self.csp = -1;

        var fidx = self.exportMap[fname].index;

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
            dumpStacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        }
        var result = doCall(self.stack, self.callstack, self.sp, self.fp, self.csp, self.function_[fidx], 0, false);
        self.rdr.pos = result[0];
        self.sp = result[1];
        self.fp = result[2];
        self.csp = result[3];

        interpret();
        if (TRACE) {
            dumpStacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
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

// def host_putchar(mem, args):
//     assert len(args) == 1
//     assert args[0][0] == I32
//     char_code = args[0][1]
//     os.write(1, bytes([char_code]))
//     return [(I32, char_code, 0.0)]

// def import_function(module, field, mem, args):
//     fname = "%s.%s" % (module, field)
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
//     elif fname == "host.putchar":
//         return host_putchar(mem, args)
//     else:
//         raise Exception("function import %s not found" % (fname))

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