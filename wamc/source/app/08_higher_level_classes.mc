import Toybox.Lang;
import Toybox.System;

typedef ImportMethodType as Method(module_ as String, field as String) as Array<Number>;
typedef ImportFunctionType as Method(module_ as String, field as String, mem as Memory, args as Array<Array<Number>>) as Array<Array<Number>>;
typedef StackType as Array<Array<Number>>;
typedef CallStackType as Array<Array<Number or Block or Function>>;
typedef Global as ValueTupleType;
typedef ValueTupleType as [Number, Number, Float];

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

    public function readLEB(maxbits as Number, signed as Boolean) as Number {
        throw new NotImplementedException();
        // var result = $.readLEB(self.bytes, self.pos, maxbits, signed);
        // self.pos = result[0];
        // return result[1];
    }

    public function eof() as Boolean {
        return self.pos >= self.bytes.size();
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
                self.bytes.addAll(new [remainingSize]);
            }
        } else {
            self.bytes = new [pages * (1 << 16)];
        }
    }

    public function grow(pages as Number) as Void {
        self.pages += pages.toNumber();
        var additionalBytes = new [pages.toNumber() * (1 << 16)];
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
}

class Module {
    private var data as ByteArray;
    private var rdr as Reader;
    // private var importValue as ImportMethodType;
    private var importFunction as ImportFunctionType;

    // Sections
    private var type as Array<Type>;
    // private var importList as Array<Import>;
    var function_ as Array<Function>;
    // private var fnImportCnt as Number;
    private var table as Dictionary<Number, Array<Number>>;
    private var exportList as Array<Export>;
    private var exportMap as Dictionary<String, Export>;
    private var globalList as Array<Global>;

    private var memory as Memory;

    // // block/loop/if blocks {start addr: Block, ...}
    // private var blockMap as Dictionary<Number, Block>;

    // Execution state
    private var sp as Number;
    private var fp as Number;
    private var stack as StackType;
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
        // self.importList = [];
        self.function_ = [];
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

        // self.blockMap = {};

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

        // dump();

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

    // ... [Other methods like readMagic(), readVersion(), readSections(), dump(), interpret(), etc.]

    public function run(fname as String, args as Array<Array<Number>>, printReturn as Boolean) as Number {
        // Reset stacks
        self.sp = -1;
        self.fp = -1;
        self.csp = -1;

        var fidx = self.exportMap[fname].index;

        // // Check arg type
        // var tparams = self.function_[fidx].type.params;
        // if (tparams.size() != args.size()) {
        //     throw new Lang.Exception("arg count mismatch " + tparams.size() + " != " + args.size());
        // }
        // for (var idx = 0; idx < args.size(); idx++) {
        //     if (tparams[idx] != args[idx][0]) {
        //         throw new Lang.Exception("arg type mismatch " + tparams[idx] + " != " + args[idx][0]);
        //     }
        //     self.sp++;
        //     self.stack[self.sp] = args[idx];
        // }

        System.println("Running function '" + fname + "' (0x" + fidx.format("%x") + ")");
        // if (TRACE) {
        //     dumpStacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        // }
        var result = doCall(self.stack, self.callstack, self.sp, self.fp, self.csp, self.function_[fidx], 0, false);
        self.rdr.pos = result[0];
        self.sp = result[1];
        self.fp = result[2];
        self.csp = result[3];

        // interpret();
        // if (TRACE) {
        //     dumpStacks(self.sp, self.stack, self.fp, self.csp, self.callstack);
        // }

        // var targs = args.map(function(a) {
        //     return valueRepr(a);
        // });
        // if (self.sp >= 0) {
        //     var ret = self.stack[self.sp];
        //     self.sp--;
        //     System.println(fname + "(" + Lang.format("$1$", [targs.join(", ")]) + ") = " + valueRepr(ret));
        //     if (printReturn) {
        //         System.println(valueRepr(ret));
        //     }
        // } else {
        //     System.println(fname + "(" + Lang.format("$1$", [targs.join(", ")]) + ")");
        // }
        // return 0;
    }

    // ... [Helper methods like valueRepr(), dumpStacks(), etc.]
}