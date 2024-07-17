// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "lib/solady/src/utils/LibBit.sol";

library LibPack {
    error InvalidInput_error();

    function packUint256s(uint256[] memory arr) internal pure returns (bytes memory ret) {
        uint256 maxIdxMSB; // idx most significant bit
        uint256 idxMSB;
        unchecked {
            for (uint256 i; i < arr.length; ++i) {
                idxMSB = LibBit.fls(arr[i]);
                if (idxMSB > maxIdxMSB) maxIdxMSB = idxMSB;
            }
            uint256 bound = maxIdxMSB / 8 + 1;
            ret = new bytes(arr.length * bound + 1);
            uint256 retIdx;
            ret[retIdx++] = bytes1(uint8(bound));
            uint256 n;
            for (uint256 i; i < arr.length; ++i) {
                n = arr[i];
                for (uint256 j; j < bound; ++j) {
                    ret[retIdx++] = bytes1(uint8(n >> (8 * j)));
                }
            }
        } // uc
    }

    function unpackBytesIntoUint256s(bytes memory packed) internal pure returns (uint256[] memory ret) {
        uint256 idx;
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            uint256 bound = uint256(uint8(packed[idx++]));
            ret = new uint256[]((packed.length - 1) / bound);
            if (packed.length < ret.length * bound) revert InvalidInput_error();
            uint256 n;
            for (uint256 i; i < ret.length; ++i) {
                n = 0;
                for (uint256 j; j < bound; ++j) {
                    n |= (uint256(uint8(packed[idx++])) << 8 * j);
                }
                ret[i] = n;
            }
        } // uc
    }
}
