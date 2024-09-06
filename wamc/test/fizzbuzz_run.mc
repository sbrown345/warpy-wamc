
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class Wamc_test_fizzbuzz_run {
    (:test)
    static function test_fizzbuzz(logger as Test.Logger) as Boolean {
        var m = Wamc_test_fizzbuzz.createModule();
        var run_args = [];
        var result = m.runStartFunction();
        System.println("result = " + result);
        System.println("host_output = " + host_output);
        return host_output.equals("fizzbuzz\n" +
"0000000001\n" +
"0000000002\n" +
"fizz\n" +
"0000000004\n" +
"buzz\n" +
"fizz\n" +
"0000000007\n" +
"0000000008\n" +
"fizz\n" +
"buzz\n" +
"0000000011\n" +
"fizz\n" +
"0000000013\n" +
"0000000014\n" +
"fizzbuzz\n" +
"0000000016\n" +
"0000000017\n" +
"fizz\n" +
"0000000019\n" +
"buzz\n" +
"fizz\n" +
"0000000022\n" +
"0000000023\n" +
"fizz\n" +
"buzz\n" +
"0000000026\n" +
"fizz\n" +
"0000000028\n" +
"0000000029\n" +
"fizzbuzz\n" +
"0000000031\n" +
"0000000032\n" +
"fizz\n" +
"0000000034\n" +
"buzz\n" +
"fizz\n" +
"0000000037\n" +
"0000000038\n" +
"fizz\n" +
"buzz\n" +
"0000000041\n" +
"fizz\n" +
"0000000043\n" +
"0000000044\n" +
"fizzbuzz\n" +
"0000000046\n" +
"0000000047\n" +
"fizz\n" +
"0000000049\n" +
"buzz\n" +
"fizz\n" +
"0000000052\n" +
"0000000053\n" +
"fizz\n" +
"buzz\n" +
"0000000056\n" +
"fizz\n" +
"0000000058\n" +
"0000000059\n" +
"fizzbuzz\n" +
"0000000061\n" +
"0000000062\n" +
"fizz\n" +
"0000000064\n" +
"buzz\n" +
"fizz\n" +
"0000000067\n" +
"0000000068\n" +
"fizz\n" +
"buzz\n" +
"0000000071\n" +
"fizz\n" +
"0000000073\n" +
"0000000074\n" +
"fizzbuzz\n" +
"0000000076\n" +
"0000000077\n" +
"fizz\n" +
"0000000079\n" +
"buzz\n" +
"fizz\n" +
"0000000082\n" +
"0000000083\n" +
"fizz\n" +
"buzz\n" +
"0000000086\n" +
"fizz\n" +
"0000000088\n" +
"0000000089\n" +
"fizzbuzz\n" +
"0000000091\n" +
"0000000092\n" +
"fizz\n" +
"0000000094\n" +
"buzz\n" +
"fizz\n" +
"0000000097\n" +
"0000000098\n" +
"fizz\n");
    }
}