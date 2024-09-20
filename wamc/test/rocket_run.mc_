
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// https://gist.github.com/dabeaz/7d8838b54dba5006c58a40fc28da9d5a

class Wamc_test_rocket_run {
    (:test)
    static function test_rocket(logger as Test.Logger) as Boolean {
        var m = Wamc_test_rocket.createModule();
        var run_args = [];

        m.run("resize", [f64(280), f64(280)]);

        // Simple game loop (for demonstration)
        for (var i = 0; i < 10; i++) {  // Run 10 frames
            m.run("update", [f64(0.016)]);  // 60 FPS
            m.run("draw", []);
        }

        return false;
    }

    function Wamc_test_rocket_import_function(module_ as Module, field as String, mem as Memory, args as ValueTupleType) as ValueTupleType {
        var fname = module_ + "." + field;
        
        if (fname.equals("env.Math_atan")) {
            return f64(Math.atan(args[0][2]));
        } else if (fname.equals("env.clear_screen")) {
            System.println("clear_screen");
            return i32(0);
        } else if (fname.equals("env.cos")) {
            return f64(Math.cos(args[0][2]));
        } else if (fname.equals("env.draw_bullet")) {
            System.println("draw_bullet " + args[0][2] + " " + args[1][2]);
            return i32(0);
        } else if (fname.equals("env.draw_enemy")) {
            System.println("draw_enemy " + args[0][2] + " " + args[1][2]);
            return i32(0);
        } else if (fname.equals("env.draw_particle")) {
            System.println("draw_particle " + args[0][2] + " " + args[1][2] + " " + args[2][2]);
            return i32(0);
        } else if (fname.equals("env.draw_player")) {
            System.println("draw_player " + args[0][2] + " " + args[1][2] + " " + args[2][2]);
            return i32(0);
        } else if (fname.equals("env.draw_score")) {
            System.println("draw_score " + args[0][2]);
            return i32(0);
        } else if (fname.equals("env.sin")) {
            return f64(Math.sin(args[0][2]));
        } else {
            throw new WAException("function import " + fname + " not found");
        }
    }
}