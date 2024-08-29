## Notes

```sh
python3 wapy_parse.py wamc/test/addTwo.wasm --generate-monkeyc

python wapy.py test/addTwo.wasm addTwo 1 2 &> wapy-addTwo,1,2.log
```

## Todo
- [x] Basic classes
- [ ] Generate MonkeyC factory from .wasm with modified warpy
- [ ] Port enough to run `addTwo.wat`
- [ ] Port more to run tests
- [ ] ...