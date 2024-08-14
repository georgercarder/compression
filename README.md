## Compression

VPL George R. Carder 2023

Library starting with LibCompression but now contains other utilities including:

- `LibCompression.sol`
- `LibDynamicBuffer.sol`
- `LibEncryption.sol`
- `LibPack.sol`


this repo started with the statment:

`compress the shit out of a bytes array. in this case "shit" is "zeros".`


basic benchmarking:
```
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

