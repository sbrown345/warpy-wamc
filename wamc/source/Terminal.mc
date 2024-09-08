import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.StringUtil;

class Terminal {
    private var _lines as Array<String>;
    private var _maxLines as Number;
    private var _font as Graphics.FontType;
    private var _currentLine as Array<Number>;

    function initialize(maxLines as Number, font as Graphics.FontType) {
        _lines = [];
        _maxLines = maxLines;
        _font = font;
        _currentLine = [];
    }

    function putChar(char as Number) as Void {
        _currentLine.add(char);
        if (char == 10) {  // ASCII for newline
            addLine(StringUtil.utf8ArrayToString(_currentLine));
            _currentLine = [];
        }
    }

    function addLine(text as String) as Void {
        _lines.add(text);
        if (_lines.size() > _maxLines) {
            _lines = _lines.slice(_lines.size() - _maxLines, null);
        }
        WatchUi.requestUpdate();
    }

    function draw(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var lineHeight = dc.getFontHeight(_font);
        for (var i = 0; i < _lines.size(); i++) {
            dc.drawText(x, y + (i * lineHeight), _font, _lines[i], Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}