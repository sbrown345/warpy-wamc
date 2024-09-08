import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

var terminal as Terminal;

class wamcApp extends Application.AppBase {
    var waModule;

    function initialize() {
        AppBase.initialize();
        waModule = Wamc_test_addTwo.createModule();
        terminal = new Terminal(10, Graphics.FONT_XTINY);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new wamcView(), new wamcDelegate() ];
    }

    function add(a as Number, b as Number) as ValueTupleType {
        var run_args = [[I32, a, 0.0], [I32, b, 0.0]]; // type, int, float
        var result = waModule.runWithArgs("addTwo", run_args, true, true);
        System.println("result = " + result);
        return result;
    }

    function fizzbuzz() as ValueTupleType {
        var m = Wamc_test_fizzbuzz.createModule();
        var result = m.runStartFunction();
        return result;
    }
}

function getApp() as wamcApp {
    return Application.getApp() as wamcApp;
}