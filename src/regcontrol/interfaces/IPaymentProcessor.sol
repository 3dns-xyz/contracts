// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";

interface IPaymentProcessor {
    /// Events ---------------------------------------------------------------------------------

    /// Management Functions ----------------------------------------------------------------------

    /// Accessor Functions ------------------------------------------------------------------------

    function ERC20_USDC_ADDRESS() external returns (IERC20Upgradeable);

    // function rentPrice(
    //     string memory label_,
    //     bytes32 tld_,
    //     uint256 duration_,
    //     Datastructures.PaymentType paymentType_
    // ) external view returns (uint256 amount_);
}
