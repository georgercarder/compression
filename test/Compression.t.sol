// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Compression.sol";

contract CounterTest is Test {
    bytes public wall0;
    bytes public wall1;

    function setUp() public {}

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

    function test() public {
        string[] memory lyrics = getLyrics();

        bytes memory ignorant = abi.encode(lyrics);
        uint256 ignorantLength = ignorant.length;
        uint256 gasBefore = gasleft();
        wall0 = ignorant;
        uint256 ignorantStorageGasUsed = gasBefore - gasleft();

        bytes memory compressed = Compression.compressZeros(ignorant);
        uint256 compressedLength = compressed.length;
        gasBefore = gasleft();
        wall1 = compressed;
        uint256 compressedStorageGasUsed = gasBefore - gasleft();

        console.log("%d ignorantLength", ignorantLength);
        console.log("%d ignorantStorageGasUsed", ignorantStorageGasUsed);

        console.log("%d compressedLength", compressedLength);
        console.log("%d compressedStorageGasUsed", compressedStorageGasUsed);

        bytes memory decompressed = Compression.decompressZeros(compressed);
        assertEq(keccak256(decompressed), keccak256(ignorant));
    }
}
