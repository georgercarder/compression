// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

// cheaper than bytes concat :)
function _append(bytes memory dst, bytes memory src) pure {
    assembly {
        // resize

        let priorLength := mload(dst)

        mstore(dst, add(priorLength, mload(src)))

        // copy
        mcopy(add(dst, add(0x20, priorLength)), add(src, 0x20), mload(src))
    }
}

// assumes dev is not stupid and startIdx < endIdx
function _appendSubstring(bytes memory dst, bytes memory src, uint256 startIdx, uint256 endIdx) pure {
    assembly {
        // resize

        let priorLength := mload(dst)
        let substringLength := sub(endIdx, startIdx)
        mstore(dst, add(priorLength, substringLength))

        // copy
        mcopy(add(dst, add(0x20, priorLength)), add(src, add(0x20, startIdx)), substringLength)
    }
}
