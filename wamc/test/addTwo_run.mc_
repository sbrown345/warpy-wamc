
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class Wamc_test_addTwo_run {
    (:test)
    static function test_1_plus_2(logger as Test.Logger) as Boolean {
        var m = Wamc_test_addTwo.createModule();
        var run_args = [[I32, 1, 0.0], [I32, 2, 0.0]];
        var result = m.runWithArgs("addTwo", run_args, true, true);
        System.println("result = " + result);
        return assertEqual([I32, 3, 0.0], result);
    }
}