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

}