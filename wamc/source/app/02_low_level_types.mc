import Toybox.Lang;
import Toybox.System;

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
    // This is an empty base class in the Python version
    // In MonkeyC, we'll define it as an empty class as well
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
        var fname = module_ + "." + field;
    }

    function toString() as String {
        return "FunctionImport(type: " + self.type + ", module: '" + self.module_ + "', field: '" + self.field + "')";
    }
}