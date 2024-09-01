import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class I32_test_factory_0 {
    static function createModule() {
        var module_ = new Module(
            // WASM bytecode
            [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x07, 0x01, 0x60, 0x02, 0x7f, 0x7f, 0x01, 0x7f, 0x03, 0x04, 0x03, 0x00, 0x00, 0x00, 0x07, 0x13, 0x03, 0x03, 0x61, 0x64, 0x64, 0x00, 0x00, 0x03, 0x73, 0x75, 0x62, 0x00, 0x01, 0x03, 0x6d, 0x75, 0x6c, 0x00, 0x02, 0x0a, 0x19, 0x03, 0x07, 0x00, 0x20, 0x00, 0x20, 0x01, 0x6a, 0x0b, 0x07, 0x00, 0x20, 0x00, 0x20, 0x01, 0x6b, 0x0b, 0x07, 0x00, 0x20, 0x00, 0x20, 0x01, 0x6c, 0x0b]b,
            // Imported Functions
            [
            ],
            // Memory
            new Memory(1, null),
            // Types
            [
                new Type(0, 96, [127, 127], [127], 528401),
            ],
            // Functions
            [
                new Function(new Type(0, 96, [127, 127], [127], 528401), 0, [], 49, 54, 0, 54),
                new Function(new Type(0, 96, [127, 127], [127], 528401), 1, [], 57, 62, 0, 62),
                new Function(new Type(0, 96, [127, 127], [127], 528401), 2, [], 65, 70, 0, 70),
            ],
            // Tables
            {
                112 => [],
            },
            // Globals
            [
            ],
            // Exports
            [
                new Export("add", 0, 0),
                new Export("sub", 0, 1),
                new Export("mul", 0, 2),
            ],
            // Export map
            {
                "add" => new Export("add", 0, 0),
                "sub" => new Export("sub", 0, 1),
                "mul" => new Export("mul", 0, 2),
            }
        );

        // Data sections
        return module_;
    }
}
