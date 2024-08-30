import Toybox.Lang;
import Toybox.System;

// ######################################
// General Functions
// ######################################

function assert(condition as Boolean) as Void {
    if (!condition) {
        throw new WAException("Assertion failed");
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
        System.println("DEBUG: " + str);
    }
}

function debugWithEnd(str, end) {
    if (DEBUG) {
        if (end == null) {
            end = "\n";
        }
        System.println("DEBUG: " + str + end);
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

function unpack_nan32(i32) {
    throw new NotImplementedException();
    // return Float32.fromBits(i32);
}

function unpack_nan64(i64) {
    throw new NotImplementedException();
    // return Float64.fromBits(i64);
}

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
    assert(pos >= 0);
    return bytes.decodeNumber(Lang.NUMBER_FORMAT_SINT32, { :offset => pos });
}

function read_I64(bytes, pos) {
    assert(pos >= 0);
    return bytes2uint64(bytes.slice(pos, pos + 8));
}

function read_F32(bytes, pos) {
    assert(pos >= 0);
    var num = bytes.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, { :offset => pos });
    if (isNaN(num)) {return num; }
    return fround(num, 5);
}

function read_F64(bytes, pos) {
    assert(pos >= 0);
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


function valueRepr(val as Array) as String {
    var vt = val[0];
    var ival = val[1];
    var fval = val[2];
    var vtn = VALUE_TYPE[vt];
    
    if (vtn.equals("i32") || vtn.equals("i64")) {
        return Lang.format("$1$:$2$", [ival.format("%x"), vtn]);
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

function typeRepr(t as Type) as String {
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

function exportRepr(e as Export) as String {
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
        res.add(valueRepr(stack[i]));
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
            throw new WAException("call signature mismatch: " + VALUE_TYPE[t.results[0]] + " != " + VALUE_TYPE[save[0]] + " (" + valueRepr(save) + ")");
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
                 join(immediateParts, ","));
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
                debug("      - cond: " + valueRepr(cond) + " jump to 0x" + pc.format("%x") + ", block: " + blockRepr(block));
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
            if (TRACE) { debug("      - dropping: " + valueRepr(stack[sp])); }
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
                debug("      - cond: 0x" + cond[1].format("%x") + ", selected: " + valueRepr(stack[sp]));
            }
        }

        // Variable access
        else if (opcode == 0x20) {  // get_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            sp += 1;
            stack[sp] = stack[fp+arg[1]];
            if (TRACE) { debug("      - got " + valueRepr(stack[sp])); }
        } else if (opcode == 0x21) {  // set_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            var val = stack[sp];
            sp -= 1;
            stack[fp+arg[1]] = val;
            if (TRACE) { debug("      - to " + valueRepr(val)); }
        } else if (opcode == 0x22) {  // tee_local
            var arg = read_LEB(code, pc,  32, null);
            pc = arg[0];
            var val = stack[sp]; // like set_local but do not pop
            stack[fp+arg[1]] = val;
            if (TRACE) { debug("      - to " + valueRepr(val)); }
        } else if (opcode == 0x23) {  // get_global
            var gidx = read_LEB(code, pc,  32, null);
            pc = gidx[0];
            sp += 1;
            stack[sp] = module_.globalList[gidx[1]];
            if (TRACE) { debug("      - got " + valueRepr(stack[sp])); }
        } else if (opcode == 0x24) {  // set_global
            var gidx = read_LEB(code, pc,  32, null);
            pc = gidx[0];
            var val = stack[sp];
            sp -= 1;
            module_.globalList[gidx[1]] = val;
            if (TRACE) { debug("      - to " + valueRepr(val)); }
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

//         # i32 binary
//         elif 0x6a <= opcode <= 0x78:
//             a, b = stack[sp-1], stack[sp]
//             sp -= 2
//             if VALIDATE: assert a[0] == I32 and b[0] == I32
//             if   0x6a == opcode: # i32.add
//                 res = (I32, int2int32(a[1] + b[1]), 0.0)
//             elif 0x6b == opcode: # i32.sub
//                 res = (I32, a[1] - b[1], 0.0)
//             elif 0x6c == opcode: # i32.mul
//                 res = (I32, int2int32(a[1] * b[1]), 0.0)
//             elif 0x6d == opcode: # i32.div_s
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 elif a[1] == 0x80000000 and b[1] == -1:
//                     raise WAException("integer overflow")
//                 else:
//                     res = (I32, idiv_s(int2int32(a[1]), int2int32(b[1])), 0.0)
//             elif 0x6e == opcode: # i32.div_u
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     res = (I32, int2uint32(a[1]) / int2uint32(b[1]), 0.0)
//             elif 0x6f == opcode: # i32.rem_s
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     res = (I32, irem_s(int2int32(a[1]), int2int32(b[1])), 0.0)
//             elif 0x70 == opcode: # i32.rem_u
//                 if b[1] == 0:
//                     raise WAException("integer divide by zero")
//                 else:
//                     res = (I32, int2uint32(a[1]) % int2uint32(b[1]), 0.0)
//             elif 0x71 == opcode: # i32.and
//                 res = (I32, a[1] & b[1], 0.0)
//             elif 0x72 == opcode: # i32.or
//                 res = (I32, a[1] | b[1], 0.0)
//             elif 0x73 == opcode: # i32.xor
//                 res = (I32, a[1] ^ b[1], 0.0)
//             elif 0x74 == opcode: # i32.shl
//                 res = (I32, a[1] << (b[1] % 0x20), 0.0)
//             elif 0x75 == opcode: # i32.shr_s
//                 res = (I32, int2int32(a[1]) >> (b[1] % 0x20), 0.0)
//             elif 0x76 == opcode: # i32.shr_u
//                 res = (I32, int2uint32(a[1]) >> (b[1] % 0x20), 0.0)
//             elif 0x77 == opcode: # i32.rotl
//                 res = (I32, rotl32(a[1], b[1]), 0.0)
//             elif 0x78 == opcode: # i32.rotr
//                 res = (I32, rotr32(a[1], b[1]), 0.0)
//             else:
//                 raise WAException("%s(0x%x) unimplemented" % (
//                     OPERATOR_INFO[opcode][0], opcode))
//             if TRACE:
//                 debug("      - (%s, %s) = %s" % (
//                     value_repr(a), value_repr(b), value_repr(res)))
//             sp += 1
//             stack[sp] = res

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
