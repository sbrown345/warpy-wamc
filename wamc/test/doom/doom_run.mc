
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

function Wamc_test_doom_doom_import_function(module_ as Module, field as String, mem as Memory, args as ValueTupleType) as ValueTupleType {
    var fname = module_ + "." + field;
    
    if (fname.equals("js.js_milliseconds_since_start")) {
        return i32(System.getTimer());
    } else if (fname.equals("js.js_console_log")) {
        System.println("log: " + args);
        return i32(0);
    } else if (fname.equals("js.js_stdout")) {
        System.println("stdout: " + args);
        return i32(0);
    } else if (fname.equals("js.js_stderr")) {
        System.println("stderr: " + args);
        return i32(0);
    } else if (fname.equals("js.js_draw_screen")) {
        System.println("draw screen: " + args);
        return i32(0);
    } else {
        throw new WAException("function import " + fname + " not found");
    }
}

class Wamc_test_doom_run {
    (:test)
    static function test_doom(logger as Test.Logger) as Boolean {
        var m = Wamc_test_doom_doom.createModule();
        var run_args = [];
        var result = m.runStartFunction();
        System.println("result = " + result);
    }
}