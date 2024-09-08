import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class wamcView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // terminal.addLine("Welcome to WAMC Terminal");
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.clear();

        var offset = 54;
        terminal.draw(dc, offset, offset, dc.getWidth() - offset, dc.getHeight() - offset);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Public method to add text to the terminal
    function addToTerminal(text as String) as Void {
        terminal.addLine(text);
    }
}