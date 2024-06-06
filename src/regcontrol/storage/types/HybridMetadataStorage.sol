// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {LeadingHashStorage} from "src/utils/storage/LeadingHashStorage.sol";

library HybridMetadataStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__HYBRID_METADATA_STORAGE__V1 = keccak256("3dns.nft.metadata.hybrid.v1.state");

    /// Datastructures ----------------------------------------------------------------------------

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns token metadata.
    struct Layout {
        mapping(bytes32 => string) baseUrl;
        mapping(bytes32 => string) description;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__HYBRID_METADATA_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    function name() internal pure returns (string memory) {
        return "3DNS Powered Domain Name";
    }

    function symbol() internal pure returns (string memory) {
        return "3DNS";
    }

    function setMetadata(bytes32 tld_, string memory baseUrl_, string memory description_) internal {
        layout().baseUrl[tld_] = baseUrl_;
        layout().description[tld_] = description_;
    }

    function getMetadata(bytes32 tld_) internal view returns (string memory baseUrl_, string memory description_) {
        baseUrl_ = layout().baseUrl[tld_];
        description_ = layout().description[tld_];
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function baseUrl(bytes32 tld_) internal view returns (string memory resp) {
        resp = layout().baseUrl[tld_];
        if (bytes(resp).length == 0) {
            resp = layout().baseUrl[bytes32(0x00)];
        }
    }

    function description(bytes32 tld_) internal view returns (string memory resp) {
        resp = layout().description[tld_];
        if (bytes(resp).length == 0) {
            resp = layout().description[bytes32(0x00)];
        }
    }

    /// Bytes32 encoding --------------------------------------------------------------------------

    function bytes32ToHexString(bytes32 data_) internal pure returns (string memory hex_) {
        bytes memory byteArray = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = data_[i];
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            byteArray[i * 2] = _char(hi);
            byteArray[i * 2 + 1] = _char(lo);
        }
        return string(byteArray);
    }

    function _char(bytes1 b_) private pure returns (bytes1 c) {
        if (uint8(b_) < 10) return bytes1(uint8(b_) + 0x30);
        else return bytes1(uint8(b_) + 0x57);
    }

    /// Base64 encoding ---------------------------------------------------------------------------

    string private constant _B64_CHARACTER_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data_) internal pure returns (string memory) {
        if (data_.length == 0) return "";

        // load the table into memory
        string memory table = _B64_CHARACTER_TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data_.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result_ = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result_, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data_
            let endPtr := add(dataPtr, mload(data_))

            // result ptr, jump over length
            let resultPtr := add(result_, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data_), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result_;
    }
}
