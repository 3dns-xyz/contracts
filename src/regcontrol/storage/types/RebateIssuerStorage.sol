// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import { EnumerableSetUpgradeable } from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

library RebateIssuerStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__REBATE_ISSUER_STORAGE__V1 = keccak256("3dns.reg_control.rebate_issuer.v1.state");

    /// Datastructures ----------------------------------------------------------------------------
    
    /// @dev Struct used to define a payment object...
    struct Rebate {
        uint256 oustanding;
        uint256 claimed;
        uint32[] indexes;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the rebate issuer.
    struct Layout {
        /// @param rebates Mapping of address to rebate.
        mapping (address => Rebate) rebates;

        uint32 domains;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__REBATE_ISSUER_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    ///
    function getRebate(address registrant_) internal view returns (Rebate storage rebate) {
        return layout().rebates[registrant_];
    }

    function incrementOutstandingRebate(address registrant_, uint256 amount) internal {
        Rebate storage rebate = getRebate(registrant_);
        rebate.oustanding += amount;
    }

    function addIndex(address registrant_) internal {
        Rebate storage rebate = getRebate(registrant_);
        rebate.indexes.push(uint32(rebate.indexes.length + 1));
    }

    function resetOutstandingRebate(address registrant_) internal {
        Rebate storage rebate = getRebate(registrant_);
        rebate.oustanding = 0;
    }
} 