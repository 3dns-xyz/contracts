// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {
    RegistryStorage as Storage, 
    RegistrarStorage
} from "src/regcontrol/storage/Storage.sol";

import {RegControlBase} from "src/regcontrol/modules/types/RegControlBase.sol";
import "src/regcontrol/modules/types/Errors.sol";

/// Contract -----------------------------------------------------------------------------------
contract Enforcer is RegControlBase {

    /// Internal Functions ------------------------------------------------------------------------

    function _lockRegistration(bytes32 node_, uint64 duration_) internal {
        // Validate the registration exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the node has not already expired
        if (_isNodeExpired(node_)) {
            revert BaseRegControl_nodeExpired(node_);
        }


        uint64 lockedUtil_ = uint64(block.timestamp + duration_);

        // Set the lock on the domain
        RegistrarStorage.setDomainLockData(node_, lockedUtil_);

        // Emit a RegistrationLocked event
        emit RegistrationLocked(node_, duration_);
    }

    function _removeRegistrationLock(bytes32 node_) internal {
        // Validate the registration exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the node has not already expired
        if (_isNodeExpired(node_)) {
            revert BaseRegControl_nodeExpired(node_);
        }

        // Remove the lock on the domain
        RegistrarStorage.setDomainLockData(node_, 0);

        // Emit a RegistrationUnlocked event
        emit RegistrationUnlocked(node_);
    }
    
    /// Accessor Functions ------------------------------------------------------------------------

    function _isNodeTransferable(bytes32 node_) internal view returns (bool) {
        return !_isNodeExpired(node_) && !_isNodeLocked(node_);
    }

    function _isNodeLocked(bytes32 node_) internal view returns (bool) {
        // TODO: Add controlBitmap check ~ when implemented
        // Check the registrar storage for domain locks
        (uint64 settlement_) = RegistrarStorage.getDomainLockData(node_);
        return settlement_ > block.timestamp;
    }

    function _isNodeExpired(bytes32 node_) internal view returns (bool) {
        (,, uint64 expiration_) = Storage.getRecordData(node_);
        return expiration_ < block.timestamp;
    }
}
