
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class AddTwoRunTest {
    (:test)
    static function test_1_plus_2(logger as Test.Logger) as Boolean {
        var m = GeneratedWasmModule.createModule();
        var run_args = [[I32, 1, 0.0], [I32, 2, 0.0]]; // type, int, float
        var result = m.run("addTwo", run_args, true, true);
        System.println("ret = " + result);
        return result[0] == I32 && result[1] == 3;
    }
}