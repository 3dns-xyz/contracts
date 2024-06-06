// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {IENS} from "src/regcontrol/interfaces/tokens/IENS.sol";

import {IIAM} from "src/regcontrol/interfaces/IIAM.sol";

import {AccessManagement} from "src/regcontrol/modules/types/AccessManagement.sol";
import {Registry} from "src/regcontrol/modules/types/Registry.sol";

import {RegControlStorage} from "src/regcontrol/storage/Storage.sol";

/// Errors -------------------------------------------------------------------------------------

error DomainController_accessDenied();
error DomainController_notSupported();

abstract contract CustomENS is 
    IENS,
    AccessManagement, 
    Registry
{

    /// Constants ---------------------------------------------------------------------------------

    uint64 public constant DEFAULT_TTL = 3600;

    /// User Functions ----------------------------------------------------------------------------

    function transfer(bytes32 node_, address recipient_) external {
        // Run access control check
        if (!_permissionCheck_registration(node_, msg.sender, IIAM.IAMRole.ADMIN, IIAM.IAMPermission.MANAGE)) {
            revert DomainController_accessDenied();
        }

        // Transfer
        _transferRegistration(node_, recipient_);
    }

    /// Approval Functions ------------------------------------------------------------------------

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external override {
        revert DomainController_notSupported();
    }

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external override {
        revert DomainController_notSupported();
    }

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external override returns (bytes32) {
        revert DomainController_notSupported();
    }

    function setResolver(bytes32 node, address resolver) external override {
        revert DomainController_notSupported();
    }

    function setOwner(bytes32 node_, address owner_) external override {
        // Run access control check
        if (!_permissionCheck_registration(node_, msg.sender, IIAM.IAMRole.ADMIN, IIAM.IAMPermission.MANAGE)) {
            revert DomainController_accessDenied();
        }

        // Transfer
        _transferRegistration(node_, owner_);
    }

    function setTTL(bytes32 node, uint64 ttl) external override {
        revert DomainController_notSupported();
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function owner(bytes32 node) public view override returns (address) {
        return _getRegistrant(node);
    }

    function resolver(bytes32 node) external view override returns (address) {
        return _resolver(node);
    }

    function ttl(bytes32 node) external view override returns (uint64) {
        return DEFAULT_TTL;
    }

    function recordExists(bytes32 node) external view override returns (bool) {
        return !_isNodeAvailable(node);
    }
}
