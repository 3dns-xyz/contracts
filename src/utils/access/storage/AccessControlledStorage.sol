// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {IThreeDNSAuthority} from "../interfaces/IThreeDNSAuthority.sol";

library AccessControlledStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__ACCESS_CONTROLLED_STORAGE__V1 =
        keccak256("3dns.access_controlled.authority.v1.state");

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        /// @dev authority contract
        IThreeDNSAuthority authority;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__ACCESS_CONTROLLED_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize(IThreeDNSAuthority authority_) internal {
        changeAuthority(authority_);
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function authority() internal view returns (IThreeDNSAuthority) {
        return layout().authority;
    }

    function changeAuthority(IThreeDNSAuthority newAuthority_) internal {
        if (address(newAuthority_) == address(0)) {
            revert();
        }

        layout().authority = newAuthority_;
    }
}
