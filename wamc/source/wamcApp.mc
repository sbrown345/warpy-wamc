import Toybox.Application;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

var terminal as Terminal;
var interpretStep as Timer;

const DEFAULT_DEVICE_OPERATIONS = 800;

class wamcApp extends Application.AppBase {
    var waModule;
    var fizzbuzzModule as Module;
    var maxAsyncOps = DEFAULT_DEVICE_OPERATIONS;

    function initialize() {
        AppBase.initialize();
        waModule = Wamc_test_addTwo.createModule();
        fizzbuzzModule = Wamc_test_fizzbuzz.createModule();
        System.println("app init");
        terminal = new Terminal(10, Graphics.FONT_XTINY);
        interpretStep = new Timer.Timer();
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

    // add
    function add(a as Number, b as Number) as ValueTupleType {
        var run_args = [[I32, a, 0.0], [I32, b, 0.0]]; // type, int, float
        var result = waModule.runWithArgs("addTwo", run_args, true, true);
        System.println("result = " + result);
        return result;
    }

    // fizzbuzz
    private var fizzbuzzCallback as Method(ValueTupleType)?;
    private var startTime as Number;

    function fizzbuzz(callback as Method(ValueTupleType)) as Void {
        if (fizzbuzzModule.isAsyncRunning()) {
            WatchUi.showToast("Already running", {});
            return;
        }
        
        startTime = System.getTimer();
        fizzbuzzCallback = callback;
        fizzbuzzModule.runStartFunctionAsync(getApp().maxAsyncOps, method(:onFizzbuzzComplete));
    }

    function onFizzbuzzComplete(result as ValueTupleType) as Void {
        var endTime = System.getTimer();
        var timeTaken = endTime - startTime;
        System.println("Time taken to complete fizzbuzz: " + timeTaken + " ms");
        terminal.addLine(timeTaken + " ms (" + maxAsyncOps + "op/s)");

        if (fizzbuzzCallback != null) {
            fizzbuzzCallback.invoke(result);
            fizzbuzzCallback = null;
        }
    }
}

function getApp() as wamcApp {
    return Application.getApp() as wamcApp;
}