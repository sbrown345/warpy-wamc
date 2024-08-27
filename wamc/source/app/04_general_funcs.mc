import Toybox.Lang;
import Toybox.System;

function info_(str, end) {
    if (INFO) {
        if (end == null) {
            end = "\n";
        }
        System.println("ERR: " + str + end);
    }
}

function debug_(str, end) {
    if (DEBUG) {
        if (end == null) {
            end = "\n";
        }
        System.println("DEBUG: " + str + end);
    }
}














function doCall(stack as StackType, callstack as CallStackType, sp as Number, fp as Number, csp as Number, func, pc as Number, indirect as Boolean) as Number {
    System.println("do call");
}