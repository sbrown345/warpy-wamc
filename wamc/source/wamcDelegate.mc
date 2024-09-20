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
        getApp().doom();
        return true;
    }

    function onFizzbuzzComplete(result as ValueTupleType) as Void {
        System.println("result = " + result);
        WatchUi.requestUpdate();
    }
}