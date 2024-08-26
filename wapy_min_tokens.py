# Basic low-level types/classes

class Type():
    def __init__(self, index, form, params, results):
        self.index = index
        self.form = form
        self.params = params
        self.results = results
        self.mask = 0x80

class Code():
    pass

class Block(Code):
    def __init__(self, kind, type, start):
        self.kind = kind # block opcode (0x00 for init_expr)
        self.type = type # value_type
        self.locals = []
        self.start = start
        self.end = 0
        self.else_addr = 0
        self.br_addr = 0

    def update(self, end, br_addr):
        self.end = end
        self.br_addr = br_addr

class Function(Code):
    def __init__(self, type, index):
        self.type = type # value_type
        self.index = index
        self.locals = []
        self.start = 0
        self.end = 0
        self.else_addr = 0
        self.br_addr = 0

    def update(self, locals, start, end):
        self.locals = locals
        self.start = start
        self.end = end
        self.br_addr = end

class FunctionImport(Code):
    def __init__(self, type, module, field):
        self.type = type  # value_type
        self.module = module
        self.field = field
        fname = "%s.%s" % (module, field)


######################################
# WebAssembly spec data
######################################

MAGIC = 0x6d736100
VERSION = 0x01  # MVP

STACK_SIZE     = 65536
CALLSTACK_SIZE = 8192

I32     = 0x7f  # -0x01
I64     = 0x7e  # -0x02
F32     = 0x7d  # -0x03
F64     = 0x7c  # -0x04
ANYFUNC = 0x70  # -0x10
FUNC    = 0x60  # -0x20
BLOCK   = 0x40  # -0x40

VALUE_TYPE = { I32     : 'i32',
               I64     : 'i64',
               F32     : 'f32',
               F64     : 'f64',
               ANYFUNC : 'anyfunc',
               FUNC    : 'func',
               BLOCK   : 'block_type' }

# Block types/signatures for blocks, loops, ifs
BLOCK_TYPE = { I32   : Type(-1, BLOCK, [], [I32]),
               I64   : Type(-1, BLOCK, [], [I64]),
               F32   : Type(-1, BLOCK, [], [F32]),
               F64   : Type(-1, BLOCK, [], [F64]),
               BLOCK : Type(-1, BLOCK, [], []) }


BLOCK_NAMES = { 0x00 : "fn",  # TODO: something else?
                0x02 : "block",
                0x03 : "loop",
                0x04 : "if",
                0x05 : "else" }


EXTERNAL_KIND_NAMES = { 0x0 : "Function",
                        0x1 : "Table",
                        0x2 : "Memory",
                        0x3 : "Global" }

#                 ID :  section name
SECTION_NAMES = { 0  : 'Custom',
                  1  : 'Type',
                  2  : 'Import',
                  3  : 'Function',
                  4  : 'Table',
                  5  : 'Memory',
                  6  : 'Global',
                  7  : 'Export',
                  8  : 'Start',
                  9  : 'Element',
                  10 : 'Code',
                  11 : 'Data' }

#      opcode  name              immediate(s)
OPERATOR_INFO = {
        0x00 : ['unreachable',    ''],
        0x01 : ['nop',            ''],
        0x41 : ['i32.const',      'varint32'],
# etc
        }

LOAD_SIZE = { 0x28 : 4,
# etc
              0x44 : 4 }


# General Functions

# math functions
# etc

# https://en.wikipedia.org/wiki/LEB128
def read_LEB(bytes, pos, maxbits=32, signed=False):
    result = 0
    shift = 0

    bcnt = 0
    startpos = pos
    while True:
        byte = bytes[pos]
        pos += 1
        result |= ((byte & 0x7f)<<shift)
        shift +=7
        if (byte & 0x80) == 0:
            break
        # Sanity check length against maxbits
        bcnt += 1
        if bcnt > math.ceil(maxbits/7.0):
            raise Exception("Unsigned LEB at byte %s overflow" %
                    startpos)
    if signed and (shift < maxbits) and (byte & 0x40):
        # Sign extend
        result |= - (1 << shift)
    return (pos, result)

def read_I32(bytes, pos):
    assert pos >= 0
    return bytes2uint32(bytes[pos:pos+4])

def read_I64(bytes, pos):
    assert pos >= 0
    return bytes2uint64(bytes[pos:pos+8])

def read_F32(bytes, pos):
    assert pos >= 0
    bits = bytes2int32(bytes[pos:pos+4])
    num = unpack_f32(bits)
    # fround hangs if called with nan
    if math.isnan(num): return num
    return fround(num, 5)

def read_F64(bytes, pos):
    assert pos >= 0
    bits = bytes2int64(bytes[pos:pos+8])
    return unpack_f64(bits)

def write_I32(bytes, pos, ival):
    bytes[pos:pos+4] = uint322bytes(ival)

def write_I64(bytes, pos, ival):
    bytes[pos:pos+8] = uint642bytes(ival)

def write_F32(bytes, pos, fval):
    ival = intmask(pack_f32(fval))
    bytes[pos:pos+4] = uint322bytes(ival)

def write_F64(bytes, pos, fval):
    ival = intmask(pack_f64(fval))
    bytes[pos:pos+8] = uint642bytes(ival)


def value_repr(val):
    vt, ival, fval = val
    vtn = VALUE_TYPE[vt]
    if   vtn in ('i32', 'i64'):
        return "%s:%s" % (hex(ival), vtn)
    elif vtn in ('f32', 'f64'):
        str = "%.7g" % fval
        if str.find('.') < 0:
            return "%f:%s" % (fval, vtn)
        else:
            return "%s:%s" % (str, vtn)
    else:
        raise Exception("unknown value type %s" % vtn)

def type_repr(t):
    return "<index: %s, form: %s, params: %s, results: %s, mask: %s>" % (
            t.index, VALUE_TYPE[t.form],
            [VALUE_TYPE[p] for p in t.params],
            [VALUE_TYPE[r] for r in t.results], hex(t.mask))

def export_repr(e):
    return "<kind: %s, field: '%s', index: 0x%x>" % (
            EXTERNAL_KIND_NAMES[e.kind], e.field, e.index)

def func_repr(f):
    if isinstance(f, FunctionImport):
        return "<type: 0x%x, import: '%s.%s'>" % (
                f.type.index, f.module, f.field)
    else:
        return "<type: 0x%x, locals: %s, start: 0x%x, end: 0x%x>" % (
                f.type.index, [VALUE_TYPE[p] for p in f.locals],
                f.start, f.end)

def block_repr(block):
    if isinstance(block, Block):
        return "%s<0/0->%d>" % (
                BLOCK_NAMES[block.kind],
                len(block.type.results))
    elif isinstance(block, Function):
        return "fn%d<%d/%d->%d>" % (
                block.index, len(block.type.params),
                len(block.locals), len(block.type.results))

def stack_repr(sp, fp, stack):
    res = []
    for i in range(sp+1):
        if i == fp:
            res.append("*")
        res.append(value_repr(stack[i]))
    return "[" + " ".join(res) + "]"

def callstack_repr(csp, bs):
    return "[" + " ".join(["%s(sp:%d/fp:%d/ra:0x%x)" % (
        block_repr(bs[i][0]),bs[i][1],bs[i][2],bs[i][3])
                           for i in range(csp+1)]) + "]"

def dump_stacks(sp, stack, fp, csp, callstack):
    debug("      * stack:     %s" % (
        stack_repr(sp, fp, stack)))
    debug("      * callstack: %s" % (
        callstack_repr(csp, callstack)))

def byte_code_repr(bytes):
    res = []
    for val in bytes:
        if val < 16:
            res.append("%x" % val)
        else:
            res.append("%x" % val)
    return "[" + ",".join(res) + "]"

def skip_immediates(code, pos):
    opcode = code[pos]
    pos += 1
    vals = []
    imtype = OPERATOR_INFO[opcode][1]
    if   'varuint1' == imtype:
  # etc
    else:
        raise Exception("unknown immediate type %s" % imtype)
    return pos, vals

def find_blocks(code, start, end, block_map):
    pos = start

    # stack of blocks with current at top: (opcode, pos) tuples
    opstack = []

    #
    # Build the map of blocks
    #
    opcode = 0
    while pos <= end:
  # etc


    assert opcode == 0xb, "function block did not end with 0xb"
    assert len(opstack) == 0, "function ended in middle of block"

    #debug("block_map: %s" % block_map)
    return block_map

def pop_block(stack, callstack, sp, fp, csp):
  # etc

    return block, ra, sp, orig_fp, csp

def do_call(stack, callstack, sp, fp, csp, func, pc, indirect=False):
  # etc


    return pc, sp, fp, csp


def do_call_import(stack, sp, memory, import_function, func):
    t = func.type

    args = []
    for idx in range(len(t.params)-1, -1, -1):
        arg = stack[sp]
        sp -= 1
        args.append(arg)    # Workaround rpython failure to identify type
    results = [(0, 0, 0.0)]
    results.pop()
    args.reverse()
    results.extend(import_function(func.module, func.field, memory, args))

    # make sure returns match type signature
    for idx, rtype in enumerate(t.results):
        if idx < len(results):
            res = results[idx]
            if rtype != res[0]:
                raise Exception("return signature mismatch")
            sp += 1
            stack[sp] = res
        else:
            raise Exception("return signature mismatch")
    return sp


# Main loop/JIT

def get_location_str(opcode, pc, code, function, table, block_map):
    return "0x%x %s(0x%x)" % (
            pc, OPERATOR_INFO[opcode][0], opcode)

def get_block(block_map, pc):
    return block_map[pc]

def get_function(function, fidx):
    return function[fidx]

def bound_violation(opcode, addr, pages):
    return addr < 0 or addr+LOAD_SIZE[opcode] > pages*(2**16)

def get_from_table(table, tidx, table_index):
    tbl = table[tidx]
    if table_index < 0 or table_index >= len(tbl):
        raise WAException("undefined element")
    return tbl[table_index]


def interpret_mvp(module,
        # Greens
        pc, code, function, table, block_map,
        # Reds
        memory, sp, stack, fp, csp, callstack):

    while pc < len(code):
        opcode = code[pc]

        cur_pc = pc
        pc += 1

        if TRACE:
            dump_stacks(sp, stack, fp, csp, callstack)
            _, immediates = skip_immediates(code, cur_pc)
            info("    0x%x <0x%x/%s%s%s>" % (
                cur_pc, opcode, OPERATOR_INFO[opcode][0],
                " " if immediates else "",
                ",".join(["0x%x" % i for i in immediates])))

        #
        # Control flow operators
        #
        if   0x00 == opcode:  # unreachable
            raise WAException("unreachable")
        elif 0x01 == opcode:  # nop
            pass
        elif 0x02 == opcode:  # block
            pc, ignore = read_LEB(code, pc, 32) # ignore block_type
            block = get_block(block_map, cur_pc)
            csp += 1
            callstack[csp] = (block, sp, fp, 0)
            if TRACE: debug("      - block: %s" % block_repr(block))
        elif 0x03 == opcode:  # loop
            pc, ignore = read_LEB(code, pc, 32) # ignore block_type
            block = get_block(block_map, cur_pc)
            csp += 1
            callstack[csp] = (block, sp, fp, 0)
            if TRACE: debug("      - block: %s" % block_repr(block))
        elif 0x04 == opcode:  # if
            pc, ignore = read_LEB(code, pc, 32) # ignore block_type
            block = get_block(block_map, cur_pc)
            csp += 1
            callstack[csp] = (block, sp, fp, 0)
            cond = stack[sp]
            sp -= 1
            if not cond[1]:  # if false (I32)
                # branch to else block or after end of if
                if block.else_addr == 0:
                    # no else block so pop if block and skip end
                    csp -= 1
                    pc = block.br_addr+1
                else:
                    pc = block.else_addr
            if TRACE:
                debug("      - cond: %s jump to 0x%x, block: %s" % (
                    value_repr(cond), pc, block_repr(block)))
        elif 0x05 == opcode:  # else
            block = callstack[csp][0]
            pc = block.br_addr
            if TRACE:
                debug("      - of %s jump to 0x%x" % (
                    block_repr(block), pc))
        elif 0x0b == opcode:  # end
            block, ra, sp, fp, csp = pop_block(stack, callstack, sp,
                    fp, csp)
            if TRACE: debug("      - of %s" % block_repr(block))
            if isinstance(block, Function):
                # Return to return address
                pc = ra
                if csp == -1:
                    # Return to top-level, ignoring return_addr
                    return pc, sp, fp, csp
                else:
                    if TRACE:
                        info("  Returning from function 0x%x to 0x%x" % (
                            block.index, pc))
            elif isinstance(block, Block) and block.kind == 0x00:
                # this is an init_expr
                return pc, sp, fp, csp
            else:
                pass # end of block/loop/if, keep going
        elif 0x0c == opcode:  # br
            pc, br_depth = read_LEB(code, pc, 32)
            csp -= br_depth
            block, _, _, _ = callstack[csp]
            pc = block.br_addr # set to end for pop_block
            if TRACE: debug("      - to: 0x%x" % pc)
        elif 0x0d == opcode:  # br_if
            pc, br_depth = read_LEB(code, pc, 32)
            cond = stack[sp]
            sp -= 1
            if cond[1]:  # I32
                csp -= br_depth
                block, _, _, _ = callstack[csp]
                pc = block.br_addr # set to end for pop_block
            if TRACE:
                debug("      - cond: %s, to: 0x%x" % (cond[1], pc))
        elif 0x0e == opcode:  # br_table
            pc, target_count = read_LEB(code, pc, 32)
            depths = []
            for c in range(target_count):
                pc, depth = read_LEB(code, pc, 32)
                depths.append(depth)
            pc, br_depth = read_LEB(code, pc, 32) # default
            expr = stack[sp]
            sp -= 1
            if VALIDATE: assert expr[0] == I32
            didx = expr[1]  # I32
            if didx >= 0 and didx < len(depths):
                br_depth = depths[didx]
            csp -= br_depth
            block, _, _, _ = callstack[csp]
            pc = block.br_addr # set to end for pop_block
            if TRACE:
                debug("      - depths: %s, didx: %d, to: 0x%x" % (
                    depths, didx, pc))
        elif 0x0f == opcode:  # return
            # Pop blocks until reach Function signature
            while csp >= 0:
                if isinstance(callstack[csp][0], Function): break
                # We don't use pop_block because the end opcode
                # handler will do this for us and catch the return
                # value properly.
                block = callstack[csp]
                csp -= 1
            if VALIDATE: assert csp >= 0
            block = callstack[csp][0]
            if VALIDATE: assert isinstance(block, Function)
            # Set instruction pointer to end of function
            # The actual pop_block and return is handled by handling
            # the end opcode
            pc = block.end
            if TRACE: debug("      - to 0x%x" % pc)

        #
        # Call operators
        #
        elif 0x10 == opcode:  # call
            pc, fidx = read_LEB(code, pc, 32)
            func = get_function(function, fidx)

            if isinstance(func, FunctionImport):
                t = func.type
                if TRACE:
                    debug("      - calling import %s.%s(%s)" % (
                        func.module, func.field,
                        ",".join([VALUE_TYPE[a] for a in t.params])))
                sp = do_call_import(stack, sp, memory,
                        module.import_function, func)
            elif isinstance(func, Function):
                pc, sp, fp, csp = do_call(stack, callstack, sp, fp,
                        csp, func, pc)
                if TRACE: debug("      - calling function fidx: %d"
                                " at: 0x%x" % (fidx, pc))
        elif 0x11 == opcode:  # call_indirect
            pc, tidx = read_LEB(code, pc, 32)
            pc, reserved = read_LEB(code, pc, 1)
            type_index_val = stack[sp]
            sp -= 1
            if VALIDATE: assert type_index_val[0] == I32
            table_index = int(type_index_val[1])  # I32
            fidx = get_from_table(table, ANYFUNC, table_index)
            if VALIDATE: assert csp < CALLSTACK_SIZE, "call stack exhausted"
            func = get_function(function, fidx)
            if VALIDATE and func.type.mask != module.type[tidx].mask:
                raise WAException("indirect call type mismatch (call type %s and function type %s differ" % (func.type.index, tidx))
            pc, sp, fp, csp = do_call(stack, callstack, sp, fp, csp,
                    func, pc, True)
            if TRACE:
                debug("      - table idx: 0x%x, tidx: 0x%x,"
                      " calling function fidx: 0x%x at 0x%x" % (
                          table_index, tidx, fidx, pc))

        #
        # Parametric operators
        #
        elif 0x1a == opcode:  # drop
            if TRACE: debug("      - dropping: %s" % value_repr(stack[sp]))
            sp -= 1
        elif 0x1b == opcode:  # select
            cond, a, b = stack[sp], stack[sp-1], stack[sp-2]
            sp -= 2
            if cond[1]:  # I32
                stack[sp] = b
            else:
                stack[sp] = a
            if TRACE:
                debug("      - cond: 0x%x, selected: %s" % (
                    cond[1], value_repr(stack[sp])))

        #
        # Variable access
        #
        elif 0x20 == opcode:  # get_local
            pc, arg = read_LEB(code, pc, 32)
            sp += 1
            stack[sp] = stack[fp+arg]
            if TRACE: debug("      - got %s" % value_repr(stack[sp]))
        elif 0x21 == opcode:  # set_local
            pc, arg = read_LEB(code, pc, 32)
            val = stack[sp]
            sp -= 1
            stack[fp+arg] = val
            if TRACE: debug("      - to %s" % value_repr(val))
        elif 0x22 == opcode:  # tee_local
            pc, arg = read_LEB(code, pc, 32)
            val = stack[sp] # like set_local but do not pop
            stack[fp+arg] = val
            if TRACE: debug("      - to %s" % value_repr(val))
        elif 0x23 == opcode:  # get_global
            pc, gidx = read_LEB(code, pc, 32)
            sp += 1
            stack[sp] = module.global_list[gidx]
            if TRACE: debug("      - got %s" % value_repr(stack[sp]))
        elif 0x24 == opcode:  # set_global
            pc, gidx = read_LEB(code, pc, 32)
            val = stack[sp]
            sp -= 1
            module.global_list[gidx] = val
            if TRACE: debug("      - to %s" % value_repr(val))

        #
        # Memory-related operators
        #

        # Memory load operators
        elif 0x28 <= opcode <= 0x35:
            pc, flags = read_LEB(code, pc, 32)
            pc, offset = read_LEB(code, pc, 32)
            addr_val = stack[sp]
            sp -= 1
            if flags != 2:
                if TRACE:
                    info("      - unaligned load - flags: 0x%x,"
                         " offset: 0x%x, addr: 0x%x" % (
                             flags, offset, addr_val[1]))
            addr = addr_val[1] + offset
            if bound_violation(opcode, addr, memory.pages):
                raise WAException("out of bounds memory access")
            assert addr >= 0
            if   0x28 == opcode:  # i32.load
                res = (I32, bytes2uint32(memory.bytes[addr:addr+4]), 0.0)
            elif 0x29 == opcode:  # i64.load
  # etc
                raise WAException("%s(0x%x) unimplemented" % (
                    OPERATOR_INFO[opcode][0], opcode))
            sp += 1
            stack[sp] = res

        # Memory store operators
        elif 0x36 <= opcode <= 0x3e:
            pc, flags = read_LEB(code, pc, 32)
            pc, offset = read_LEB(code, pc, 32)
            val = stack[sp]
            sp -= 1
            addr_val = stack[sp]
            sp -= 1
            if flags != 2:
                if TRACE:
                    info("      - unaligned store - flags: 0x%x,"
                         " offset: 0x%x, addr: 0x%x, val: 0x%x" % (
                             flags, offset, addr_val[1], val[1]))
            addr = addr_val[1] + offset
            if bound_violation(opcode, addr, memory.pages):
                raise WAException("out of bounds memory access")
            assert addr >= 0
            if   0x36 == opcode:  # i32.store
                write_I32(memory.bytes, addr, val[1])
            elif 0x37 == opcode:  # i64.store
                write_I64(memory.bytes, addr, val[1])
            elif 0x38 == opcode:  # f32.store
                write_F32(memory.bytes, addr, val[2])
            elif 0x39 == opcode:  # f64.store
                write_F64(memory.bytes, addr, val[2])
            elif 0x3a == opcode:  # i32.store8
                memory.bytes[addr] = val[1] & 0xff
            elif 0x3b == opcode:  # i32.store16
                memory.bytes[addr]   =  val[1] & 0x00ff
                memory.bytes[addr+1] = (val[1] & 0xff00)>>8
            elif 0x3c == opcode:  # i64.store8
                memory.bytes[addr]   =  val[1] & 0xff
            elif 0x3d == opcode:  # i64.store16
                memory.bytes[addr]   =  val[1] & 0x00ff
                memory.bytes[addr+1] = (val[1] & 0xff00)>>8
            elif 0x3e == opcode:  # i64.store32
                memory.bytes[addr]   =  val[1] & 0x000000ff
                memory.bytes[addr+1] = (val[1] & 0x0000ff00)>>8
                memory.bytes[addr+2] = (val[1] & 0x00ff0000)>>16
                memory.bytes[addr+3] = (val[1] & 0xff000000)>>24
            else:
                raise WAException("%s(0x%x) unimplemented" % (
                    OPERATOR_INFO[opcode][0], opcode))

        # Memory size operators
        elif 0x3f == opcode:  # current_memory
            pc, reserved = read_LEB(code, pc, 1)
            sp += 1
            stack[sp] = (I32, module.memory.pages, 0.0)
            if TRACE:
                debug("      - current 0x%x" % module.memory.pages)
        elif 0x40 == opcode:  # grow_memory
            pc, reserved = read_LEB(code, pc, 1)
            prev_size = module.memory.pages
            delta = stack[sp][1]  # I32
            module.memory.grow(delta)
            stack[sp] = (I32, prev_size, 0.0)
            debug("      - delta 0x%x, prev: 0x%x" % (
                delta, prev_size))

        #
        # Constants
        #
        elif 0x41 == opcode:  # i32.const
            pc, val = read_LEB(code, pc, 32, signed=True)
            sp += 1
            stack[sp] = (I32, val, 0.0)
            if TRACE: debug("      - %s" % value_repr(stack[sp]))
        elif 0x42 == opcode:  # i64.const
            pc, val = read_LEB(code, pc, 64, signed=True)
            sp += 1
            stack[sp] = (I64, val, 0.0)
            if TRACE: debug("      - %s" % value_repr(stack[sp]))
        elif 0x43 == opcode:  # f32.const
            sp += 1
            stack[sp] = (F32, 0, read_F32(code, pc))
            pc += 4
            if TRACE: debug("      - %s" % value_repr(stack[sp]))
        elif 0x44 == opcode:  # f64.const
            sp += 1
            stack[sp] = (F64, 0, read_F64(code, pc))
            pc += 8
            if TRACE: debug("      - %s" % value_repr(stack[sp]))

        #
        # Comparison operators
        #

        # unary
        elif opcode in [0x45, 0x50]:
            a = stack[sp]
            sp -= 1
            if   0x45 == opcode: # i32.eqz
                if VALIDATE: assert a[0] == I32
                res = (I32, a[1] == 0, 0.0)
            elif 0x50 == opcode: # i64.eqz
                if VALIDATE: assert a[0] == I64
                res = (I32, a[1] == 0, 0.0)
            else:
                raise WAException("%s(0x%x) unimplemented" % (
                    OPERATOR_INFO[opcode][0], opcode))
            if TRACE:
                debug("      - (%s) = %s" % (
                    value_repr(a), value_repr(res)))
            sp += 1
            stack[sp] = res

        # binary
        elif 0x46 <= opcode <= 0x66:
            a, b = stack[sp-1], stack[sp]
            sp -= 2
            if   0x46 == opcode: # i32.eq
                if VALIDATE: assert a[0] == I32 and b[0] == I32
                res = (I32, a[1] == b[1], 0.0)
            # etc

            else:
                raise WAException("%s(0x%x) unimplemented" % (
                    OPERATOR_INFO[opcode][0], opcode))
            if TRACE:
                debug("      - (%s, %s) = %s" % (
                    value_repr(a), value_repr(b), value_repr(res)))
            sp += 1
            stack[sp] = res

        #
        # Numeric operators
        #

        # unary
        elif opcode in [0x67,...]:
            a = stack[sp]
            sp -= 1
            if   0x67 == opcode: # i32.clz
                if VALIDATE: assert a[0] == I32
                count = 0
                val = a[1]
                while count < 32 and (val & 0x80000000) == 0:
                    count += 1
                    val = val * 2
                res = (I32, count, 0.0)
          # etc

            sp += 1
            stack[sp] = res

        # i32 binary
        elif 0x6a <= opcode <= 0x78:
            a, b = stack[sp-1], stack[sp]
            sp -= 2
            if VALIDATE: assert a[0] == I32 and b[0] == I32
            if   0x6a == opcode: # i32.add
                res = (I32, int2int32(a[1] + b[1]), 0.0)
            # etc

            sp += 1
            stack[sp] = res

        # i64 binary
        elif 0x7c <= opcode <= 0x8a:
             # etc

            sp += 1
            stack[sp] = res

        # f32 binary operations
        elif 0x92 <= opcode <= 0x98:
            # etc


        # f64 binary operations
        elif 0xa0 <= opcode <= 0xa6:
             # etc


        ## conversion operations
        elif 0xa7 <= opcode <= 0xbb:
            # etc


        ## reinterpretations
        el  # etc


        else:
            raise WAException("unrecognized opcode 0x%x" % opcode)

    return pc, sp, fp, csp


######################################
# Higher level classes
######################################

class Reader():
    def __init__(self, bytes):
        self.bytes = bytes
        self.pos = 0

    def read_byte(self):
        b = self.bytes[self.pos]
        self.pos += 1
        return b

    def read_word(self):
        w = bytes2uint32(self.bytes[self.pos:self.pos+4])
        self.pos += 4
        return w

    def read_bytes(self, cnt):
        if VALIDATE: assert cnt >= 0
        if VALIDATE: assert self.pos >= 0
        bytes = self.bytes[self.pos:self.pos+cnt]
        self.pos += cnt
        return bytes

    def read_LEB(self, maxbits=32, signed=False):
        [self.pos, result] = read_LEB(self.bytes, self.pos,
                maxbits, signed)
        return result

    def eof(self):
        return self.pos >= len(self.bytes)

class Memory():
    def __init__(self, pages=1, bytes=[]):
        debug("memory pages: %d" % pages)
        self.pages = pages
        self.bytes = bytes + ([0]*((pages*(2**16))-len(bytes)))
        #self.bytes = [0]*(pages*(2**16))

    def grow(self, pages):
        self.pages += int(pages)
        self.bytes = self.bytes + ([0]*(int(pages)*(2**16)))

    def read_byte(self, pos):
        b = self.bytes[pos]
        return b

    def write_byte(self, pos, val):
        self.bytes[pos] = val


class Import():
    def __init__(self, module, field, kind, type=0,
            element_type=0, initial=0, maximum=0, global_type=0,
            mutability=0):
        self.module = module
        self.field = field
        self.kind = kind
        self.type = type # Function
        self.element_type = element_type # Table
        self.initial = initial # Table & Memory
        self.maximum = maximum # Table & Memory

        self.global_type = global_type # Global
        self.mutability = mutability # Global

class Export():
    def __init__(self, field, kind, index):
        self.field = field
        self.kind = kind
        self.index = index


class Module():
    def __init__(self, data, import_value, import_function, memory=None):
        assert isinstance(data, bytes)
        self.data = data
        self.rdr = Reader(list(data))  # Convert bytes to list of integers
        self.import_value = import_value
        self.import_function = import_function

        # Sections
        self.type = []
        self.import_list = []
        self.function = []
        self.fn_import_cnt = 0
        self.table = {ANYFUNC: []}
        self.export_list = []
        self.export_map = {}
        self.global_list = []

        if memory:
            self.memory = memory
        else:
            self.memory = Memory(1)  # default to 1 page

        # block/loop/if blocks {start addr: Block, ...}
        self.block_map = {}

        # Execution state
        self.sp = -1
        self.fp = -1
        self.stack = [(0x00, 0, 0.0)] * STACK_SIZE
        self.csp = -1
        block = Block(0x00, BLOCK_TYPE[I32], 0)
        self.callstack = [(block, -1, -1, 0)] * CALLSTACK_SIZE
        self.start_function = -1

        self.read_magic()
        self.read_version()
        self.read_sections()

        self.dump()

        # Run the start function if set
        if self.start_function >= 0:
            fidx = self.start_function
            func = self.function[fidx]
            info("Running start function 0x%x" % fidx)
            if TRACE:
                dump_stacks(self.sp, self.stack, self.fp, self.csp,
                        self.callstack)
            if isinstance(func, FunctionImport):
                sp = do_call_import(self.stack, self.sp, self.memory,
                        self.import_function, func)
            elif isinstance(func, Function):
                self.rdr.pos, self.sp, self.fp, self.csp = do_call(
                        self.stack, self.callstack, self.sp, self.fp,
                        self.csp, func, len(self.rdr.bytes))
            self.interpret()

    def dump(self):
        #debug("raw module data: %s" % self.data)
        debug("module bytes: %s" % byte_code_repr(self.rdr.bytes))
        info("")

        info("Types:")
        for i, t in enumerate(self.type):
            info("  0x%x %s" % (i, type_repr(t)))

        info("Imports:")
        for i, imp in enumerate(self.import_list):
            if imp.kind == 0x0:  # Function
                info("  0x%x [type: %d, '%s.%s', kind: %s (%d)]" % (
                    i, imp.type, imp.module, imp.field,
                    EXTERNAL_KIND_NAMES[imp.kind], imp.kind))
            elif imp.kind in [0x1,0x2]:  # Table & Memory
                info("  0x%x ['%s.%s', kind: %s (%d), initial: %d, maximum: %d]" % (
                    i, imp.module, imp.field,
                    EXTERNAL_KIND_NAMES[imp.kind], imp.kind,
                    imp.initial, imp.maximum))
            elif imp.kind == 0x3:  # Global
                info("  0x%x ['%s.%s', kind: %s (%d), type: %d, mutability: %d]" % (
                    i, imp.module, imp.field,
                    EXTERNAL_KIND_NAMES[imp.kind], imp.kind,
                    imp.type, imp.mutability))

        info("Functions:")
        for i, f in enumerate(self.function):
            info("  0x%x %s" % (i, func_repr(f)))

        info("Tables:")
        for t, entries in self.table.items():
            info("  0x%x -> [%s]" % (t,",".join([hex(e) for e in entries])))

        def hexpad(x, cnt):
            s = "%x" % x
            return '0' * (cnt-len(s)) + s

        info("Memory:")
        if self.memory.pages > 0:
            for r in range(10):
                info("  0x%s [%s]" % (hexpad(r*16,3),
                    ",".join([hexpad(b,2) for b in self.memory.bytes[r*16:r*16+16]])))

        info("Global:")
        for i, g in enumerate(self.global_list):
            info("  0x%s [%s]" % (i, value_repr(g)))

        info("Exports:")
        for i, e in enumerate(self.export_list):
            info("  0x%x %s" % (i, export_repr(e)))
        info("")

        bl = self.block_map
        block_keys = list(bl.keys())  # Convert dict_keys to a list
        block_keys.sort()  # Now we can sort the list
        info("block_map: %s" % (
            ["%s[0x%x->0x%x]" % (block_repr(bl[k]), bl[k].start, bl[k].end)
             for k in block_keys]))
        info("")


    ## Wasm top-level readers

    def read_magic(self):
        magic = self.rdr.read_word()
        if magic != MAGIC:
            raise Exception("Wanted magic 0x%x, got 0x%x" % (
                MAGIC, magic))

    def read_version(self):
        self.version = self.rdr.read_word()
        if self.version != VERSION:
            raise Exception("Wanted version 0x%x, got 0x%x" % (
                VERSION, self.version))

    def read_section(self):
        cur_pos = self.rdr.pos
        id = self.rdr.read_LEB(7)
        name = SECTION_NAMES[id]
        length = self.rdr.read_LEB(32)
        debug("parsing %s(%d), section start: 0x%x, payload start: 0x%x, length: 0x%x bytes" % (
            name, id, cur_pos, self.rdr.pos, length))
        if   "Type" == name:     self.parse_Type(length)
        elif "Import" == name:   self.parse_Import(length)
        elif "Function" == name: self.parse_Function(length)
        elif "Table" == name:    self.parse_Table(length)
        elif "Memory" == name:   self.parse_Memory(length)
        elif "Global" == name:   self.parse_Global(length)
        elif "Export" == name:   self.parse_Export(length)
        elif "Start" == name:    self.parse_Start(length)
        elif "Element" == name:  self.parse_Element(length)
        elif "Code" == name:     self.parse_Code(length)
        elif "Data" == name:     self.parse_Data(length)
        else:                    self.rdr.read_bytes(length)

    def read_sections(self):
        while not self.rdr.eof():
            self.read_section()

    ## Wasm section handlers

    def parse_Type(self, length):
        count = self.rdr.read_LEB(32)
        for c in range(count):
            form = self.rdr.read_LEB(7)
            params = []
            results = []
            param_count = self.rdr.read_LEB(32)
            for pc in range(param_count):
                params.append(self.rdr.read_LEB(32))
            result_count = self.rdr.read_LEB(32)
            for rc in range(result_count):
                results.append(self.rdr.read_LEB(32))
            tidx = len(self.type)
            t = Type(tidx, form, params, results)
            self.type.append(t)

            # calculate a unique type mask
            t.mask = 0x80
            if result_count == 1:
                t.mask |= 0x80 - results[0]
            t.mask = t.mask << 4
            for p in params:
                t.mask = t.mask << 4
                t.mask |= 0x80 - p

            debug("  parsed type: %s" % type_repr(t))


    def parse_Import(self, length):
        count = self.rdr.read_LEB(32)
        for c in range(count):
            module_len = self.rdr.read_LEB(32)
            module_bytes = self.rdr.read_bytes(module_len)
            module = "".join([chr(f) for f in module_bytes])

            field_len = self.rdr.read_LEB(32)
            field_bytes = self.rdr.read_bytes(field_len)
            field = "".join([chr(f) for f in field_bytes])

            kind = self.rdr.read_byte()

            if kind == 0x0:  # Function
                type_index = self.rdr.read_LEB(32)
                type = self.type[type_index]
                imp = Import(module, field, kind, type=type_index)
                self.import_list.append(imp)
                func = FunctionImport(type, module, field)
                self.function.append(func)
                self.fn_import_cnt += 1
            elif kind in [0x1,0x2]:  # Table & Memory
                if kind == 0x1:
                    etype = self.rdr.read_LEB(7) # TODO: ignore?
                flags = self.rdr.read_LEB(32)
                initial = self.rdr.read_LEB(32)
                if flags & 0x1:
                    maximum = self.rdr.read_LEB(32)
                else:
                    maximum = 0
                self.import_list.append(Import(module, field, kind,
                    initial=initial, maximum=maximum))
            elif kind == 0x3:  # Global
                type = self.rdr.read_byte()
                mutability = self.rdr.read_LEB(1)
                self.global_list.append(self.import_value(module, field))

    def parse_Function(self, length):
        count = self.rdr.read_LEB(32)
        for c in range(count):
            type = self.type[self.rdr.read_LEB(32)]
            idx = len(self.function)
            self.function.append(Function(type, idx))

    def parse_Table(self, length):
        count = self.rdr.read_LEB(32)
        assert count == 1

        initial = 1
        for c in range(count):
            type = self.rdr.read_LEB(7)
            assert type == ANYFUNC
            flags = self.rdr.read_LEB(1) # TODO: fix for MVP
            initial = self.rdr.read_LEB(32) # TODO: fix for MVP
            if flags & 0x1:
                maximum = self.rdr.read_LEB(32)
            else:
                maximum = initial

            self.table[type] = [0] * initial

    def parse_Memory(self, length):
        count = self.rdr.read_LEB(32)
        assert count <= 1  # MVP
        flags = self.rdr.read_LEB(32)  # TODO: fix for MVP
        initial = self.rdr.read_LEB(32)
        if flags & 0x1:
            maximum = self.rdr.read_LEB(32)
        else:
            maximum = 0
        self.memory = Memory(initial)

    def parse_Global(self, length):
        count = self.rdr.read_LEB(32)
        for c in range(count):
            content_type = self.rdr.read_LEB(7)
            mutable = self.rdr.read_LEB(1)
#            print("global: content_type: %s, BLOCK_TYPE: %s, mutable: %s"
#                    % (VALUE_TYPE[content_type],
#                        type_repr(BLOCK_TYPE[content_type]),
#                        mutable))
            # Run the init_expr
            block = Block(0x00, BLOCK_TYPE[content_type], self.rdr.pos)
            self.csp += 1
            self.callstack[self.csp] = (block, self.sp, self.fp, 0)
            # WARNING: running code here to get offset!
            self.interpret()  # run iter_expr
            init_val = self.stack[self.sp]
#            print("init_val: %s" % value_repr(init_val))
            self.sp -= 1
            assert content_type == init_val[0]
            self.global_list.append(init_val)

    def parse_Export(self, length):
        count = self.rdr.read_LEB(32)
        for c in range(count):
            field_len = self.rdr.read_LEB(32)
            field_bytes = self.rdr.read_bytes(field_len)
            field = "".join([chr(f) for f in field_bytes])
            kind = self.rdr.read_byte()
            index = self.rdr.read_LEB(32)
            exp = Export(field, kind, index)
            self.export_list.append(exp)
            debug("  parsed export: %s" % export_repr(exp))
            self.export_map[field] = exp

    def parse_Start(self, length):
        fidx = self.rdr.read_LEB(32)
        self.start_function = fidx

    def parse_Element(self, length):
        start = self.rdr.pos
        count = self.rdr.read_LEB(32)

        for c in range(count):
            index = self.rdr.read_LEB(32)
            assert index == 0  # Only 1 default table in MVP

            # Run the init_expr
            block = Block(0x00, BLOCK_TYPE[I32], self.rdr.pos)
            self.csp += 1
            self.callstack[self.csp] = (block, self.sp, self.fp, 0)
            # WARNING: running code here to get offset!
            self.interpret()  # run iter_expr
            offset_val = self.stack[self.sp]
            self.sp -= 1
            assert offset_val[0] == I32
            offset = int(offset_val[1])

            num_elem = self.rdr.read_LEB(32)
            self.table[ANYFUNC] = [0] * (offset + num_elem)
            table = self.table[ANYFUNC]
            for n in range(num_elem):
                fidx = self.rdr.read_LEB(32)
                table[offset+n] = fidx

        assert self.rdr.pos == start+length

    def parse_Code_body(self, idx):
        body_size = self.rdr.read_LEB(32)
        payload_start = self.rdr.pos
        #debug("body_size %d" % body_size)
        local_count = self.rdr.read_LEB(32)
        #debug("local_count %d" % local_count)
        locals = []
        for l in range(local_count):
            count = self.rdr.read_LEB(32)
            type = self.rdr.read_LEB(7)
            for c in range(count):
                locals.append(type)
        # TODO: simplify this calculation and find_blocks
        start = self.rdr.pos
        self.rdr.read_bytes(body_size - (self.rdr.pos-payload_start)-1)
        end = self.rdr.pos
        debug("  find_blocks idx: %d, start: 0x%x, end: 0x%x" % (idx, start, end))
        self.rdr.read_bytes(1)
        func = self.function[idx]
        assert isinstance(func,Function)
        func.update(locals, start, end)
        self.block_map = find_blocks(
                self.rdr.bytes, start, end, self.block_map)

    def parse_Code(self, length):
        body_count = self.rdr.read_LEB(32)
        for idx in range(body_count):
            self.parse_Code_body(idx + self.fn_import_cnt)

    def parse_Data(self, length):
        seg_count = self.rdr.read_LEB(32)
        for seg in range(seg_count):
            index = self.rdr.read_LEB(32)
            assert index == 0  # Only 1 default memory in MVP

            # Run the init_expr
            block = Block(0x00, BLOCK_TYPE[I32], self.rdr.pos)
            self.csp += 1
            self.callstack[self.csp] = (block, self.sp, self.fp, 0)
            # WARNING: running code here to get offset!
            self.interpret()  # run iter_expr
            offset_val = self.stack[self.sp]
            self.sp -= 1
            assert offset_val[0] == I32
            offset = int(offset_val[1])

            size = self.rdr.read_LEB(32)
            for addr in range(offset, offset+size, 1):
                self.memory.bytes[addr] = self.rdr.read_byte()

    def interpret(self):
        self.rdr.pos, self.sp, self.fp, self.csp = interpret_mvp(self,
                # Greens
                self.rdr.pos, self.rdr.bytes, self.function,
                self.table, self.block_map,
                # Reds
                self.memory, self.sp, self.stack, self.fp, self.csp,
                self.callstack)


    def run(self, fname, args, print_return=False):
        # Reset stacks
        self.sp  = -1
        self.fp  = -1
        self.csp = -1

        fidx = self.export_map[fname].index

        # Check arg type
        tparams = self.function[fidx].type.params
        assert len(tparams) == len(args), "arg count mismatch %s != %s" % (len(tparams), len(args))
        for idx, arg in enumerate(args):
            assert tparams[idx] == arg[0], "arg type mismatch %s != %s" % (tparams[idx], arg[0])
            self.sp += 1
            self.stack[self.sp] = arg

        info("Running function '%s' (0x%x)" % (fname, fidx))
        if TRACE:
            dump_stacks(self.sp, self.stack, self.fp, self.csp,
                    self.callstack)
        self.rdr.pos, self.sp, self.fp, self.csp = do_call(
                self.stack, self.callstack, self.sp, self.fp,
                self.csp, self.function[fidx], 0)

        self.interpret()
        if TRACE:
            dump_stacks(self.sp, self.stack, self.fp, self.csp,
                    self.callstack)

        targs = [value_repr(a) for a in args]
        if self.sp >= 0:
            ret = self.stack[self.sp]
            self.sp -= 1
            info("%s(%s) = %s" % (fname, ", ".join(targs), value_repr(ret)))
            if print_return:
                print(value_repr(ret))
        else:
            info("%s(%s)" % (fname, ", ".join(targs)))
        return 0

######################################
# Imported functions points
######################################


def readline(prompt):
    res = ''
    sys.stdout.write(prompt)
    sys.stdout.flush()
    while True:
        buf = sys.stdin.readline()
        if not buf: raise EOFError()
        res += buf
        if res[-1] == '\n': return res[:-1]

def get_string(mem, addr):
    slen = 0
    assert addr >= 0
    while mem.bytes[addr+slen] != 0: slen += 1
    bytes_data = mem.bytes[addr:addr+slen]
    return bytes(bytes_data).decode('utf-8')

def put_string(mem, addr, string):
    pos = addr
    bytes_data = string.encode('utf-8')
    for i in range(len(bytes_data)):
        mem.bytes[pos] = bytes_data[i]
        pos += 1
    mem.bytes[pos] = 0  # zero terminated
    return pos


######################################
# Entry points
######################################


def entry_point(argv):
    try:
        # Argument handling
        repl = False
        argv_mode = False
        memory_pages = 1
        fname = None
        args = []
        run_args = []
        idx = 1
        while idx < len(argv):
            arg = argv[idx]
            idx += 1
            if arg == "--help":
                usage(argv)
                return 1
            elif arg == "--repl":
                repl = True
            elif arg == "--argv":
                argv_mode = True
                memory_pages = 256
            elif arg == "--memory-pages":
                memory_pages = int(argv[idx])
                idx += 1
            elif arg == "--":
                continue
            elif arg.startswith('--'):
                print("Unknown option '%s'" % arg)
                usage(argv)
                return 2
            else:
                args.append(arg)
        with open(args[0], 'rb') as file:
            wasm = file.read()
        args = args[1:]

        #
        mem = Memory(memory_pages)

        if argv_mode:
            # Convert args into C argv style array of strings and
            # store at the beginning of memory. This must be before
            # the module is initialized so that we can properly set
            # the memoryBase global before it is imported.
            args.insert(0, argv[0])
            string_next = (len(args) + 1) * 4
            for i, arg in enumerate(args):
                slen = put_string(mem, string_next, arg)
                write_I32(mem.bytes, i*4, string_next) # zero terminated
                string_next += slen

            # Set memoryBase to next 64-bit aligned address
            string_next += (8 - (string_next % 8))
            IMPORT_VALUES['env.memoryBase'] = (I32, string_next, 0.0)


        m = Module(wasm, import_value, import_function, mem)

        if argv_mode:
            fname = "_main"
            fidx = m.export_map[fname].index
            arg_count = len(m.function[fidx].type.params)
            if arg_count == 2:
                run_args = [(I32, len(args), 0.0), (I32, 0, 0.0)]
            elif arg_count == 0:
                run_args = []
            else:
                raise Exception("_main has %s args, should have 0 or 2" %
                        arg_count)
        else:
            # Convert args to expected numeric type. This must be
            # after the module is initialized so that we know what
            # types the arguments are
            fname, run_args = parse_command(m, args)

        if '__post_instantiate' in m.export_map:
            m.run('__post_instantiate', [])

        if not repl:

            # Invoke one function and exit
            try:
                return m.run(fname, run_args, not argv_mode)
            except WAException as e:
                os.write(2, "".join(traceback.format_exception(*sys.exc_info())))
                os.write(2, "%s\n" % e.message)
                return 1
        else:
            # Simple REPL
            while True:
                try:
                    line = readline("webassembly> ")
                    if line == "": continue

                    fname, run_args = parse_command(m, line.split(' '))
                    res = m.run(fname, run_args, True)
                    if not res == 0:
                        return res

                except WAException as e:
                    os.write(2, "Exception: %s\n" % e.message)
                except EOFError as e:
                    break

    except WAException as e:
        sys.stderr.write("".join(traceback.format_exception(*sys.exc_info())))
        sys.stderr.write("Exception: %s\n" % str(e))
    except ExitException as e:
        return e.code
    except Exception as e:
        sys.stderr.write("".join(traceback.format_exception(*sys.exc_info())))
        return 1

    return 0

def target(*args):
    return entry_point

if __name__ == '__main__':
    sys.exit(entry_point(sys.argv))