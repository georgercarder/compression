// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "lib/solady/src/utils/LibBit.sol";

import "lib/solady/src/utils/LibZip.sol";

import "./Append.sol";

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

    function bytesAt(bytes memory input, uint256 idx) internal pure returns (bytes memory ret) {
        uint256 packedPositionsLength = uint256At(input, 0);
        if (packedPositionsLength < 1) revert InvalidInput_error();
        uint256 bound = uint256(uint8(input[0]));
        uint256 scratch = 1 + bound;
        uint256 start = scratch;
        bytes memory packedPositions = new bytes(packedPositionsLength);
        assembly {
            mstore(packedPositions, 0)
        }
        _appendSubstring(packedPositions, input, start, start + packedPositionsLength);
        uint256[] memory positions = unpackBytesIntoUint256s(packedPositions);

        uint256 position = positions[idx];
        uint256 end;
        start += position;
        if (idx == positions.length - 1) {
            end = input.length;
        } else {
            end = scratch + positions[idx + 1];
        }
        ret = new bytes(end - start);
        assembly {
            mstore(ret, 0)
        }
        _appendSubstring(ret, input, start, end);
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

    function packInt256s(int256[] memory arr) internal pure returns (bytes memory ret) {
        uint256 length = arr.length;
        uint256 polarityRodLength = (length / 256 + 1);
        uint256[] memory pr = new uint256[](polarityRodLength);
        uint256[] memory us = new uint256[](length);
        bool negative;
        uint256 n;
        for (uint256 i; i < arr.length; ++i) {
            (negative, n) = decomposeZ(arr[i]);
            us[i] = n;
            if (negative) {
                pr[i / 256] |= 1 << (i % 256);
            }
        }
        bytes[] memory bs = new bytes[](2);
        bs[0] = packUint256s(pr);
        bs[1] = packUint256s(us);
        ret = packBytesArrs(bs);
    }

    function int256At(bytes memory packed, uint256 idx) internal pure returns (int256 ret) {
        bytes[] memory bs = unpackBytesIntoBytesArrs(packed);
        if (bs.length != 2) revert InvalidInput_error();
        uint256[] memory pr = unpackBytesIntoUint256s(bs[0]);
        uint256[] memory us = unpackBytesIntoUint256s(bs[1]);
        if (!(idx < us.length) || !(idx / 256 < pr.length)) revert InvalidInput_error();
        ret = int256(us[idx]);
        if ((pr[idx / 256] >> (idx % 256)) & 0x1 == 0x1) {
            ret *= -1;
        }
    }

    function unpackBytesIntoInt256s(bytes memory packed) internal pure returns (int256[] memory ret) {
        bytes[] memory bs = unpackBytesIntoBytesArrs(packed);
        if (bs.length != 2) revert InvalidInput_error();
        uint256[] memory pr = unpackBytesIntoUint256s(bs[0]);
        uint256[] memory us = unpackBytesIntoUint256s(bs[1]);
        uint256 length = us.length;
        ret = new int256[](length);
        for (uint256 i; i < length; ++i) {
            ret[i] = int256(us[i]);
            if ((pr[i / 256] >> (i % 256)) & 0x1 == 0x1) {
                ret[i] *= -1;
            }
        }
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
}
