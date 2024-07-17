// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "../src/Compression.sol";
import "../src/LibPack.sol";

contract LibPackTest is Test {
    function setUp() public {}

    function test_benchmark() public {
        uint256 arrLength = 100;
        uint256 bitsBound = 64;
        console.log("%d uint256[] arr length", arrLength);
        for (uint256 ii = 1; ii < bitsBound; ++ii) {
            uint256 maxBits = ii;
            console.log("%d maxBits", maxBits);
            uint256[] memory arr = new uint256[](arrLength);
            uint256 modulus;
            for (uint256 i; i < arr.length; ++i) {
                modulus = ((uint256(keccak256(abi.encode(i + 1))) % (2 ** maxBits)) + 1);
                //console.log(modulus);
                arr[i] = uint256(keccak256(abi.encode(i))) % modulus;
            }
            uint256 gasBefore = gasleft();
            bytes memory packed = LibPack.packUint256s(arr);
            console.log("%d pack gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            bytes memory compressed = Compression.compressZeros(packed);
            console.log("%d compressed gas used", gasBefore - gasleft());

            console.log("%d abi.encoded len", abi.encode(arr).length);
            console.log("%d packed len", packed.length);
            console.log("%d compressed len", compressed.length);

            gasBefore = gasleft();
            bytes memory decompressed = Compression.decompressZeros(compressed);
            console.log("%d decompressed gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            uint256[] memory unpacked = LibPack.unpackBytesIntoUint256s(decompressed);
            console.log("%d unpack gas used", gasBefore - gasleft());
            assertEq(unpacked.length, arr.length);
            for (uint256 i; i < unpacked.length; ++i) {
                //console.log(unpacked[i], arr[i]);
                assertEq(unpacked[i], arr[i]);
            }

            console.log("-----------------");
            console.log("bottom line tl;dr");
            console.log("-----------------");
            console.log("%d standard abi.encoded len", abi.encode(arr).length);
            console.log("%d packed and compressed len", compressed.length);
        }
    }
}
