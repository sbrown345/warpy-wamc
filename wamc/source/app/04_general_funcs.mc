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