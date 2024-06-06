// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {IThreeDNSAuthority} from "../interfaces/IThreeDNSAuthority.sol";

library ReentrancyGuardStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__REENTRANCY_GUARD_STORAGE__V1 =
        keccak256("3dns.access_controlled.reentrancy_guard.v1.state");

    /// Constants ---------------------------------------------------------------------------------
    
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        uint256 status;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__REENTRANCY_GUARD_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize() internal {
        _setStatus(_NOT_ENTERED);
    }

    /// Helper Functions --------------------------------------------------------------------------

    function _setStatus(uint256 status) internal {
        layout().status = status;
    }

    function _getStatus() internal view returns (uint256) {
        return layout().status;
    }
}
