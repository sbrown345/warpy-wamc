import Toybox.System;
import Toybox.Lang;
import Toybox.Test;

// Test cases
// (:test)
function testRotr32(logger as Logger) as Boolean {
    // Failed tests: [0, 1, 2]
    var tests = [
        [0x47890abc, 14, 0xd6e22b91],
        [0x47890abc, 14, 0xd6e22b91],  // The case from your example (1199797690 in decimal)
        [0xFFFFFFFF, 1, 0x7FFFFFFF],
        [0x12345678, 4, 0x81234567],
        [0x80000000, 1, 0x40000000],
        [0x00000001, 31, 0x00000002],
        [0xDEADBEEF, 0, 0xDEADBEEF],
        [0x01234567, 32, 0x01234567],  // Full rotation should return the same number
        [0xFFFFFFFF, 16, 0xFFFFFFFF],
        [0x00FF00FF, 8, 0xFF00FF00],
    ];

    var failedTests = [];
    var passedTests = 0;

    for (var i = 0; i < tests.size(); i++) {
        var input = tests[i][0];
        var shift = tests[i][1];
        var expected = tests[i][2];
        var result = rotr32(input, shift);
        
        logger.debug("Test case " + i + ":");
        logger.debug("  Input:    0x" + input.format("%08x"));
        logger.debug("  Shift:    " + shift);
        logger.debug("  Expected: 0x" + expected.format("%08x"));
        logger.debug("  Got:      0x" + result.format("%08x"));
        
        if ((result & 0xFFFFFFFF) != (expected & 0xFFFFFFFF)) {
            failedTests.add(i);
            logger.error("Test case " + i + " FAILED ❌");
        } else {
            passedTests++;
            logger.debug("Test case " + i + " PASSED ✅");
        }
    }

    // Summary
    logger.debug("Test Summary:");
    logger.debug("  Total tests: " + tests.size());
    logger.debug("  Passed:      " + passedTests + " ✅");
    logger.debug("  Failed:      " + failedTests.size() + " ❌");
    
    if (failedTests.size() > 0) {
        logger.error("Failed tests: " + failedTests.toString());
        return false;
    } else {
        logger.debug("All tests passed successfully! 🎉");
        return true;
    }
}