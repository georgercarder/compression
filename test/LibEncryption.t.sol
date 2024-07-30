// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "../src/LibEncryption.sol";

contract LibEncryptionTest is Test {
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

    function test_flow() public {
        string[] memory lyrics = getLyrics();
        string memory str;
        for (uint256 i; i < lyrics.length; ++i) {
            str = string(bytes.concat(bytes(str), bytes(lyrics[i])));
        }
        //console.log(str);
        console.log(bytes(str).length);

        bytes32 key = keccak256("secret key");
        bytes32 nonce = keccak256("nonce");

        bytes memory encrypted = LibEncryption.xorEncrypt(key, nonce, bytes(str));

        assertEq(uint256(keccak256(encrypted)) != uint256(keccak256(bytes(str))), true);

        //console.log(string(encrypted));
        console.log(encrypted.length);

        console.log("--");

        uint256 gasBefore = gasleft();
        bytes memory decrypted = LibEncryption.xorDecrypt(key, encrypted);
        console.log("%d gas used decrypt", gasBefore - gasleft());
        assertEq(bytes(str).length > 0, true); // just checking for trivialities.. sanity
        //console.log(string(decrypted));
        console.log("%d og len", bytes(str).length);
        console.log("%d decrypted len", decrypted.length);
        assertEq(keccak256(decrypted), keccak256(bytes(str)));
    }
}
