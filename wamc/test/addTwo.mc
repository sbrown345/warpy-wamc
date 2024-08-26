import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class GeneratedWasmModule {
    static function createModule() {
        var module_ = new Module(
            // Types
            new Type(0, 96, [127, 127], [127], 528401),
            // Functions
            new Function(module_.type[0], 0),
            // Tables
            new Table(112, []),
            // Memory
            new Memory(1),
            // Globals
            // Exports
            new Export("addTwo", 0, 0),
        );
        // Function bodies
        module_.function_[0].update([], 38, 43, 0, 43);

        // Data sections
        return module_;
    }
}
