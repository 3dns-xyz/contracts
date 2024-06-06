// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {IThreeDNSAuthority} from "../interfaces/IThreeDNSAuthority.sol";

library SponsorShieldStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__SPONSOR_SHIELD_STORAGE__V1 =
        keccak256("3dns.access_controlled.sponsor_shield.v1.state");

    /// Constants ---------------------------------------------------------------------------------
    
    uint256 internal constant _NOT_SPONSORED = 1;
    uint256 internal constant _SPONSORED = 2;

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        uint256 status;

        address payee;
        uint256 paymentType;
        uint256 paymentAmount;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__SPONSOR_SHIELD_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize() internal {
        _setStatus(_NOT_SPONSORED);
    }

    /// Helper Functions --------------------------------------------------------------------------

    function _setStatus(uint256 status) internal {
        layout().status = status;
    }

    function _setPayee(address payee) internal {
        layout().payee = payee;
    }

    function _getPayee() internal view returns (address) {
        return layout().payee;
    }

    function _setPaymentType(uint256 paymentType) internal {
        layout().paymentType = paymentType;
    }

    function _getPaymentType() internal view returns (uint256) {
        return layout().paymentType;
    }

    function _setPaymentAmount(uint256 paymentAmount) internal {
        layout().paymentAmount = paymentAmount;
    }

    function _decrementPaymentAmount(uint256 amount) internal returns (bool) {
        if (layout().paymentAmount < amount) {
            return false;
        }
        layout().paymentAmount -= amount;
        return true;
    }

    function _clearPayment() internal {
        layout().paymentType = 0;
        layout().paymentAmount = 0;
    }

    function _getStatus() internal view returns (uint256) {
        return layout().status;
    }
}
