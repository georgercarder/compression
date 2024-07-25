## Compression

VPL George R. Carder 2023

compress the shit out of a bytes array. in this case "shit" is "zeros".


basic benchmarking:
```
Ran 2 tests for test/LibCompression.t.sol:CounterTest
[PASS] test() (gas: 3734884)
Logs:
  1250695 compressed gas used
  2496 ignorantLength
  1673384 ignorantStorageGasUsed
  756 compressedLength
  554956 compressedStorageGasUsed
  236356 decompressed gas used

[PASS] test_newCompression() (gas: 3109671)
Logs:
  794679 compressed gas used
  2496 og length
  759 compressedLength
  2496 ignorantLength
  1673384 ignorantStorageGasUsed
  759 compressedLength
  554956 compressedStorageGasUsed
  64900 decompressed gas used
```

not audited. use at your own risk.

Support my work on this library by donating ETH or other coins to

`0x1331DA733F329F7918e38Bc13148832D146e5adE`

