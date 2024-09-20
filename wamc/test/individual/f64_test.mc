// import Toybox.Lang;
// import Toybox.Math;
// import Toybox.System;
// import Toybox.Test;


// // function write_and_read_F64(bytes as ByteArray, pos as Number, fval as Double) as Void {
// //     // Write the double value
// //     var bits = doubleToBits(fval);
// //     var low = (bits & 0xFFFFFFFF).toNumber();
// //     var high = ((bits >> 32) & 0xFFFFFFFF).toNumber();

// //     bytes.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, { :offset => pos, :endianness => Lang.ENDIAN_LITTLE });
// //     bytes.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, { :offset => pos + 4, :endianness => Lang.ENDIAN_LITTLE });

// //     // Log the bytes written
// //     System.println("Bytes written:");
// //     for (var i = 0; i < 8; i++) {
// //         System.print(bytes[pos + i].format("%02X") + " ");
// //     }
// //     System.println("");

// //     var long_value = read_I64(bytes, pos);
// //     var result = bitsToDouble(long_value);

// //     // Log results
// //     System.println("Original value: " + fval + " isNaN:" + isNaN(fval) + " isInfinite:" + isInfinite(fval));
// //     System.println("Method (long bitwise): " + result + " isNaN:" + isNaN(result) + " isInfinite:" + isInfinite(result));
// //     System.println("Absolute errors:");
// //     System.println("Method: " + (isNaN(result) || isInfinite(result) || isNaN(fval) || isInfinite(fval) ? "N/A" : (result - fval).abs()));
// // }


// function test_write_and_read_F64(bytes as ByteArray, pos as Number, fval as Double) as Void {
//     // Write the double value
//     write_F64(bytes, pos, fval);

//     // Log the bytes written
//     System.println("Bytes written:");
//     for (var i = 0; i < 8; i++) {
//         System.print(bytes[pos + i].format("%02X") + " ");
//     }
//     System.println("");

//     // Read the double value
//     var result = read_F64(bytes, pos);

//     // Log results
//     System.println("Original value: " + fval + " isNaN:" + isNaN(fval) + " isInfinite:" + isInfinite(fval));
//     System.println("Read value: " + result + " isNaN:" + isNaN(result) + " isInfinite:" + isInfinite(result));
//     System.println("Absolute error: " + (isNaN(result) || isInfinite(result) || isNaN(fval) || isInfinite(fval) ? "N/A" : (result - fval).abs()));
// }

// class Wamc_test_double_conversions {

//     (:test)
//     static function testWriteAndReadF64(logger as Test.Logger) as Boolean {
//         var testBytes = new [8]b;
//         var testCases = [
//             // Normal numbers
//             3.14159265358979323846,
//             -2.71828182845904523536,
//             1.41421356237309504880,
            
//             // Integer values
//             0.0,
//             1.0,
//             -1.0,
//             42.0,
//             // Very small numbers
//             1.0e-20,
//             -1.0e-20,
            
//             // Special values
//             createPositiveInfinity(),
//             createNegativeInfinity(),
//             createNaN()
            
//             // // Subnormal numbers (if supported)
//             // 4.9e-324,  // Smallest positive subnormal double
//             // -4.9e-324, // Smallest negative subnormal double
            
//             // // Edge cases
//             // Float.MAX,
//             // -Float.MAX,
//             // Float.MIN,
//             // -Float.MIN
//         ];
        
//         for (var i = 0; i < testCases.size(); i++) {
//             var testValue = testCases[i];
//             System.println("\nTest case " + (i + 1) + ": " + testValue);
//             test_write_and_read_F64(testBytes, 0, testValue);
//         }
//     }
// }