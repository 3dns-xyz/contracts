// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {
    IAMStorage as Storage,
    RegistryStorage
} from "src/regcontrol/storage/Storage.sol";

import {IIAM} from "src/regcontrol/interfaces/IIAM.sol";

import {RegControlBase} from "src/regcontrol/modules/types/RegControlBase.sol";
import "src/regcontrol/modules/types/Errors.sol";

/// Contract -----------------------------------------------------------------------------------
contract AccessManagement is RegControlBase {

    /// Authorization Functions -------------------------------------------------------------------

    function _permissionCheck_registration(
        bytes32 node_, address operator_, IIAM.IAMRole role_, IIAM.IAMPermission perm_
    ) internal view returns (bool) {
        if (perm_ == IIAM.IAMPermission.UNDEFINED) {
            revert BaseRegControl_invalidPermission();
        }

        // Operators and controlers are treated as accounts with ADMIN role
        // - Controllers are account level administrators
        // - Operators are token level administrators
        if (_isApprovedRegistrationOperator(node_, operator_) || _isApprovedAccountOperator(node_, operator_)) {
            return true;
        }

        // Check if the operator has the required role
        return _checkRegistrationIAM_hasRole(node_, operator_, role_, perm_);
    }

    /// Administrative Functions ------------------------------------------------------------------

    function _clearRegistrationApprovals(bytes32 node_) internal {
        // Remove the registration approval
        _setRegistrationApproval(node_, address(0));

        // Clear the registration IAM profiles
        _clearRegistrationIAMProfiles(node_);
    }

    function _clearRegistrationIAMProfiles(bytes32 node_) internal {
        // Increment the version number of the IAM profiles to invalidate all existing profiles
        Storage.clearIAMProfiles(node_);

        // Emit event
        emit RegistrationIAMCleared(node_);
    }

    // Token Operator Compliance //

    function _setRegistrationApproval(bytes32 node_, address operator_) internal {
        // Validate operation
        _setRegistrationApproval__validate(node_, operator_);

        if (operator_ == address(0)) {
            // Remove the operator
            RegistryStorage.removeApprovedRegistrationOperator(node_);
        } else {
            // Approve the operator
            RegistryStorage.approveRegistrationOperator(node_, operator_);
        }

        (address registrant_, ,) = RegistryStorage.getRecordData(node_);

        // Emit approval events
        // ERC721 & ERC1155 events are the same
        emit Approval(registrant_, operator_, uint256(node_));
    }

    // Account Operator //

    function _setAccountOperatorApproval(address operator_, bool approval_) internal {
        // Validate operation
        _setAccountOperatorApproval__validate(msg.sender, operator_, approval_);

        // Process request
        _setAccountOperatorApproval__private(msg.sender, operator_, approval_);

        // Emit approval events
        // ENS & ERC721 & ERC1155 events are the same
        emit ApprovalForAll(msg.sender, operator_, approval_);
    }

    // IAM Roles //

    function _setRegistrationIAMAuthorization(
        bytes32 node_, 
        address account_, 
        IIAM.IAMAuthorization[] memory profile_
    ) internal {
        bytes32 perms_;

        // Build the permissions
        for (uint8 i = 0; i < profile_.length; i++) {
            // If the permission has already been set, revert
            if ((perms_ >> (uint8(profile_[i].role) * 2) & bytes32(uint256(3))) > 0)
                revert BaseRegControl_invalidPermission();
            perms_ |= bytes32(uint256(uint8(profile_[i].permission)) << (uint8(profile_[i].role) * 2));
        }
        
        // Set the IAM profile permissions
        Storage.setIAMProfile(node_, account_, perms_);

        // Emit event
        emit RegistrationIAMAuthorization(node_, account_, perms_);
    }
    
    function _setRegistrationIAMRolePermission(
        bytes32 node_, 
        address account_, 
        IIAM.IAMRole role_, 
        IIAM.IAMPermission perm_
    ) internal {
        // Grab the current permissions
        bytes32 perms_ = Storage.getIAMProfile(node_, account_);

        perms_ &= ~bytes32(uint256(uint8(3) << (uint8(role_) * 2)));
        perms_ |= bytes32(uint256(uint8(perm_) << (uint8(role_) * 2)));

        // Update the permissions
        Storage.setIAMProfile(node_, account_, perms_);
        
        // Emit event
        emit RegistrationIAMAuthorization(node_, account_, perms_);
    }

    /// Internal Functions ------------------------------------------------------------------------
       
    // function _getRegistrationIAMProfileAccounts(bytes32 node_) internal view returns (address[] memory) {
    //     return Storage.getIAMProfiles(node_);
    // }
       
    function _getRegistrationIAMProfiles(bytes32 node_) internal view returns (IIAM.IAMProfile[] memory) {
        // Get the accounts with IAM profiles
        address[] memory accounts = Storage.getIAMProfiles(node_);

        // Create the IAM profiles
        IIAM.IAMProfile[] memory profiles = new IIAM.IAMProfile[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) 
            profiles[i] = IIAM.IAMProfile(accounts[i], _getRegistrationIAMProfile(node_, accounts[i]));

        return profiles;
    }

    function _getRegistrationIAMProfile(bytes32 node_, address account_) internal view returns (IIAM.IAMAuthorization[] memory) {
        // Grab the current profile permissions
        bytes32 permissions_ = Storage.getIAMProfile(node_, account_);

        // Create the IAM profile
        IIAM.IAMAuthorization[] memory profile = new IIAM.IAMAuthorization[](4);
        for (uint8 i = 0; i < 4; i++)
            profile[i] = IIAM.IAMAuthorization(IIAM.IAMRole(i), IIAM.IAMPermission((uint256(permissions_) >> (i * 2)) & 0x03));

        return profile;
    }
    
    function _getRegistrationIAMRole(
        bytes32 node_, 
        address account_, 
        IIAM.IAMRole role_
    ) internal view returns (IIAM.IAMPermission) {
        // Grab the current permissions
        bytes32 currentPermissions = Storage.getIAMProfile(node_, account_);
        uint8 role = uint8((uint256(currentPermissions) >> (uint8(role_) * 2)) & 0x03);
        return IIAM.IAMPermission(role);
    }

    function _checkRegistrationIAM_hasRole(
        bytes32 node_, 
        address account_, 
        IIAM.IAMRole role_,
        IIAM.IAMPermission perm_
    ) internal view returns (bool) {
        // If the current role is greater than or equal to the desired permission, return true
        return _getRegistrationIAMRole(node_, account_, role_) >= perm_;
    }

    /// Validators --------------------------------------------------------------------------------
    
    function _setAccountOperatorApproval__validate(
        address account_, address operator_, bool approval_
    ) private {
        // Validate the operator is not the sender or the zero address
        if (account_ == operator_ || operator_ == address(0)) {
            revert BaseRegControl_invalidOperator(operator_);
        }

        // Validate the operator is not the desired approval state
        if (_isApprovedAccountOperator(account_, operator_) == approval_) {
            revert BaseRegControl_operatorStateUnchanged(operator_, approval_);
        }
    }

    function _setRegistrationApproval__validate(bytes32 node_, address operator_) private {
        // Validate the operator is not the sender
        address registrant_ = _getRegistrant(node_);
        if (registrant_ != address(0) && registrant_ == operator_) {
            revert BaseRegControl_invalidOperator(operator_);
        }

        // Validate the registration exists
        if (_isNodeAvailable(node_)) {
            revert BaseRegControl_nodeDoesNotExist(node_);
        }

        // Validate the operator is not the current approved address
        if (operator_ != address(0) && _getApprovedRegistrationOperator(node_) == operator_) {
            revert BaseRegControl_invalidOperator(operator_);
        }
    }

    /// Private Functions -------------------------------------------------------------------------
    
    function _setAccountOperatorApproval__private(
        address registrant_, address operator_, bool approval_
    ) private {
        // Update internal state to track the approval
        if (approval_) {
            RegistryStorage.addAccountOperatorApproval(registrant_, operator_);
        } else {
            RegistryStorage.removeAccountOperatorApproval(registrant_, operator_);
        }
    }

    /// Accessor Functions ------------------------------------------------------------------------
    
    function _isApprovedAccountOperator(bytes32 node_, address operator_) private view returns (bool) {
        return _isApprovedAccountOperator(_getRegistrant(node_), operator_);
    }
    
    function _isApprovedAccountOperator(address owner_, address operator_) internal view returns (bool) {
        // Return true if operator is the owner or the account operator
        return owner_ == operator_ || 
            RegistryStorage.isApprovedAccountOperator(owner_, operator_);
    }

    function _isApprovedRegistrationOperator(bytes32 node_, address operator_) private view returns (bool) {
        // Return true if operator is account operator or token operator
        return _getApprovedRegistrationOperator(node_) == operator_;
    }

    function _getApprovedRegistrationOperator(bytes32 node_) internal view returns (address) {
        return RegistryStorage.getApprovedRegistrationOperator(node_);
    }
}
