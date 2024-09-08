import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class wamcMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        var app = getApp();
        var a = 0;
        var b = 0;
        if (item == :add12) {
            a = 1;
            b = 2;
            var result = app.add(a, b);
            terminal.addLine("1+2=" + result[1]);
        } else if (item == :add16) {
            a = 1;
            b = 6;
            var result = app.add(a, b);
            terminal.addLine("1+6=" + result[1]);
        } else if (item == :fizzbuzz) {
            // app.fizzbuzz();
            terminal.addLine("async not impl, use onSelect");
        } else if (item == :moreOps) {
            app.maxAsyncOps += 100;
            terminal.addLine("Increased ops/s to " + app.maxAsyncOps);
        } else if (item == :fewerOps) {
            var maxOps = app.maxAsyncOps;
            maxOps = (maxOps - 100 < 0) ? 0 : maxOps - 100;
            app.maxAsyncOps = maxOps;
            terminal.addLine("Decreased ops/s to " + app.maxAsyncOps);
        }
    }

}