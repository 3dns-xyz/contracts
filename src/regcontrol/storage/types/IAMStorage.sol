// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {EnumerableSetUpgradeable} from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {LeadingHashStorage} from "src/utils/storage/LeadingHashStorage.sol";

library IAMStorage {
    // Libraries -------------------------------------------------------------------------------

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the iam state
    bytes32 public constant THREE_DNS__IAM_STORAGE__V1 = keccak256("3dns.reg_control.iam.v1.state");

    /// Datastructures ----------------------------------------------------------------------------

    struct IAMProfiles {
        EnumerableSetUpgradeable.AddressSet profiles;
        mapping(address => bytes32) permissions;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        /// @param approvals Mapping of token to IAM permissions
        mapping(bytes32 => mapping(uint256 => IAMProfiles)) iamProfiles;
        mapping(bytes32 => uint256) iamProfilesVersion;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__IAM_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    function getIAMProfilesVersion(bytes32 node) internal view returns (uint256) {
        return layout().iamProfilesVersion[node];
    }

    function clearIAMProfiles(bytes32 node) internal {
        layout().iamProfilesVersion[node]++;
    }

    function hasIAMProfile(bytes32 node, address user) internal view returns (bool) {
        return layout().iamProfiles[node][getIAMProfilesVersion(node)].profiles.contains(user);
    }

    function getIAMProfiles(bytes32 node) internal view returns (address[] memory) {
        return layout().iamProfiles[node][getIAMProfilesVersion(node)].profiles.values();
    }

    function getIAMProfile(bytes32 node, address user) internal view returns (bytes32) {
        return layout().iamProfiles[node][getIAMProfilesVersion(node)].permissions[user];
    }

    function setIAMProfile(bytes32 node, address user, bytes32 profile) internal {
        if (profile == 0) {
            deleteIAMProfile(node, user);
        } else {
            if (!hasIAMProfile(node, user)) {
                layout().iamProfiles[node][getIAMProfilesVersion(node)].profiles.add(user);
            }
            layout().iamProfiles[node][getIAMProfilesVersion(node)].permissions[user] = profile;
        }
    }

    function deleteIAMProfile(bytes32 node, address user) internal {
        layout().iamProfiles[node][getIAMProfilesVersion(node)].profiles.remove(user);
        delete layout().iamProfiles[node][getIAMProfilesVersion(node)].permissions[user];
    }
}
