## Notes

```sh
python3 wapy_parse.py wamc/test/addTwo.wasm --generate-monkeyc

python wapy.py test/addTwo.wasm addTwo 1 2 &> wapy-addTwo,1,2.log


python wapy_parse.py wamc/test/rocket.wasm --generate-monkeyc
python rocket.py &> rocket-py.log
python trim_log.py rocket-mc.log rocket-py.log "Running function 'resize'"
```

## Todo
- [x] Basic classes
- [x] Generate MonkeyC factory from .wasm with modified warpy
- [x] Port enough to run `addTwo.wat`
- [x] Run `fizzbuzz.wat` on real device
- [ ] Run `rocket.wasm` on emulator from https://gist.github.com/dabeaz/7d8838b54dba5006c58a40fc28da9d5a 
- [ ] .wast tests
- [ ] ...