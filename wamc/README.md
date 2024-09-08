## Notes

```sh
python3 wapy_parse.py wamc/test/addTwo.wasm --generate-monkeyc

python wapy.py test/addTwo.wasm addTwo 1 2 &> wapy-addTwo,1,2.log

python wapy.py wamc/test/fizzbuzz.wasm &> wapy-fizzbuzz.log
```

## Todo
- [x] Basic classes
- [x] Generate MonkeyC factory from .wasm with modified warpy
- [x] Port enough to run `addTwo.wat`
- [x] Run `fizzbuzz.wat` on real device
- [ ] .wast tests
- [ ] ...