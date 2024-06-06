// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {EnumerableSetUpgradeable} from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {LeadingHashStorage} from "src/utils/storage/LeadingHashStorage.sol";

library RegistryStorage {
    // Libraries -------------------------------------------------------------------------------

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using LeadingHashStorage for LeadingHashStorage.LHBytes;

    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the registry state
    bytes32 public constant THREE_DNS__REGISTRY_STORAGE__V1 = keccak256("3dns.reg_control.registry.v1.state");

    /// Datastructures ----------------------------------------------------------------------------

    /// @dev Struct used to define a record, the base notion of ownership for a zone (primary/apex domain name).
    struct Record {
        // 32 Bytes Packed Data
        // | address - 160 bits | uint32 - 32 bits | uint64 - 64 bits |
        // | Owner Address | Control Bitmap | Expiration (unix seconds) |
        bytes32 data;
        // An enumerable set of all subdomains
        EnumerableSetUpgradeable.Bytes32Set children;
    }

    /// @dev Mapping of child node to its parent node & label. keccak256(parent, keccak256(label)) <=> node
    struct ReverseRecord {
        // The parent node
        bytes32 parent;
        // The label
        LeadingHashStorage.LHBytes label;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        /// @param records Mapping of zone (notioned as node) to its record.
        mapping(bytes32 => Record) records;
        uint256 recordCount;

        /// @param reverseRecords Mapping of child node to its parent node. It also stores the label.
        mapping(bytes32 => ReverseRecord) reverseRecords;
        /// @param ownershipEnumerations Mapping of address (owner) to an enumerable set of owned
        /// zones (notioned as node).
        mapping(address => EnumerableSetUpgradeable.Bytes32Set) ownershipEnumerations;
        
        /// @param operators Mapping of owner to an enumerable set of authorized operators.
        mapping(address => EnumerableSetUpgradeable.AddressSet) accountOperators;

        /// @param approvals Mapping of registration to an approved operator
        mapping(bytes32 => address) registrationOperatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__REGISTRY_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    function recordCount() internal view returns (uint256) {
        return layout().recordCount;
    }

    /// Ownership State Actions ///

    function trackNewOwnership(bytes32 node, address registrant) internal {
        return _trackNewOwnership(layout().ownershipEnumerations[registrant], node);
    }

    function renounceOwnership(bytes32 node, address registrant) internal {
        return _renounceOwnership(layout().ownershipEnumerations[registrant], node);
    }

    function getOwnershipCount(address registrant) internal view returns (uint256) {
        return _getOwnershipCount(layout().ownershipEnumerations[registrant]);
    }

    /// Operator State Actions ///

    // Registrant => Account Operator Approval (can manage all of the users domains)

    function addAccountOperatorApproval(address registrant, address operator) internal {
        return _registerOperator(
            layout().accountOperators[registrant], 
            operator
        );
    }

    function removeAccountOperatorApproval(address registrant, address operator) internal {
        return _removeOperator(
            layout().accountOperators[registrant], 
            operator
        );
    }

    function isApprovedAccountOperator(address registrant, address operator) internal view returns (bool) {
        return _isApprovedAccountOperator(
            layout().accountOperators[registrant], 
            operator
        );
    }

    // Registration => Operator Approval

    function approveRegistrationOperator(bytes32 node, address addr) internal {
        layout().registrationOperatorApprovals[node] = addr;
    }

    function removeApprovedRegistrationOperator(bytes32 node) internal {
        delete layout().registrationOperatorApprovals[node];
    }

    function getApprovedRegistrationOperator(bytes32 node) internal view returns (address) {
        return layout().registrationOperatorApprovals[node];
    }

    /// Record State Actions ///

    function createNewRecord(bytes32 node, address owner, uint32 controlBitmap, uint64 expiration) internal {
        // Increment the record count
        layout().recordCount++;

        // Set the record data
        _setRecordData(layout().records[node], owner, controlBitmap, expiration);
    }

    function setRecordData(bytes32 node, address owner, uint32 controlBitmap, uint64 expiration) internal {
        _setRecordData(layout().records[node], owner, controlBitmap, expiration);
    }

    function deleteRecord(bytes32 node) internal {
        // Revert if the record has children
        if (recordHasChildren(node)) revert();

        // Decrement the record count
        layout().recordCount--;

        // Delete the record
        delete layout().records[node];
    }

    /// Reverse Record State Actions ///

    function trackReverseRecord(bytes32 parent, bytes memory label) internal {
        // Calculate the node from the parent and label
        bytes32 node_ = keccak256(abi.encodePacked(parent, keccak256(label)));

        // Register the reverse record
        _addReverseRecord(node_, parent, label);
    }

    function untrackReverseRecord(bytes32 node) internal {
        // Delete the reverse record & mapping
        _removeReverseRecord(node);
    }

    function getParent_reverseRecord(bytes32 node) internal view returns (bytes32) {
        return layout().reverseRecords[node].parent;
    }

    function getLabel_reverseRecord(bytes32 node) internal view returns (bytes memory) {
        return layout().reverseRecords[node].label.get();
    }

    /// Record Specific Functions =================================================================

    // Data Helper Functions

    function getRecord(bytes32 node) internal view returns (Record storage) {
        return layout().records[node];
    }

    function getRecordData(bytes32 node)
        internal
        view
        returns (address owner, uint32 controlBitmap, uint64 expiration)
    {
        return _getRecordData(layout().records[node]);
    }

    function getRecordChildren(bytes32 node) internal view returns (EnumerableSetUpgradeable.Bytes32Set storage) {
        return _getRecordChildren(layout().records[node]);
    }

    function recordHasChildren(bytes32 node) internal view returns (bool) {
        return _recordHasChildren(layout().records[node]);
    }

    /// Children Helper Functions

    function addChild(bytes32 node, bytes32 child) internal {
        return _addChild(layout().records[node], child);
    }

    function removeChild(bytes32 node, bytes32 child) internal {
        return _removeChild(layout().records[node], child);
    }

    function getChildAtIndex(bytes32 node, uint256 index) internal view returns (bytes32) {
        return _getChildAtIndex(layout().records[node], index);
    }

    function containsChild(bytes32 node, bytes32 child) internal view returns (bool) {
        return _containsChild(layout().records[node], child);
    }

    /// Record Storage Functions ///

    function _getRecordData(Record storage r_)
        private
        view
        returns (address owner, uint32 controlBitmap, uint64 expiration)
    {
        bytes32 data_ = r_.data;

        assembly {
            owner := shr(96, data_)
            controlBitmap := shr(64, data_)
            expiration := data_
        }
    }

    function _setRecordData(Record storage r_, address owner_, uint32 controlBitmap_, uint64 expiration_) private {
        // bytes32 data_;

        // assembly {
        //     // Zero out any extra bits by shifting right then left
        //     let ownerMasked := shl(96, shr(96, owner_))
        //     let controlBitmapMasked := shl(64, shr(192, controlBitmap_))
        //     let expirationMasked := shl(0, shr(192, expiration_))

        //     // Combine the masked and shifted values
        //     data_ := or(or(ownerMasked, controlBitmapMasked), expirationMasked)

        //     data_ := or(or(shl(96, owner_), shl(64, controlBitmap_)), expiration_)
        // }

        // r_.data = data_;
        r_.data = bytes32(uint256(uint160(owner_))) << 96 | (bytes32(uint256(controlBitmap_)) << 64)
            | bytes32(uint256(expiration_));
    }

    function _getRecordChildren(Record storage r_) private view returns (EnumerableSetUpgradeable.Bytes32Set storage) {
        return r_.children;
    }

    function _recordHasChildren(Record storage r_) private view returns (bool) {
        return r_.children.length() > 0;
    }

    /// Children Storage Functions ///

    function _addChild(Record storage r_, bytes32 child) private {
        r_.children.add(child);
    }

    function _removeChild(Record storage r_, bytes32 child) private {
        r_.children.remove(child);
    }

    function _getChildAtIndex(Record storage r_, uint256 index) private view returns (bytes32) {
        return r_.children.at(index);
    }

    function _containsChild(Record storage r_, bytes32 child) private view returns (bool) {
        return r_.children.contains(child);
    }

    /// Ownership Enumeration Storage Functions ///

    function _trackNewOwnership(EnumerableSetUpgradeable.Bytes32Set storage s_, bytes32 node_) private {
        s_.add(node_);
    }

    function _renounceOwnership(EnumerableSetUpgradeable.Bytes32Set storage s_, bytes32 node_) private {
        s_.remove(node_);
    }

    function _getOwnershipCount(EnumerableSetUpgradeable.Bytes32Set storage s_) private view returns (uint256) {
        return s_.length();
    }

    /// Operator Storage Functions ///

    function _registerOperator(EnumerableSetUpgradeable.AddressSet storage s_, address registrant_) private {
        s_.add(registrant_);
    }

    function _removeOperator(EnumerableSetUpgradeable.AddressSet storage s_, address registrant_) private {
        s_.remove(registrant_);
    }

    function _isApprovedAccountOperator(EnumerableSetUpgradeable.AddressSet storage s_, address operator_)
        private
        view
        returns (bool)
    {
        return s_.contains(operator_);
    }

    /// Reverse Record Storage Functions ///

    function _addReverseRecord(bytes32 node, bytes32 parent, bytes memory label) private {
        // Register node as child of parent
        addChild(parent, node);

        // Set the reverse record
        _setReverseRecord(layout().reverseRecords[node], parent, label);
    }

    function _removeReverseRecord(bytes32 node) private {
        // Remove node as child of parent
        removeChild(layout().reverseRecords[node].parent, node);

        // Delete the reverse record
        delete layout().reverseRecords[node];
    }

    function _setReverseRecord(ReverseRecord storage rr_, bytes32 parent, bytes memory label) private {
        rr_.parent = parent;
        rr_.label.set(label);
    }
}
