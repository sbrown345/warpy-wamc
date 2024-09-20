import Toybox.System;
import Toybox.Lang;
import Toybox.Test;


// function i64_shr_u(value as Long, shift as Number) as Long {
//     if (shift == 0) {
//         return value;
//     }
    
//     if (shift >= 64) {
//         return 0;
//     }
    
//     var bytes = new [8]b;
//     write_I64(bytes, 0, value);
    
//     var fullBytes = shift / 8;
//     var remainingBits = shift % 8;
    
//     if (fullBytes > 0) {
//         for (var i = 0; i < 8 - fullBytes; i++) {
//             bytes[i] = bytes[i + fullBytes];
//         }
//         for (var i = 8 - fullBytes; i < 8; i++) {
//             bytes[i] = 0;
//         }
//     }
    
//     if (remainingBits > 0) {
//         var carry = 0;
//         for (var i = 7; i >= 0; i--) {
//             var newCarry = bytes[i] & ((1 << remainingBits) - 1);
//             bytes[i] = ((bytes[i] >> remainingBits) | (carry << (8 - remainingBits))) & 0xFF;
//             carry = newCarry;
//         }
//     }
    
//     return read_I64(bytes, 0);
// }

// Test cases
// (:test)
function testI64ShrU(logger as Logger) as Boolean {
    var tests = [
        // Simple tests
        [8l, 1, 4l],
        [16l, 2, 4l],
        [-8l, 1, 9223372036854775804l],
        [0l, 5, 0l],
        [1l << 63, 1, 1l << 62],
        [0xFFFFFFFFFFFFFFFFl, 4, 0x0FFFFFFFFFFFFFFFl], // fails
        [0x0123456789ABCDEFl, 8, 0x0001234567899BCDl],
        [0x8000000000000000l, 63, 1l],
        
        // Original tests
        [-760248312259484428l, 18, 67468627019691l],
        [0x8000000000000000l, 1, 0x4000000000000000l],
        [0xffffffffffffffffl, 1, 0x7fffffffffffffffl],
        [1l, 1, 0l],
        [-1l, 1, 0x7fffffffffffffffl],
        [0x123456789abcdef0l, 4, 0x0123456789abcdefl],
        [-8l, 1, 0x7ffffffffffffffcl],
    ];

    var failedTests = [];
    var passedTests = 0;

    for (var i = 0; i < tests.size(); i++) {
        var input = tests[i][0];
        var shift = tests[i][1];
        var expected = tests[i][2];
        var result = i64_shr_u(input, shift);
        
        logger.debug("Test case " + i + ":");
        logger.debug("  Input:    " + input + " (0x" + input.format("%x") + ")");
        logger.debug("  Shift:    " + shift);
        logger.debug("  Expected: " + expected + " (0x" + expected.format("%x") + ")");
        logger.debug("  Got:      " + result + " (0x" + result.format("%x") + ")");
        
        if (result != expected) {
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