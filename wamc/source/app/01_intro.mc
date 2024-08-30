import Toybox.Lang;
import Toybox.System;

// var INFO  = false; // informational logging
// var TRACE = false; // trace instructions/stacks
// var DEBUG = false; // verbose logging
var INFO  = true;
var TRACE = true;
var DEBUG = true;
var VALIDATE = true;

// def do_sort(a):
//     a.sort(null)

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
