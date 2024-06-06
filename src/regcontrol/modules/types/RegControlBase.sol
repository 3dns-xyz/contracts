// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {BytesUtils} from "src/regcontrol/libraries/BytesUtils.sol";
import {
    RegistryStorage as Storage,
    RegControlStorage
} from "src/regcontrol/storage/Storage.sol";

import {GlobalEvents} from "src/regcontrol/modules/types/GlobalEvents.sol";
import "src/regcontrol/modules/types/Errors.sol";

/// Contract -----------------------------------------------------------------------------------
contract RegControlBase is GlobalEvents {

    /// Constants ------------------------------------------------------------------------------

    uint64 internal constant YEAR = 31557600; // 365.25 * 24 * 60 * 60;

    /// Accessor Functions ------------------------------------------------------------------------

    function _getRegistrant(bytes32 node_) internal view returns (address registrant_) {
        uint64 expiration_;
        (registrant_,, expiration_) = Storage.getRecordData(node_);
        if (expiration_ < block.timestamp) {
            registrant_ = address(0x00);
        }
        return registrant_;
    }
    
    function _getNodeData(bytes32 node_) internal view returns (address registrant, uint32 controlBitmap, uint64 expiration) {
        (registrant, controlBitmap, expiration) = Storage.getRecordData(node_);
        if (expiration < block.timestamp) {
            registrant = address(0x00);
        }
        return (registrant, controlBitmap, expiration);
    }

    function _getDomainNameOwnershipCount(address registrant_) internal view returns (uint256) {
        return Storage.getOwnershipCount(registrant_);
    }

    function _getRecordCount() internal view returns (uint256) {
        return Storage.recordCount();
    }

    function _getParent(bytes32 node_) internal view returns (bytes32) {
        return Storage.getParent_reverseRecord(node_);
    }

    function _getLabel(bytes32 node_) internal view returns (bytes memory) {
        return Storage.getLabel_reverseRecord(node_);
    }

    function _resolver(bytes32 node_) internal view returns (address) {
        return RegControlStorage.primaryResolver();
    }

    /// Helper Functions --------------------------------------------------------------------------

    function _isNodeAvailable(bytes32 node_) internal view returns (bool) {
        (address registrant_,, uint64 expiration_) = Storage.getRecordData(node_);
        return registrant_ == address(0x00) || expiration_ < block.timestamp;
    }

    function _isSubdomainAvailable(bytes32 labelHash_, bytes32 parent_) internal view returns (bool) {
        return _isNodeAvailable(_calculateNode(labelHash_, parent_));
    }

    function _hasSubdomains(bytes32 node_) internal view returns (bool) {
        return Storage.recordHasChildren(node_);
    }

    /// Helper Functions --------------------------------------------------------------------------

    function _calculateNode(bytes calldata fqdn_) internal pure returns (bytes32) {
        // Parse the label from the fqdn
        (, bytes32 labelHash_, uint256 offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

        // Parse the tld from the fqdn
        bytes32 tld_ = BytesUtils.namehash(fqdn_, offset_);

        // Calculate the node
        return _calculateNode(labelHash_, tld_);
    }

    function _calculateNode(bytes memory label_, bytes32 parent_) internal pure returns (bytes32) {
        return _calculateNode(keccak256(label_), parent_);
    }

    function _calculateNode(bytes32 labelHash_, bytes32 parent_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent_, labelHash_));
    }
}
