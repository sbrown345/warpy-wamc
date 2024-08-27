import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class GeneratedWasmModule {
    static function createModule() {
        var module_ = new Module(
            // WASM bytecode
            [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x07, 0x01, 0x60, 0x02, 0x7f, 0x7f, 0x01, 0x7f, 0x03, 0x02, 0x01, 0x00, 0x07, 0x0a, 0x01, 0x06, 0x61, 0x64, 0x64, 0x54, 0x77, 0x6f, 0x00, 0x00, 0x0a, 0x09, 0x01, 0x07, 0x00, 0x20, 0x00, 0x20, 0x01, 0x6a, 0x0b, 0x00, 0x19, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x01, 0x09, 0x01, 0x00, 0x06, 0x61, 0x64, 0x64, 0x54, 0x77, 0x6f, 0x02, 0x07, 0x01, 0x00, 0x02, 0x00, 0x00, 0x01, 0x00]b,
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
                new Function(0, 0),
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
                new Export("addTwo", 0, 0),
            ],
            // Export map
            {
                "addTwo" => new Export("addTwo", 0, 0),
            }
        );
        // Function bodies
        module_.function_[0].update([], 38, 43, 0, 43);

        // Data sections
        return module_;
    }
}
