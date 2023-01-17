// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.0;

library Compression {

    struct Segment {
        uint256 start;
        uint256 end;
    }

    uint256 constant FLAG_IS_NOT_COMPRESSED = 0x1;
    uint256 constant FLAG_IS_COMPRESSED = 0x2;

    uint256 constant FLAG_ZERO_MASK = 0x0f;
    uint256 constant FLAG_ZERO = 0x03;
    uint256 constant FLAG_NONZERO = 0x04;

    uint256 constant FLAG_LENGTH_MASK = 0xf0;
    uint256 constant FLAG_LENGTH_UINT8 = 0x10;
    uint256 constant FLAG_LENGTH_UINT16 = 0x20;
    uint256 constant FLAG_LENGTH_UINT32 = 0x30;
    uint256 constant FLAG_LENGTH_UINT64 = 0x40;

    // just compresses all zeros 
    function compressZeros(bytes memory input) internal view returns(bytes memory ret) {
        uint256 inputLength = input.length;
        ret = new bytes(inputLength*3); // overdo it
        uint256 retIdx;

        uint256 idx;

        // first find consecutive zeros
        
        uint256 _byte;
        bool inZeroSegment;
        Segment[] memory zeroSegments = new Segment[](inputLength);

        // collect all zero segments
        for (uint256 i; i < inputLength; ++i) {
            _byte = uint256(uint8(input[i]));

            if (_byte == 0) {
                if (!inZeroSegment) { // start of zero segment
                    zeroSegments[idx].start = i;
                    inZeroSegment = true;
                }
            } else {
                if (inZeroSegment) { // is end of zero segment
                    zeroSegments[idx].end = i;
                    inZeroSegment = false;
                    ++idx;
                }
            }
        }
        
        assembly {
            mstore(zeroSegments, idx)
        }

        // we now know all the zero segments
        Segment memory zs;
        uint256 start;
        uint256 end;
        uint256 length;

        for (uint256 i; i < idx; ++i) {
            zs = zeroSegments[i]; 
            end = zs.start;
            ret[retIdx] = bytes1(uint8(FLAG_NONZERO));
            length = end-start;

            retIdx = _setLength(ret, retIdx, length);
            for (uint256 j = start; j < end; ++j) {
                ret[retIdx++] = input[j];
            }
            start = zs.end;

            // zeros
            ret[retIdx] = bytes1(uint8(FLAG_ZERO));
            length = zs.end-zs.start;
            retIdx = _setLength(ret, retIdx, length);
        }
        
        ret[retIdx] = bytes1(uint8(FLAG_NONZERO));
        length = inputLength-zs.end;
        retIdx = _setLength(ret, retIdx, length);
        for (uint256 i = zs.end; i < inputLength; ++i) {
            ret[retIdx++] = input[i];
        }
        if (retIdx < input.length) { // compression was favorable
            ret[retIdx++] = bytes1(uint8(FLAG_IS_COMPRESSED));
            assembly {
                mstore(ret, retIdx)
            }
        } else { // compression was NOT an improvement
            ret = new bytes(inputLength+1);
            assembly {
                mstore(ret, 0)
            }
            _append(ret, input);
            assembly {
                mstore(ret, add(inputLength, 1))
            }
            ret[inputLength] = bytes1(uint8(FLAG_IS_NOT_COMPRESSED));
        }
    } 

    function decompressZeros(bytes memory input) internal pure returns(bytes memory ret) {
        // assumes input is output of `compressZeros`
        uint256 inputLength = input.length;
        require(inputLength > 0, "invalid input len.");
        uint256 isCompressed = uint256(uint8(input[inputLength-1]));
        assembly {
            mstore(input, sub(mload(input), 1))
        }
        if (isCompressed == FLAG_IS_NOT_COMPRESSED) return input;
        --inputLength;

        uint256 totalLength;
        uint256 length;
        uint256 idx;
        uint256 flag;
        
        while (idx < inputLength) {
            flag = uint256(uint8(input[idx])) & FLAG_ZERO_MASK;
            (length, idx) = _getLength(input, idx);
            if (length == 0) {
                continue;
            }
            totalLength += length; 
            if (flag == FLAG_NONZERO){
                idx += length;
            }
        }
        idx = 0;
        ret = new bytes(totalLength);
        uint256 retIdx;
        while (idx < inputLength) {
            flag = uint256(uint8(input[idx])) & FLAG_ZERO_MASK;
            (length, idx) = _getLength(input, idx);
            if (length == 0) {
                continue;
            }
            if (flag == FLAG_ZERO) {
                retIdx += length;
                continue;
            } else if (flag == FLAG_NONZERO){
                for (uint256 i; i < length; ++i) {
                    ret[retIdx++] = input[i+idx]; 
                }
                idx += length; 
            } else {
                revert("should not happen :("); // FIXME
            }
        }
    }
    
    function _setLength(bytes memory arr, uint256 arrIdx, uint256 length) private pure returns(uint256) {
        uint256 bound;
        if (length < type(uint8).max) {
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT8));
            bound = 1;
        } else if (length < type(uint16).max) {
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT16));
            bound = 2;
        } else if (length < type(uint32).max) { 
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT32));
            bound = 4;
        } else if (length < type(uint64).max) { 
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT64));
            bound = 8;
        } else {
            revert("_setLength:unsupportedLength");
        }
        for (uint256 i; i < bound; ++i) {
            arr[arrIdx++] = bytes1(uint8(length >> (8*i)));
        }
        return arrIdx;
    }

    function _getLength(bytes memory arr, uint256 arrIdx) private pure returns(uint256, uint256) {
        uint256 flagLength = uint256(uint8(arr[arrIdx++])) & FLAG_LENGTH_MASK; 
        uint256 bound;
        if (flagLength == FLAG_LENGTH_UINT8) {
            bound = 1;
        } else if (flagLength == FLAG_LENGTH_UINT16) {
            bound = 2;
        } else if (flagLength == FLAG_LENGTH_UINT32) { 
            bound = 4;
        } else if (flagLength == FLAG_LENGTH_UINT64) { 
            bound = 8;
        } else {
            revert("_getLength:unsupportedLength");
        }
        uint256 length;
        for (uint256 i; i < bound; ++i) {
            length |= uint256(uint8(arr[arrIdx++])) << (8*i);
        }
        return (length, arrIdx);
    }
    
    // cheaper than bytes concat :)
    function _append(bytes memory dst, bytes memory src) private view {
      
        assembly {
            // resize

            let priorLength := mload(dst)
            
            mstore(dst, add(priorLength, mload(src)))
        
            // copy    

            pop(
                staticcall(
                  gas(), 4, 
                  add(src, 32), // src data start
                  mload(src), // src length 
                  add(dst, add(32, priorLength)), // dst write ptr
                  mload(dst)
                ) 
            )
        }
    }
}
