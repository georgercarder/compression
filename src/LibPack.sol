// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "lib/solady/src/utils/LibBit.sol";

library LibPack {
    error InvalidInput_error();

    function packBytesArrs(bytes[] memory arrs) internal pure returns (bytes memory ret) {
        uint256[] memory positions = new uint256[](arrs.length);
        uint256 position;
        for (uint256 i; i < positions.length; ++i) {
            positions[i] = position;
            position += arrs[i].length;
        }
        bytes memory packedPositions = packUint256s(positions);
        uint256[] memory lengthPacked = new uint256[](1);
        lengthPacked[0] = packedPositions.length;
        bytes memory packedLengthPacked = packUint256s(lengthPacked);
        ret = new bytes(packedLengthPacked.length + packedPositions.length + position + arrs[arrs.length - 1].length);
        assembly {
            mstore(ret, 0)
        }
        _append(ret, packedLengthPacked);
        _append(ret, packedPositions);
        for (uint256 i; i < arrs.length; ++i) {
            _append(ret, arrs[i]);
        }
    }

    function unpackBytesIntoBytesArrs(bytes memory input) internal pure returns (bytes[] memory ret) {
        // assumes input is from pack function and thus is well-formed.. meaning overflows are not an issue
        unchecked {
            uint256 packedPositionsLength = uint256At(input, 0);
            uint256 bound = uint256(uint8(input[0]));
            uint256 scratch = 1 + bound;
            uint256 start = scratch;
            bytes memory packedPositions = new bytes(packedPositionsLength);
            assembly {
                mstore(packedPositions, 0)
            }
            _appendSubstring(packedPositions, input, start, start + packedPositionsLength);
            uint256[] memory positions = unpackBytesIntoUint256s(packedPositions);

            ret = new bytes[](positions.length);
            scratch += packedPositionsLength;
            start = scratch;
            uint256 position;
            uint256 end;
            for (uint256 i; i < positions.length; ++i) {
                position = positions[i];
                start += position;
                if (i == positions.length - 1) {
                    end = input.length;
                } else {
                    end = scratch + positions[i + 1];
                }
                bytes memory _ret = new bytes(end - start);
                assembly {
                    mstore(_ret, 0)
                }
                _appendSubstring(_ret, input, start, end);
                ret[i] = _ret;

                // reset start
                start = scratch;
            }
        } //uc
    }

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

    function uint256At(bytes memory packed, uint256 idx) internal pure returns (uint256 ret) {
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            uint256 bound = uint256(uint8(packed[0]));
            idx = idx * bound + 1;
            for (uint256 j; j < bound; ++j) {
                ret |= (uint256(uint8(packed[idx++])) << (8 * j));
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

    function int256At(bytes memory packed, uint256 idx) internal pure returns (int256 ret) {
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            uint256 bound = uint256(uint8(packed[0]));
            uint256 polarityRodLength = uint256(uint8(packed[1]));
            ret = -(2 * int256((uint256(uint8(packed[3 + idx / 8])) >> (idx % 8)) & 0x01) - 1);
            // (0, 1) -> (0, 2) -> (-1, 1) -> (1, -1)
            idx = idx * bound + 2;
            uint256 n;
            for (uint256 j; j < bound; ++j) {
                n |= (uint256(uint8(packed[polarityRodLength + 1 + idx + j])) << (8 * j));
            }
            ret *= int256(n);
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
                ret[i] = int256(n);
                if ((uint256(uint8(packed[3 + i / 8])) >> (i % 8)) & 0x01 == 1) {
                    ret[i] *= -1;
                }
            }
        } // uc
    }

    function packAddresses(address[] memory arr) internal pure returns (bytes memory ret) {
        uint256 bound = 20;
        ret = new bytes(arr.length * bound);
        uint256 retIdx;
        uint256 n;
        for (uint256 i; i < arr.length; ++i) {
            n = uint256(uint160(arr[i]));
            for (uint256 j; j < bound; ++j) {
                ret[retIdx++] = bytes1(uint8(n >> (8 * j)));
            }
        }
    }

    function addressAt(bytes memory packed, uint256 idx) internal pure returns (address ret) {
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            idx = idx * 20; // no +1 since know bound
            uint256 n;
            for (uint256 j; j < 20; ++j) {
                n |= (uint256(uint8(packed[idx++])) << (8 * j));
            }
            ret = address(uint160(n));
        } // uc
    }

    function unpackBytesIntoAddresses(bytes memory packed) internal pure returns (address[] memory ret) {
        uint256 idx;
        if (packed.length < 1) revert InvalidInput_error();
        unchecked {
            ret = new address[](packed.length / 20); // no +1 since know bound
            if (packed.length < ret.length * 20) revert InvalidInput_error();
            uint256 n;
            for (uint256 i; i < ret.length; ++i) {
                n = 0;
                for (uint256 j; j < 20; ++j) {
                    n |= (uint256(uint8(packed[idx++])) << (8 * j));
                }
                ret[i] = address(uint160(n));
            }
        } // uc
    }

    // cheaper than bytes concat :)
    function _append(bytes memory dst, bytes memory src) private pure {
        assembly {
            // resize

            let priorLength := mload(dst)

            mstore(dst, add(priorLength, mload(src)))

            // copy
            mcopy(add(dst, add(0x20, priorLength)), add(src, 0x20), mload(src))
        }
    }

    // assumes dev is not stupid and startIdx < endIdx
    function _appendSubstring(bytes memory dst, bytes memory src, uint256 startIdx, uint256 endIdx) private pure {
        assembly {
            // resize

            let priorLength := mload(dst)
            let substringLength := sub(endIdx, startIdx)
            mstore(dst, add(priorLength, substringLength))

            // copy
            mcopy(add(dst, add(0x20, priorLength)), add(src, add(0x20, startIdx)), substringLength)
        }
    }
}
