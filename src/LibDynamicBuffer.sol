// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "./Append.sol";

library LibDynamicBuffer {
    struct DynamicBuffer {
        bytes processed;
        uint256 aggregateIdx;
        LinkedBuffer linkedBufferStart;
        LinkedBuffer linkedBufferEnd;
    }

    struct LinkedBuffer {
        bytes buffer;
        LinkedBuffer[] next;
    }

    function newDynamicBuffer() internal pure returns (DynamicBuffer memory ret) {
        LinkedBuffer memory first;
        ret = DynamicBuffer({processed: bytes(""), aggregateIdx: 0, linkedBufferStart: first, linkedBufferEnd: first});
    }

    function getBuffer(DynamicBuffer memory db) internal pure returns (bytes memory) {
        _update(db);
        return db.processed;
    }

    function p(DynamicBuffer memory db, bytes memory data) internal pure {
        unchecked {
            db.aggregateIdx += data.length;
            LinkedBuffer[] memory next = new LinkedBuffer[](1);
            next[0].buffer = data;
            db.linkedBufferEnd.next = next;
            db.linkedBufferEnd = next[0];
        } // uc
    }

    function p(DynamicBuffer memory db, bytes[] memory datas) internal pure {
        unchecked {
            for (uint256 i; i < datas.length; ++i) {
                p(db, datas[i]);
            }
        } // uc
    }

    function _update(DynamicBuffer memory db) private pure {
        if (db.aggregateIdx < 1) return;
        unchecked {
            bytes memory newProcessed = new bytes(db.processed.length + db.aggregateIdx);
            assembly {
                mstore(newProcessed, 0)
            }
            _append(newProcessed, db.processed);

            _update(newProcessed, db.linkedBufferStart.next);
            LinkedBuffer memory first;
            db.processed = newProcessed;
            db.aggregateIdx = 0;
            db.linkedBufferStart = first;
            db.linkedBufferEnd = first;
        } // uc
    }

    function _update(bytes memory buffer, LinkedBuffer[] memory lb) private pure {
        if (lb.length < 1) return;
        LinkedBuffer memory _lb = lb[0];
        _append(buffer, _lb.buffer);
        _update(buffer, _lb.next);
    }
}
