// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {IERC20Upgradeable as IERC20} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { EnumerableSetUpgradeable } from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import { LeadingHashStorage } from "src/utils/storage/LeadingHashStorage.sol";

library PaymentStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__PAYMENT_STORAGE__V1 = keccak256("3dns.reg_control.payment.v1.state");

    /// Datastructures ----------------------------------------------------------------------------
    
    /// @dev Struct used to define a payment object...
    struct Payment {
        // 32 Bytes Packed Data
        // | address - 160 bits | uint32 - 32 bits | uint64 - 64 bits |
        // | Owner Address | Control Bitmap | Expiration (unix seconds) |
        bytes32 data;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        /// @param payments Mapping of subdomain payment rules from a corresponding node.
        mapping (bytes32 => Payment) payments;
        
        // Supported Payment Types
        IERC20 usdc;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__PAYMENT_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize(IERC20 _usdc) internal {
        setUSDCTokenAddress(_usdc);
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    function setUSDCTokenAddress(IERC20 usdc) internal {
        layout().usdc = IERC20(usdc);
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function ERC20_USDC_ADDRESS() internal view returns (IERC20) {
        return layout().usdc;
    }
}