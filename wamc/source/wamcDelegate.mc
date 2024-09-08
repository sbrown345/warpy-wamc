import Toybox.Lang;
import Toybox.WatchUi;

class wamcDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new wamcMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() as Boolean {
        // var result = getApp().add(12, 21);
        var result = getApp().fizzbuzz();
        System.println("result = " + host_output);
    }
}