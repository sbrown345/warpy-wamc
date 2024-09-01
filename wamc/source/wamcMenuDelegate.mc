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
        } else if (item == :add16) {
            a = 1;
            b = 6;
        }

        var result = getApp().add(a, b);
        WatchUi.showToast("=" + result[1], null);
    }

}