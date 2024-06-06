// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IIAM {
    struct IAMProfile {
        address account;
        IAMAuthorization[] perms;
    }

    struct IAMAuthorization {
        IAMRole role;
        IAMPermission permission;
    }

    enum IAMRole {
        ADMIN,
        WEB_MANAGER,
        IDENTITY_MANAGER,
        OFFCHAIN_MANAGER
    }

    enum IAMPermission {
        UNDEFINED,
        VIEW,
        PROPOSE,
        MANAGE
    }

    // Delete all IAM profiles associated with the node
    function clearIAMProfiles(bytes32 node_) external;

    // Setting a profile to 0 will remove it
    function setIAMProfile(bytes32 node_, address account_, IAMAuthorization[] memory perms_) external;
    
    function setIAMPermission(
        bytes32 node_, 
        address account_, 
        IAMRole role_, 
        IAMPermission perm_
    ) external;
    
    function getIAMProfiles(bytes32 node_) external view returns (IAMProfile[] memory);
    function getIAMProfile(bytes32 node_, address account_) external view returns (IAMAuthorization[] memory);

    function getIAMPermission(
        bytes32 node_, 
        address account_, 
        IAMRole role_
    ) external view returns (IAMPermission perm_);

    function hasIAMRole(
        bytes32 node_, 
        address account_, 
        IAMRole role_, 
        IAMPermission perm_
    ) external view returns (bool);
}