// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "../src/LibCompression.sol";
import "../src/LibPack.sol";

contract LibPackTest is Test {
    uint256 arrLength = 100;

    function setUp() public {}

    function test_uint256s() public {
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

            /*
            console.log("--");
            for (uint256 i; i < packed.length; ++i) {
                console.log(uint256(uint8(packed[i]))); 
            }
            console.log("--");
            */

            gasBefore = gasleft();
            bytes memory compressed = LibCompression.compressZeros(packed);
            /*/
            console.log(uint256(keccak256(packed)));
            console.log(packed.length);
            */
            console.log("%d compressed gas used", gasBefore - gasleft());

            console.log("%d abi.encoded len", abi.encode(arr).length);
            console.log("%d packed len", packed.length);
            console.log("%d compressed len", compressed.length);
            console.log("note: compressed only good when lots of zeros");

            gasBefore = gasleft();
            bytes memory decompressed = LibCompression.decompressZeros(compressed);
            /*
            console.log(uint256(keccak256(decompressed)));
            console.log(decompressed.length);
            */
            console.log("%d decompressed gas used", gasBefore - gasleft());

            /*
            console.log("..");
            for (uint256 i; i < decompressed.length; ++i) {
                console.log(uint256(uint8(decompressed[i]))); 
            }
            console.log("..");
            */

            gasBefore = gasleft();
            uint256[] memory unpacked = LibPack.unpackBytesIntoUint256s(decompressed);
            console.log("%d unpack gas used", gasBefore - gasleft());
            assertEq(unpacked.length, arr.length);
            for (uint256 i; i < unpacked.length; ++i) {
                //console.log(unpacked[i], arr[i]);
                assertEq(unpacked[i], arr[i]);
                assertEq(LibPack.uint256At(packed, i), arr[i]);
            }

            console.log("-----------------");
            console.log("bottom line tl;dr");
            console.log("-----------------");
            console.log("%d standard abi.encoded len", abi.encode(arr).length);
            console.log("%d packed and compressed len", compressed.length);
        }
    }

    function test_ints() public {
        uint256 bitsBound = 10;
        console.log("%d int256[] arr length", arrLength);
        for (uint256 ii = 1; ii < bitsBound; ++ii) {
            uint256 maxBits = ii;
            console.log("%d maxBits", maxBits);
            int256[] memory arr = new int256[](arrLength);
            uint256 modulus;
            for (uint256 i; i < arr.length; ++i) {
                modulus = ((uint256(keccak256(abi.encode(i + 1))) % (2 ** maxBits)) + 1);
                //console.log(modulus);
                arr[i] = int256(uint256(keccak256(abi.encode(i))) % modulus);
                if (modulus % 2 == 0) arr[i] *= -1;
            }
            uint256 gasBefore = gasleft();
            bytes memory packed = LibPack.packInt256s(arr);
            console.log("%d pack gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            bytes memory compressed = LibCompression.compressZeros(packed);
            console.log("%d compressed gas used", gasBefore - gasleft());

            console.log("%d abi.encoded len", abi.encode(arr).length);
            console.log("%d packed len", packed.length);
            console.log("%d compressed len", compressed.length);

            gasBefore = gasleft();
            bytes memory decompressed = LibCompression.decompressZeros(compressed);
            console.log("%d decompressed gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            int256[] memory unpacked = LibPack.unpackBytesIntoInt256s(decompressed);
            console.log("%d unpack gas used", gasBefore - gasleft());
            assertEq(unpacked.length, arr.length);
            for (uint256 i; i < unpacked.length; ++i) {
                assertEq(
                    keccak256(bytes(Strings.toStringSigned(unpacked[i]))),
                    keccak256(bytes(Strings.toStringSigned(arr[i])))
                );
                assertEq(
                    keccak256(bytes(Strings.toStringSigned(LibPack.int256At(packed, i)))),
                    keccak256(bytes(Strings.toStringSigned(arr[i])))
                );
            }

            console.log("-----------------");
            console.log("bottom line tl;dr");
            console.log("-----------------");
            console.log("%d standard abi.encoded len", abi.encode(arr).length);
            console.log("%d packed and compressed len", compressed.length);
        }
    }

    function test_addresses() public {
        //uint256 arrLength = 10;
        address[] memory arr = new address[](arrLength);
        uint256 modulus;
        for (uint256 i; i < arr.length; ++i) {
            arr[i] = address(uint160(uint256(keccak256(abi.encode(i)))));
        }
        uint256 gasBefore = gasleft();
        bytes memory packed = LibPack.packAddresses(arr);
        console.log("%d pack gas used", gasBefore - gasleft());

        gasBefore = gasleft();
        bytes memory compressed = LibCompression.compressZeros(packed);
        console.log("%d compressed gas used", gasBefore - gasleft());

        console.log("%d abi.encoded len", abi.encode(arr).length);
        console.log("%d packed len", packed.length);
        console.log("%d compressed len", compressed.length);

        gasBefore = gasleft();
        bytes memory decompressed = LibCompression.decompressZeros(compressed);
        console.log("%d decompressed gas used", gasBefore - gasleft());

        gasBefore = gasleft();
        address[] memory unpacked = LibPack.unpackBytesIntoAddresses(decompressed);
        console.log("%d unpack gas used", gasBefore - gasleft());
        assertEq(unpacked.length, arr.length);
        for (uint256 i; i < unpacked.length; ++i) {
            //console.log(unpacked[i], arr[i]);
            assertEq(unpacked[i], arr[i]);
            //console.log(LibPack.addressAt(packed, i));
            assertEq(LibPack.addressAt(packed, i), arr[i]);
        }

        console.log("-----------------");
        console.log("bottom line tl;dr");
        console.log("-----------------");
        console.log("%d standard abi.encoded len", abi.encode(arr).length);
        console.log("%d packed and compressed len", compressed.length);
    }

    function test_benchmarkAt() public {
        //uint256 arrLength = 10;
        uint256 bitsBound = 10;
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
            bytes memory encoded = abi.encode(arr);
            console.log("%d encode (ignorant) gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            bytes memory packed = LibPack.packUint256s(arr);
            console.log("%d pack gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            uint256[] memory decoded = abi.decode(encoded, (uint256[]));
            uint256 _at = decoded[3];
            console.log("%d decode at (ignorant) gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            uint256[] memory _decoded = LibPack.unpackBytesIntoUint256s(packed);
            console.log("%d unpacked gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            uint256 __at = LibPack.uint256At(packed, 3);
            console.log("%d libpack at gas used", gasBefore - gasleft());

            assertEq(__at, _at);
        }
    }

    function test_benchmarkAt_Int() public {
        //uint256 arrLength = 10;
        uint256 bitsBound = 10;
        for (uint256 ii = 1; ii < bitsBound; ++ii) {
            uint256 maxBits = ii;
            console.log("%d maxBits", maxBits);
            int256[] memory arr = new int256[](arrLength);
            uint256 modulus;
            for (uint256 i; i < arr.length; ++i) {
                modulus = ((uint256(keccak256(abi.encode(i + 1))) % (2 ** maxBits)) + 1);
                //console.log(modulus);
                arr[i] = int256(uint256(keccak256(abi.encode(i))) % modulus);
                if (modulus % 2 == 0) arr[i] *= -1;
            }
            uint256 gasBefore = gasleft();
            bytes memory encoded = abi.encode(arr);
            console.log("%d encode (ignorant) gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            bytes memory packed = LibPack.packInt256s(arr);
            console.log("%d pack gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            int256[] memory decoded = abi.decode(encoded, (int256[]));
            int256 _at = decoded[3];
            console.log("%d decode at (ignorant) gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            int256[] memory _decoded = LibPack.unpackBytesIntoInt256s(packed);
            console.log("%d unpacked gas used", gasBefore - gasleft());

            gasBefore = gasleft();
            int256 __at = LibPack.int256At(packed, 3);
            console.log("%d libpack at gas used", gasBefore - gasleft());

            assertEq(__at, _at);
        }
    }

    function getLyrics() public returns (string[] memory lyrics) {
        lyrics = new string[](24);
        lyrics[0] = "[Instrumental Intro]";
        lyrics[1] = "";
        lyrics[2] = "[Riff]";
        lyrics[3] = "";
        lyrics[4] = "[Verse 1]";
        lyrics[5] = "What is this that stands before me?";
        lyrics[6] = "Figure in black which points at me";
        lyrics[7] = "Turn 'round quick and start to run";
        lyrics[8] = "Find out I'm the chosen one";
        lyrics[9] = "Oh, no!";
        lyrics[10] = "";
        lyrics[11] = "[Verse 2]";
        lyrics[12] = "Big black shape with eyes of fire";
        lyrics[13] = "Tellin' people their desire";
        lyrics[14] = "Satan's sittin' there, he's smilin'";
        lyrics[15] = "Watches those flames get higher and higher";
        lyrics[16] = "Oh, no! No! Please, God, help me!";
        lyrics[17] = "";
        lyrics[18] = "[Outro]";
        lyrics[19] = "Is it the end, my friend?";
        lyrics[20] = "Satan's comin' 'round the bend";
        lyrics[21] = "People runnin' 'cause they're scared";
        lyrics[22] = "The people better go and beware";
        lyrics[23] = "No! No! Please, no!";
    }

    function test_packBytes() public {
        string[] memory lyrics = getLyrics();
        bytes[] memory bLyrics;
        assembly {
            bLyrics := lyrics
        }

        bytes memory ignorantPacked = abi.encode(lyrics);
        console.log("%d ignorant encoded len", ignorantPacked.length);
        uint256 gasBefore = gasleft();
        bytes[] memory ignorantUnpacked = abi.decode(ignorantPacked, (bytes[]));
        console.log("%d ignorant decode gas used", gasBefore - gasleft());

        bytes memory packed = LibPack.packBytesArrs(bLyrics);
        console.log("%d packed.length", packed.length);

        gasBefore = gasleft();
        bytes[] memory unpacked = LibPack.unpackBytesIntoBytesArrs(packed);
        console.log("%d unpack gas used", gasBefore - gasleft());
        for (uint256 i; i < lyrics.length; ++i) {
            assertEq(keccak256(unpacked[i]), keccak256(bytes(lyrics[i])));
        }
    }
}
