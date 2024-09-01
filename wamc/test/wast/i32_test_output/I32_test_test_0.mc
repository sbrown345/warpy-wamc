
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests generated from ./wamc/test/wast/i32_test.wast

class WasmTests_I32_test_0 {

    (:test)
    static function test_I32_test_0_1_Add___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:35
        // Field: add
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("add", [i32(1), i32(1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(2));
    }

    (:test)
    static function test_I32_test_0_2_Add___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:36
        // Field: add
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("add", [i32(1), i32(0)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(1));
    }

    (:test)
    static function test_I32_test_0_3_Add___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:37
        // Field: add
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("add", [i32(-1), i32(-1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(-2));
    }

    (:test)
    static function test_I32_test_0_4_Add___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:38
        // Field: add
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("add", [i32(-1), i32(1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(0));
    }

    (:test)
    static function test_I32_test_0_5_Sub___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:44
        // Field: sub
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("sub", [i32(1), i32(1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(0));
    }

    (:test)
    static function test_I32_test_0_6_Sub___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:45
        // Field: sub
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("sub", [i32(1), i32(0)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(1));
    }

    (:test)
    static function test_I32_test_0_7_Sub___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:46
        // Field: sub
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("sub", [i32(-1), i32(-1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(0));
    }

    (:test)
    static function test_I32_test_0_8_Mul___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:52
        // Field: mul
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("mul", [i32(1), i32(1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(1));
    }

    (:test)
    static function test_I32_test_0_9_Mul___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:53
        // Field: mul
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("mul", [i32(1), i32(0)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(0));
    }

    (:test)
    static function test_I32_test_0_10_Mul___(logger as Test.Logger) as Boolean {
        // Test from ./wamc/test/wast/i32_test.wast:54
        // Field: mul
        // Expected type: i32
        var m = I32_test_factory_0.createModule();
        var result = m.run("mul", [i32(-1), i32(-1)]);

        logger.debug("Result = " + result);
        return assertEqual(result, i32(1));
    }
}
