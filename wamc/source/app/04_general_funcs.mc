import Toybox.Lang;
import Toybox.System;

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


// math functions

// def unpack_nan32(i32):
//     return struct.unpack('f', struct.pack('I', i32))[0]
// def unpack_nan64(i64):
//     return struct.unpack('d', struct.pack('Q', i64))[0]

// def parse_nan(type, arg):
//     if   type == F32: v = unpack_nan32(0x7fc00000)
//     else:             v = unpack_nan64(0x7ff8000000000000)
//     return v

// def parse_number(type, arg):
//     arg = "".join([c for c in arg if c != '_'])
//     if   type == I32:
//         if   arg[0:2] == '0x':   v = (I32, string_to_int(arg,16), 0.0)
//         elif arg[0:3] == '-0x':  v = (I32, string_to_int(arg,16), 0.0)
//         else:                    v = (I32, string_to_int(arg,10), 0.0)
//     elif type == I64:
//         if arg[0:2] == '0x':     v = (I64, string_to_int(arg,16), 0.0)
//         elif arg[0:3] == '-0x':  v = (I64, string_to_int(arg,16), 0.0)
//         else:                    v = (I64, string_to_int(arg,10), 0.0)
//     elif type == F32:
//         if   arg.find('nan')>=0: v = (F32, 0, parse_nan(type, arg))
//         elif arg.find('inf')>=0: v = (F32, 0, float_fromhex(arg))
//         elif arg[0:2] == '0x':   v = (F32, 0, float_fromhex(arg))
//         elif arg[0:3] == '-0x':  v = (F32, 0, float_fromhex(arg))
//         else:                    v = (F32, 0, float(arg))
//     elif type == F64:
//         if   arg.find('nan')>=0: v = (F64, 0, parse_nan(type, arg))
//         elif arg.find('inf')>=0: v = (F64, 0, float_fromhex(arg))
//         elif arg[0:2] == '0x':   v = (F64, 0, float_fromhex(arg))
//         elif arg[0:3] == '-0x':  v = (F64, 0, float_fromhex(arg))
//         else:                    v = (F64, 0, float(arg))
//     else:
//         raise Exception("invalid number %s" % arg)
//     return v

// # Integer division that rounds towards 0 (like C)
// def idiv_s(a,b):
//     return a//b if a*b>0 else (a+(-a%b))//b

// def irem_s(a,b):
//     return a%b if a*b>0 else -(-a%b)

// #

// def rotl32(a,cnt):
//     return (((a << (cnt % 0x20)) & 0xffffffff)
//             | (a >> (0x20 - (cnt % 0x20))))

// def rotr32(a,cnt):
//     return ((a >> (cnt % 0x20))
//             | ((a << (0x20 - (cnt % 0x20))) & 0xffffffff))

// def rotl64(a,cnt):
//     return (((a << (cnt % 0x40)) & 0xffffffffffffffff)
//             | (a >> (0x40 - (cnt % 0x40))))

// def rotr64(a,cnt):
//     return ((a >> (cnt % 0x40))
//             | ((a << (0x40 - (cnt % 0x40))) & 0xffffffffffffffff))

// def bytes2uint8(b):
//     return b[0]

// def bytes2int8(b):
//     val = b[0]
//     if val & 0x80:
//         return val - 0x100
//     else:
//         return val

// #

// def bytes2uint16(b):
//     return (b[1]<<8) + b[0]

// def bytes2int16(b):
//     val = (b[1]<<8) + b[0]
//     if val & 0x8000:
//         return val - 0x10000
//     else:
//         return val

// #

// def bytes2uint32(b):
//     return (b[3]<<24) + (b[2]<<16) + (b[1]<<8) + b[0]

// def uint322bytes(v):
//     return [0xff & (v),
//             0xff & (v>>8),
//             0xff & (v>>16),
//             0xff & (v>>24)]

// def bytes2int32(b):
//     val = (b[3]<<24) + (b[2]<<16) + (b[1]<<8) + b[0]
//     if val & 0x80000000:
//         return val - 0x100000000
//     else:
//         return val

// def int2uint32(i):
//     return int(i) & 0xffffffff

// def int2int32(i):
//     val = int(i) & 0xffffffff
//     if val & 0x80000000:
//         return val - 0x100000000
//     else:
//         return val
        
// #

// def bytes2uint64(b):
//     return ((b[7]<<56) + (b[6]<<48) + (b[5]<<40) + (b[4]<<32) +
//             (b[3]<<24) + (b[2]<<16) + (b[1]<<8) + b[0])

// def uint642bytes(v):
//     return [0xff & (v),
//             0xff & (v>>8),
//             0xff & (v>>16),
//             0xff & (v>>24),
//             0xff & (v>>32),
//             0xff & (v>>40),
//             0xff & (v>>48),
//             0xff & (v>>56)]

// def bytes2int64(b):
//     val = ((b[7]<<56) + (b[6]<<48) + (b[5]<<40) + (b[4]<<32) +
//             (b[3]<<24) + (b[2]<<16) + (b[1]<<8) + b[0])
//     if val & 0x8000000000000000:
//         return val - 0x10000000000000000
//     else:
//         return val

// #

// def int2uint64(i):
//     return i & 0xffffffffffffffff

// def int2int64(i):
//     val = i & 0xffffffffffffffff
//     if val & 0x8000000000000000:
//         return val - 0x10000000000000000
//     else:
//         return val

// # https://en.wikipedia.org/wiki/LEB128
// def read_LEB(bytes, pos, maxbits=32, signed=False):
//     result = 0
//     shift = 0

//     bcnt = 0
//     startpos = pos
//     while True:
//         byte = bytes[pos]
//         pos += 1
//         result |= ((byte & 0x7f)<<shift)
//         shift +=7
//         if (byte & 0x80) == 0:
//             break
//         # Sanity check length against maxbits
//         bcnt += 1
//         if bcnt > math.ceil(maxbits/7.0):
//             raise Exception("Unsigned LEB at byte %s overflow" %
//                     startpos)
//     if signed and (shift < maxbits) and (byte & 0x40):
//         # Sign extend
//         result |= - (1 << shift)
//     return (pos, result)

// def read_I32(bytes, pos):
//     assert pos >= 0
//     return bytes2uint32(bytes[pos:pos+4])

// def read_I64(bytes, pos):
//     assert pos >= 0
//     return bytes2uint64(bytes[pos:pos+8])

// def read_F32(bytes, pos):
//     assert pos >= 0
//     bits = bytes2int32(bytes[pos:pos+4])
//     num = unpack_f32(bits)
//     # fround hangs if called with nan
//     if math.isnan(num): return num
//     return fround(num, 5)

// def read_F64(bytes, pos):
//     assert pos >= 0
//     bits = bytes2int64(bytes[pos:pos+8])
//     return unpack_f64(bits)

// def write_I32(bytes, pos, ival):
//     bytes[pos:pos+4] = uint322bytes(ival)

// def write_I64(bytes, pos, ival):
//     bytes[pos:pos+8] = uint642bytes(ival)

// def write_F32(bytes, pos, fval):
//     ival = intmask(pack_f32(fval))
//     bytes[pos:pos+4] = uint322bytes(ival)

// def write_F64(bytes, pos, fval):
//     ival = intmask(pack_f64(fval))
//     bytes[pos:pos+8] = uint642bytes(ival)


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

// def skip_immediates(code, pos):
//     opcode = code[pos]
//     pos += 1
//     vals = []
//     imtype = OPERATOR_INFO[opcode][1]
//     if   'varuint1' == imtype:
//         pos, v = read_LEB(code, pos, 1)
//         vals.append(v)
//     elif 'varint32' == imtype:
//         pos, v = read_LEB(code, pos, 32)
//         vals.append(v)
//     elif 'varuint32' == imtype:
//         pos, v = read_LEB(code, pos, 32)
//         vals.append(v)
//     elif 'varuint32+varuint1' == imtype:
//         pos, v = read_LEB(code, pos, 32)
//         vals.append(v)
//         pos, v = read_LEB(code, pos, 1)
//         vals.append(v)
//     elif 'varint64' == imtype:
//         pos, v = read_LEB(code, pos, 64)
//         vals.append(v)
//     elif 'varuint64' == imtype:
//         pos, v = read_LEB(code, pos, 64)
//         vals.append(v)
//     elif 'uint32' == imtype:
//         vals.append(read_F32(code, pos))
//         pos += 4
//     elif 'uint64' == imtype:
//         vals.append(read_F64(code, pos))
//         pos += 8
//     elif 'block_type' == imtype:
//         pos, v = read_LEB(code, pos, 7)  # block type signature
//         vals.append(v)
//     elif 'memory_immediate' == imtype:
//         pos, v = read_LEB(code, pos, 32)  # flags
//         vals.append(v)
//         pos, v = read_LEB(code, pos, 32)  # offset
//         vals.append(v)
//     elif 'br_table' == imtype:
//         pos, count = read_LEB(code, pos, 32)  # target count
//         vals.append(count)
//         for i in range(count):
//             pos, v = read_LEB(code, pos, 32)  # target
//             vals.append(v)
//         pos, v = read_LEB(code, pos, 32)  # default target
//         vals.append(v)
//     elif '' == imtype:
//         pass # no immediates
//     else:
//         raise Exception("unknown immediate type %s" % imtype)
//     return pos, vals

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

// def pop_block(stack, callstack, sp, fp, csp):
//     block, orig_sp, orig_fp, ra = callstack[csp]
//     csp -= 1
//     t = block.type

//     # Validate return value if there is one
//     if VALIDATE:
//         if len(t.results) > 1:
//             raise Exception("multiple return values unimplemented")
//         if len(t.results) > sp+1:
//             raise Exception("stack underflow")

//     if len(t.results) == 1:
//         # Restore main value stack, saving top return value
//         save = stack[sp]
//         sp -= 1
//         if save[0] != t.results[0]:
//             raise WAException("call signature mismatch: %s != %s (%s)" % (
//                 VALUE_TYPE[t.results[0]], VALUE_TYPE[save[0]],
//                 value_repr(save)))

//         # Restore value stack to original size prior to call/block
//         if orig_sp < sp:
//             sp = orig_sp

//         # Put back return value if we have one
//         sp += 1
//         stack[sp] = save
//     else:
//         # Restore value stack to original size prior to call/block
//         if orig_sp < sp:
//             sp = orig_sp

//     return block, ra, sp, orig_fp, csp












function doCall(stack as StackType, callstack as CallStackType, sp as Number, fp as Number, csp as Number, func, pc as Number, indirect as Boolean) as Number {
    System.println("do call");
}