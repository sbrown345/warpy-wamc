import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class wamcMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        var a = 0;
        var b = 0;
        if (item == :add12) {
            a = 1;
            b = 2;
            var result = getApp().add(a, b);
            terminal.addLine("1+2=" + result[1]);
        } else if (item == :add16) {
            a = 1;
            b = 6;
            var result = getApp().add(a, b);
            terminal.addLine("1+6=" + result[1]);
        } else if (item == :fizzbuzz) {
            getApp().fizzbuzz();
        }
    }

}