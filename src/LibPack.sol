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
                if (idxMSB == 256) continue;
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
                    n |= (uint256(uint8(packed[idx++])) << (8 * j));
                }
                ret[i] = n;
            }
        } // uc
    }

    function decomposeZ(int256 z) internal pure returns (bool negative, uint256 n) {
        if (z < int256(0)) return (true, uint256(-z));
        return (false, uint256(z));
    }

    // 2032 = 254*8 len array is max capacity lol
    function packInt256s(int256[] memory arr) internal pure returns (bytes memory ret) {
        uint256 maxIdxMSB; // idx most significant bit
        uint256 idxMSB;
        uint256 n;
        bool negative;
        uint256 polarityRodLength = (arr.length / 8 + 1);
        if (polarityRodLength > 255) revert("cannot support array of this size");
        unchecked {
            for (uint256 i; i < arr.length; ++i) {
                (, n) = decomposeZ(arr[i]);
                idxMSB = LibBit.fls(n);
                if (idxMSB == 256) continue;
                if (idxMSB > maxIdxMSB) maxIdxMSB = idxMSB;
            }
            uint256 bound = maxIdxMSB / 8 + 1;
            ret = new bytes(arr.length * bound + 3 + polarityRodLength); // +1 for "len" of polarity rod + polarity rod length
            //ret = new bytes(arr.length * bound + 1);
            uint256 retIdx;
            ret[retIdx++] = bytes1(uint8(bound));
            ret[retIdx++] = bytes1(uint8(polarityRodLength));
            for (uint256 i; i < arr.length; ++i) {
                (negative, n) = decomposeZ(arr[i]);
                if (negative) {
                    // 2 + i/8 + 1
                    ret[3 + i / 8] = bytes1(uint8(ret[3 + i / 8]) | uint8(1 << (i % 8)));
                }
                for (uint256 j; j < bound; ++j) {
                    ret[polarityRodLength + 1 + retIdx++] = bytes1(uint8(n >> (8 * j)));
                }
            }
        } // uc
    }

    function unpackBytesIntoInt256s(bytes memory packed) internal pure returns (int256[] memory ret) {
        uint256 idx;
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            uint256 bound = uint256(uint8(packed[idx++]));
            uint256 polarityRodLength = uint256(uint8(packed[idx++]));
            ret = new int256[]((packed.length - 3 - polarityRodLength) / bound);
            if (packed.length < ret.length * bound) revert InvalidInput_error();
            uint256 n;
            for (uint256 i; i < ret.length; ++i) {
                n = 0;
                for (uint256 j; j < bound; ++j) {
                    n |= (uint256(uint8(packed[polarityRodLength + 1 + idx++])) << (8 * j));
                }
                ret[i] = int256(n); // TODO moar
                if ((uint256(uint8(packed[3 + i / 8])) >> (i % 8)) & 0x01 == 1) {
                    ret[i] *= -1;
                }
            }
        } // uc
    }
}
