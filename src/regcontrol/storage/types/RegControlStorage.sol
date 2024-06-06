// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import { EnumerableSetUpgradeable } from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import { LeadingHashStorage } from "src/utils/storage/LeadingHashStorage.sol";

library RegControlStorage {
    // Libraries ----------------------------------------------------------------------------------

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using LeadingHashStorage for LeadingHashStorage.LHBytes;

    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the registry state
    bytes32 public constant THREE_DNS__REG_CONTROL_CORE_STORAGE__V1 = keccak256("3dns.reg_control.core.v1.state");


    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the core 3dns registry controller.
    struct Layout {
        /// @dev default & primary resolver for all nodes.
        address primaryResolver;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__REG_CONTROL_CORE_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }
    
    /// State Management Functions ----------------------------------------------------------------

    function primaryResolver() internal view returns (address) {
        return layout().primaryResolver;
    }

    function setPrimaryResolver(address resolver_) internal {
        if (address(resolver_) == address(0))
            revert();
        layout().primaryResolver = resolver_;
    }
}