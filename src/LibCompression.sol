// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "./LibPack.sol";
import "./Append.sol";

library LibCompression {
    uint256 constant FLAG_IS_NOT_COMPRESSED = 0x1;
    uint256 constant FLAG_IS_COMPRESSED = 0x2;

    uint256 constant TOLERANCE = 2;

    // just compresses all zeros
    function compressZeros(bytes memory input) internal pure returns (bytes memory ret) {
        uint256 inputLength = input.length;

        bool inZeroSegment;
        uint256 _byte;
        uint256 start;
        uint256 end;

        bytes memory nonzeroWand = new bytes(inputLength); // overshoot
        assembly {
            mstore(nonzeroWand, 0)
        }
        uint256 idxNonZeroWand;
        uint256[] memory nonzeroArr = new uint256[](2 * inputLength); // overshoot
        uint256 idxNonzeroArr;

        // collect all zero segments
        for (uint256 i; i <= inputLength; ++i) {
            if (i == input.length) {
                if (inZeroSegment) {
                    _appendSubstring(nonzeroWand, input, end, start);
                    nonzeroArr[idxNonzeroArr++] = end; // position of last nonzeroSegment
                    nonzeroArr[idxNonzeroArr++] = start; // position of end of last nonzeroSegment
                } else {
                    _appendSubstring(nonzeroWand, input, end, i - 1);
                    nonzeroArr[idxNonzeroArr++] = end; // position of last nonzeroSegment
                    nonzeroArr[idxNonzeroArr++] = i; // position of end lol
                }
                break;
            }
            _byte = uint256(uint8(input[i]));

            if (_byte == 0) {
                if (!inZeroSegment) {
                    // start of zero segment
                    start = i;
                    inZeroSegment = true;
                }
            } else {
                if ((inZeroSegment) && (i - start > TOLERANCE)) {
                    // is end of zero segment

                    nonzeroArr[idxNonzeroArr++] = end; // position of last nonzeroSegment
                    nonzeroArr[idxNonzeroArr++] = start; // position of end of last nonzeroSegment
                    _appendSubstring(nonzeroWand, input, end, start);
                    end = i;
                    inZeroSegment = false;
                    //++idx;
                } else if (inZeroSegment) {
                    inZeroSegment = false;
                }
            }
        }
        assembly {
            mstore(nonzeroArr, idxNonzeroArr)
        }
        bytes memory packed = LibPack.packUint256s(nonzeroArr);
        uint256[] memory packedLengthArr = new uint256[](2);
        packedLengthArr[0] = packed.length;
        packedLengthArr[1] = input.length;
        bytes memory packedLengthData = LibPack.packUint256s(packedLengthArr);
        ret = new bytes(1 + packedLengthData.length + packed.length + nonzeroWand.length);

        if (ret.length < inputLength) {
            // compression was favorable
            ret[ret.length - 1] = bytes1(uint8(FLAG_IS_COMPRESSED));
            assembly {
                mstore(ret, 0)
            }
            _append(ret, packedLengthData);
            _append(ret, packed);
            _append(ret, nonzeroWand);
            assembly {
                mstore(ret, add(mload(ret), 1)) // for flag
            }
        } else {
            // compression was NOT an improvement
            ret[inputLength] = bytes1(uint8(FLAG_IS_NOT_COMPRESSED));
            assembly {
                mstore(ret, 0)
            }
            _append(ret, input);
            assembly {
                mstore(ret, add(inputLength, 1)) // for flag
            }
        }
    }

    function decompressZeros(bytes memory input) internal pure returns (bytes memory ret) {
        // assumes input is output of `compressZeros`, as such there should be no overflows on this arithmetic

        uint256 inputLength = input.length;
        require(inputLength > 0, "invalid input len.");

        uint256 isCompressed = uint256(uint8(input[inputLength - 1]));
        if (isCompressed == FLAG_IS_NOT_COMPRESSED) {
            assembly {
                mstore(input, sub(inputLength, 1))
            }
            return input;
        }
        uint256 packedLength = LibPack.uint256At(input, 0);
        uint256 ogLength = LibPack.uint256At(input, 1);
        uint256 bound = uint256(uint8(input[0]));
        bytes memory packed = new bytes(packedLength);
        assembly {
            mstore(packed, 0)
        }
        unchecked {
            uint256 start = 1 + 2 * bound; // packedLength, numSignificantZeros
            _appendSubstring(packed, input, start, start + packedLength);
            uint256[] memory nonzeroArr = LibPack.unpackBytesIntoUint256s(packed);
            bytes memory nonzeroWand = new bytes(inputLength - (start + packedLength));
            assembly {
                mstore(nonzeroWand, 0)
            }
            _appendSubstring(nonzeroWand, input, (start + packedLength), input.length);

            ret = new bytes(ogLength);
            assembly {
                mstore(ret, 0)
            }
            uint256 end;

            uint256 idxNonzeroWand;
            for (uint256 i; i < nonzeroArr.length;) {
                start = nonzeroArr[i++];
                end = nonzeroArr[i++];
                if (end - start < 1) continue;
                assembly {
                    mstore(ret, start)
                }
                _appendSubstring(ret, nonzeroWand, idxNonzeroWand, idxNonzeroWand += (end - start));
            }
            assembly {
                mstore(ret, ogLength)
            }
        } // uc
    }
}
