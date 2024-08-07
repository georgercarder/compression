// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "./LibPack.sol";
import "./Append.sol";

// see https://medium.com/asecuritysite-when-bob-met-alice/how-to-do-aes-on-a-blockchain-without-consuming-too-much-gas-580e7226b26b

library LibEncryption {
    error InvalidInput_error();

    // creates a streaming cipher of the form h_0|h_1|...|h_n-1
    // where h_i = h(key | nonce | counter)
    // ALWAYS use fresh nonce or else plaintext attack vector
    function xorEncrypt(bytes32 key, bytes32 nonce, bytes memory data) internal pure returns (bytes memory ret) {
        uint256 length = (data.length % 32 == 0) ? data.length : 32 * (data.length / 32 + 1);
        bytes memory boundedData = new bytes(length + 1);
        boundedData[0] = 0x20;
        assembly {
            mstore(boundedData, 1)
        }
        _append(boundedData, data);
        assembly {
            mstore(boundedData, add(length, 1))
        }
        uint256[] memory uintData = LibPack.unpackBytesIntoUint256s(boundedData);
        length = uintData.length;
        uint256[] memory uintDataLengthed = new uint256[](length + 1);
        assembly {
            uintDataLengthed := uintData
            mstore(uintDataLengthed, add(length, 1))
        }
        uintDataLengthed[length] = data.length;

        bytes32[] memory bytes32Data;
        assembly {
            bytes32Data := uintDataLengthed
        }
        bytes memory bNonce = new bytes(32);
        assembly {
            mstore(add(bNonce, 0x20), nonce)
        }
        bytes memory preHash = new bytes(96); // key, nonce, ctr
        assembly {
            mstore(add(preHash, 0x20), key)
            mstore(add(preHash, 0x40), nonce)
        }
        bytes32 hash;
        for (uint256 i; i < uintData.length; ++i) {
            assembly {
                mstore(add(preHash, 0x60), i)
                hash := keccak256(add(preHash, 0x20), 0x60)
            }

            bytes32Data[i] = hash ^ bytes32Data[i];
        }
        bytes[] memory arrs = new bytes[](2);
        arrs[0] = bNonce;
        arrs[1] = LibPack.packUint256s(uintDataLengthed);
        ret = LibPack.packBytesArrs(arrs);
    }

    // the inverse of `xorEncrypt`
    // assumes input is output of `xorEncrypt`
    function xorDecrypt(bytes32 key, bytes memory encrypted) internal pure returns (bytes memory ret) {
        bytes[] memory arrs = LibPack.unpackBytesIntoBytesArrs(encrypted);
        bytes memory bNonce = arrs[0];
        bytes memory ciphertext = arrs[1];

        uint256[] memory uintDataLengthed = LibPack.unpackBytesIntoUint256s(ciphertext);
        bytes32[] memory bytes32Data;
        assembly {
            bytes32Data := uintDataLengthed
        }
        bytes memory preHash = new bytes(96); // key, nonce, ctr
        assembly {
            mstore(add(preHash, 0x20), key)
            mstore(add(preHash, 0x40), mload(add(bNonce, 0x20)))
        }
        bytes32 hash;
        unchecked {
            for (uint256 i; i < uintDataLengthed.length; ++i) {
                assembly {
                    mstore(add(preHash, 0x60), i)
                    hash := keccak256(add(preHash, 0x20), 0x60)
                }

                bytes32Data[i] = hash ^ bytes32Data[i];
            }
            uint256 length = uintDataLengthed[uintDataLengthed.length - 1];
            ret = new bytes(length);
            assembly {
                mstore(ret, 0)
            }
            _appendSubstring(ret, LibPack.packUint256s(uintDataLengthed), 1, length + 1);
        } // uc
    }
}
