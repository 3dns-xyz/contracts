// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {BytesUtils} from "src/regcontrol/libraries/BytesUtils.sol";
import {
    RegistryStorage as Storage, 
    RegistrarStorage
} from "src/regcontrol/storage/Storage.sol";

import {AccessManagement} from "src/regcontrol/modules/types/AccessManagement.sol";
import {Enforcer} from "src/regcontrol/modules/types/Enforcer.sol";
import "src/regcontrol/modules/types/Errors.sol";

/// Contract -----------------------------------------------------------------------------------
contract Registry is AccessManagement, Enforcer {

    /// Internal Functions ------------------------------------------------------------------------

    function _createRegistration(bytes calldata fqdn_, address registrant_, uint32 controlBitmap_, uint64 duration_)
        internal
        returns (bytes32 node_, bytes32 tld_)
    {
        // Validate the registration
        bytes memory label_;
        (label_, tld_) = _createRegistration__validate(fqdn_, registrant_, duration_);

        // Update internal state to track the registration
        uint64 expiration_ = uint64(block.timestamp) + uint64(duration_);
        (node_) = _createRegistration__private(label_, tld_, registrant_, controlBitmap_, expiration_);

        // Emit a RegistrationCreated event
        emit RegistrationCreated(node_, tld_, fqdn_, registrant_, controlBitmap_, expiration_);

        // ERC721 Event
        emit Transfer(address(0x00), registrant_, uint256(node_));

        // ERC1155 Event
        emit TransferSingle(msg.sender, address(0x00), registrant_, uint256(node_), 1);

        // ENS Event
        emit NewOwner(tld_, keccak256(label_), registrant_);
        emit Transfer(node_, registrant_);
    }

    function _extendRegistration(bytes32 labelHash_, bytes32 tld_, uint64 duration_) internal {
        // Validate the registration duration extension
        (bytes32 node_, uint64 newExpiry_) = _extendRegistration__validate(labelHash_, tld_, duration_);

        // Update internal state to track the new expiry
        _extendRegistration__private(node_, newExpiry_);

        // Emit a RegistrationExtended event
        emit RegistrationExtended(node_, duration_, newExpiry_);
    }

    function _transferRegistration(bytes32 node_, address newRegistrant_) internal {
        // Validate the transfer
        _transferRegistration__validate(node_, newRegistrant_);

        // Update internal state to track the transfer
        address oldRegistrant_ = _transferRegistration__private(node_, newRegistrant_);

        // Emit a RegistrationTransferred event
        emit RegistrationTransferred(node_, newRegistrant_, msg.sender);

        // ERC721 Event
        emit Transfer(oldRegistrant_, newRegistrant_, uint256(node_));

        // ERC1155 Event
        emit TransferSingle(msg.sender, oldRegistrant_, newRegistrant_, uint256(node_), 1);

        // ENS Event
        emit Transfer(node_, newRegistrant_);
    }

    function _burnRegistration(bytes32 node_) internal {
        // Validate the registration exits and has no subdomains
        _burnRegistration__validate(node_);

        // Update internal state to remove the registration
        address registrant_ = _burnRegistration__private(node_);

        // Emit a RegistrationBurned event
        emit RegistrationBurned(node_, msg.sender);

        // ERC721 Event
        emit Transfer(registrant_, address(0x00), uint256(node_));

        // ERC1155 Event
        emit TransferSingle(msg.sender, registrant_, address(0x00), uint256(node_), 1);

        // ENS Event
        emit Transfer(node_, address(0x00));
    }

    /// Validators --------------------------------------------------------------------------------

    function _createRegistration__validate(bytes calldata fqdn_, address registrant_, uint64 duration_)
        internal
        view
        returns (bytes memory label_, bytes32 tld_)
    {
        bytes32 labelHash_;
        uint256 offset_;

        // Parse the label from the fqdn
        (label_, labelHash_, offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

        // Validate the label
        if (!_isValidDomainLabel(label_)) {
            revert BaseRegControl_invalidLabel(label_);
        }

        // Parse the tld from the fqdn
        tld_ = BytesUtils.namehash(fqdn_, offset_);

        // Validate the tld
        if (!_isTLDEnabled(tld_)) {
            revert BaseRegControl_invalidTLD(tld_);
        }

        // Validate the uniqueness of the node
        if (!_isSubdomainAvailable(labelHash_, tld_)) {
            revert BaseRegControl_subdomainUnavailable(label_, tld_);
        }

        // Validate the registrant is not the zero address
        if (registrant_ == address(0x00)) {
            revert BaseRegControl_invalidRegistrant(registrant_);
        }

        // Validate the duration
        if (!_isValidRegistrationDuration(duration_)) {
            revert BaseRegControl_invalidDuration(duration_);
        }

        return (label_, tld_);
    }

    function _extendRegistration__validate(bytes32 labelHash_, bytes32 tld_, uint64 duration_)
        internal
        view
        returns (bytes32 node_, uint64 newExpiry_)
    {
        // Calculate the node
        node_ = _calculateNode(labelHash_, tld_);

        // Validate the node exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the node has not already expired
        if (_isNodeExpired(node_)) {
            revert BaseRegControl_nodeExpired(node_);
        }

        // Validate the tld is enabled
        if (!_isTLDEnabled(tld_)) {
            revert BaseRegControl_invalidTLD(tld_);
        }

        // TODO: Validate the tld is not locked

        // Validate the new expiry
        bool valid_;
        (valid_, newExpiry_) = _isValidRegistrationDurationExtension(node_, duration_);
        if (!valid_) {
            revert BaseRegControl_invalidDurationExtension(duration_);
        }

        return (node_, newExpiry_);
    }

    function _transferRegistration__validate(bytes32 node_, address newRegistrant_) internal view {
        // Validate the node exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the node is transferable (not expired or locked)
        if (!_isNodeTransferable(node_)) {
            revert BaseRegControl_nodeNotTransferable(node_);
        }

        // Validate the new registrant is not the zero address
        if (newRegistrant_ == address(0x00)) {
            revert BaseRegControl_invalidRegistrant(newRegistrant_);
        }
    }

    function _burnRegistration__validate(bytes32 node_) internal view {
        // Validate the node exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the node has not already expired
        if (_isNodeExpired(node_)) {
            revert BaseRegControl_nodeExpired(node_);
        }

        // Validate the node has no children/subdomains
        if (_hasSubdomains(node_)) {
            revert BaseRegControl_nodeHasSubdomains(node_);
        }
    }

    /// Private Functions -------------------------------------------------------------------------

    function _createRegistration__private(
        bytes memory label_,
        bytes32 parent_,
        address registrant_,
        uint32 controlBitmap_,
        uint64 expiration_
    ) private returns (bytes32 node_) {
        // Calculate the node
        node_ = _calculateNode(keccak256(label_), parent_);

        // Initialize the record data
        (address owner_,,) = Storage.getRecordData(node_);
        if (owner_ == address(0)) {
            // Create the new record
            Storage.createNewRecord(node_, registrant_, controlBitmap_, expiration_);

            // Build a reverse record mapping for the node to the parent
            Storage.trackReverseRecord(parent_, label_);
        } else {
            // Update the record data
            Storage.setRecordData(node_, registrant_, controlBitmap_, expiration_);

            // Renounce it from the previous owner
            Storage.renounceOwnership(node_, registrant_);
        }

        // Track the ownership
        Storage.trackNewOwnership(node_, registrant_);

        // Remove approvals
        _clearRegistrationApprovals(node_);
    }

    function _extendRegistration__private(bytes32 node_, uint64 newExpiry_) private {
        // Get the current record data
        (address registrant_, uint32 controlBitmap_,) = Storage.getRecordData(node_);

        // Update the current expiry of the node
        Storage.setRecordData(node_, registrant_, controlBitmap_, newExpiry_);
    }

    function _transferRegistration__private(bytes32 node_, address newRegistrant_) private returns (address) {
        // Get the current registrant of the node
        (address registrant_, uint32 controlBitmap, uint64 expiry_) = Storage.getRecordData(node_);

        // Remove the node from the registrant's enumerable set
        Storage.renounceOwnership(node_, registrant_);

        // Update the registrant record
        Storage.setRecordData(node_, newRegistrant_, controlBitmap, expiry_);

        // Track the ownership with the new registrant
        Storage.trackNewOwnership(node_, newRegistrant_);
        
        // Remove approvals
        _clearRegistrationApprovals(node_);

        return registrant_;
    }

    function _burnRegistration__private(bytes32 node_) private returns (address) {
        address registrant_ = _getRegistrant(node_);

        // Renounce the ownership of the node
        Storage.renounceOwnership(node_, registrant_);

        // Remove the reverse record mapping
        Storage.untrackReverseRecord(node_);

        // Remove the node from the records mapping
        Storage.deleteRecord(node_);

        // Remove approval
        _clearRegistrationApprovals(node_);

        // Delete any locks on the domain
        RegistrarStorage.setDomainLockData(node_, 0);

        return registrant_;
    }

    /// Helper Functions --------------------------------------------------------------------------

    function _isValidDomainLabel(bytes memory label_) internal pure returns (bool) {
        // Check if label is empty or exceeds 63 characters
        if (label_.length == 0x00 || label_.length > 0x3f) return false;

        // Check first and last character for hyphen
        if (label_[0] == 0x2d || label_[label_.length - 1] == 0x2d) return false;

        // Check if label contains invalid characters
        for (uint256 i = 0; i < label_.length; i++) {
            bytes1 char_ = label_[i];

            // Ensure alphanumeric and lowercase.
            // ASCII values: 0-9 => 48-57, a-z => 97-122
            // 45 is hyphen ("-")
            if (
                !(char_ >= 0x30 && char_ <= 0x39) // Check for 0-9
                    && !(char_ >= 0x61 && char_ <= 0x7A) // Check for a-z
                    && char_ != 0x2d
            ) {
                // Check for hyphen, but we already checked the start and end
                return false;
            }
        }
        return true;
    }

    function _isValidRegistrationDuration(uint64 duration_) internal pure returns (bool) {
        return duration_ > 0 && duration_ <= 10 * YEAR;
    }

    function _isValidRegistrationDurationExtension(bytes32 node_, uint64 durationExtension_)
        internal
        view
        returns (bool valid_, uint64 newExpiry_)
    {
        // Renewal must be non zero and in years
        // The new cumulative duration must be less than 10 years

        // Get the current expiry & calculate the new expiry.
        (,, newExpiry_) = Storage.getRecordData(node_);
        newExpiry_ += durationExtension_;

        // Validate the extension and the new expiry.
        valid_ = _isValidRegistrationDuration(durationExtension_) && newExpiry_ <= (block.timestamp + 10 * YEAR);

        // Return the validity and the new expiration.
        return (valid_, newExpiry_);
    }

    function _isTLDEnabled(bytes32 tld_) internal view returns (bool) {
        (bool enabled_) = RegistrarStorage.getTLDData(tld_);
        return enabled_;
    }
}
