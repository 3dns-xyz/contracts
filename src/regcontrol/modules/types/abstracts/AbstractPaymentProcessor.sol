// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// Internal References ---------------------------------------------------------------------------

import {IPaymentProcessor} from "src/regcontrol/interfaces/IPaymentProcessor.sol";

import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";

/// Errors -------------------------------------------------------------------------------------

error PaymentModule_notSupported();

abstract contract AbstractPaymentProcessor is IPaymentProcessor {

    /// Internal Payment Functions ================================================================

    function _validateRegistrationPayment(
        Datastructures.OrderPayment memory payment_, 
        bytes32 tld_, uint64 duration_
    ) internal view virtual;

    function _validatePayment(
        Datastructures.OrderPayment memory payment_,
        bool zeroPayments_
    ) internal pure virtual;

    function _handlePayment(Datastructures.OrderPayment memory payment_, bool isCommitment_) internal virtual;

    function _handlePayout(Datastructures.OrderPayment memory payment_, address recipient_) internal virtual;

    function _getPayoutAddress(bytes32 tld_) internal virtual returns (address);

    // function _handleGaslessApproval(
    //     Datastructures.PaymentType payment_, 
    //     address from_,
    //     address sponsor_,
    //     uint256 permitAmount_,
    //     uint256 permitFee_,
    //     uint256 deadline_,
    //     bytes memory permitSig_
    // ) internal virtual;

    /// Accessor Functions ------------------------------------------------------------------------

    // function rentPrice(
    //     string memory label_,
    //     bytes32 tld_,
    //     uint256 duration_,
    //     Datastructures.PaymentType paymentType_
    // ) external view returns (uint256 amount_) {
    //     revert PaymentModule_notSupported();
    // }    
}
