// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {AbstractPaymentProcessor} from "src/regcontrol/modules/types/abstracts/AbstractPaymentProcessor.sol";

import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";
import {PaymentStorage as Storage} from "src/regcontrol/storage/Storage.sol";

import {IWETH} from "src/utils/interfaces/IWETH.sol";

/// Errors -------------------------------------------------------------------------------------

error PaymentProcessor_insufficientPayment(
    Datastructures.PaymentType paymentType, uint256 paymentAmount, uint256 amount
);
error PaymentProcessor_insufficientBalance(
    Datastructures.PaymentType paymentType, uint256 paymentAmount, uint256 amount
);
error PaymentProcessor_insufficientAllowance(
    Datastructures.PaymentType paymentType, uint256 paymentAmount, uint256 amount
);
error PaymentProcessor_invalidPaymentType(Datastructures.PaymentType paymentType);
error PaymentProcessor_transferFailed();
error PaymentProcessor_permitFailed();

contract PaymentProcessor is Initializable, AbstractPaymentProcessor {    
    /// Constants ------------------------------------------------------------------------------

    address payable constant private WETH = payable(0x4200000000000000000000000000000000000006);

    bytes32 internal constant _TLD_NODE__BOX = 0x665b1306e8eb7fc67d224df1c4ceb9003655ecffaf26d78c2832fe4788a22617;

    address internal constant _WITHDRAWL_ADDRESS__3DNS = 0xBBa294D303555032C6BD1021C639654b95e77Fa8;
    address internal constant _WITHDRAWL_ADDRESS__BOX = 0xBff9E8b1F5eBd6B248238fAAF02F6eC09255ad51;

    /// Initialization Functions ==================================================================

    function __PaymentProcessor_init(IERC20 _usdc) internal onlyInitializing {
        Storage.initialize(_usdc);
    }

    /// Abstract Payment Function Implemantations =================================================

    function _validateRegistrationPayment(Datastructures.OrderPayment memory payment_, bytes32 tld_, uint64 duration_)
        internal
        view
        override
    {
        // TODO: Validate the payment amount relative to the tld

        // Validate the payment
        _validatePayment(payment_, false);
    }

    function _validatePayment(Datastructures.OrderPayment memory payment_, bool zeroPayments_)
        internal
        pure
        override
    {
        // Validate that the payment currency is supported
        if (
            payment_.paymentType != Datastructures.PaymentType.ETH
                && payment_.paymentType != Datastructures.PaymentType.USDC
        ) {
            revert PaymentProcessor_invalidPaymentType(payment_.paymentType);
        }

        // Validate the payment amount
        if (!zeroPayments_ && payment_.amount == 0) {
            revert PaymentProcessor_insufficientPayment(payment_.paymentType, 0, 0);
        }
    }

    function _handlePayment(Datastructures.OrderPayment memory payment_, bool isCommitment_)
        internal
        override
    {
        return _handlePayment(payment_, isCommitment_, msg.sender);
    }

    function _handlePayment(Datastructures.OrderPayment memory payment_, bool isCommitment_, address payee_)
        internal
    {
        uint256 amount_;
        // TODO: Add onchain bounds and handling for the payment amount

        // If this is a commitment payment, then this contract becomes the recipient of the funds
        address recipient_ = isCommitment_ ? address(this) : _WITHDRAWL_ADDRESS__3DNS;

        // Handle the payment
        if (payment_.paymentType == Datastructures.PaymentType.ETH) {
            // ETH payments are processed in WETH
            if ((amount_ = IWETH(WETH).balanceOf(address(this))) < payment_.amount) {
                revert PaymentProcessor_insufficientBalance(payment_.paymentType, uint256(payment_.amount), amount_);
            }

            // Unwrap the WETH
            IWETH(WETH).withdraw(payment_.amount);

            if (!isCommitment_) {
                (bool success,) = payable(recipient_).call{value: payment_.amount}("");
                if (!success) revert PaymentProcessor_transferFailed();
            }
        } else if (payment_.paymentType == Datastructures.PaymentType.USDC) {
            if ((amount_ = Storage.ERC20_USDC_ADDRESS().balanceOf(payee_)) < payment_.amount) {
                revert PaymentProcessor_insufficientBalance(payment_.paymentType, uint256(payment_.amount), amount_);
            }
            if ((amount_ = Storage.ERC20_USDC_ADDRESS().allowance(payee_, address(this))) < payment_.amount) {
                revert PaymentProcessor_insufficientAllowance(payment_.paymentType, uint256(payment_.amount), amount_);
            }

            // Pull USDC from the caller
            Storage.ERC20_USDC_ADDRESS().transferFrom(payee_, recipient_, uint256(payment_.amount));
        } else {
            revert PaymentProcessor_invalidPaymentType(payment_.paymentType);
        }
    }

    function _handlePayout(Datastructures.OrderPayment memory payment_, address recipient_) internal override {
        uint256 amount_;
        if (payment_.paymentType == Datastructures.PaymentType.ETH) {
            if (address(this).balance < payment_.amount) {
                revert PaymentProcessor_insufficientPayment(
                    payment_.paymentType, uint256(payment_.amount), address(this).balance
                );
            }

            // Transfer ETH to the recipient
            (bool success_,) = payable(recipient_).call{value: payment_.amount}("");
            if (!success_) revert PaymentProcessor_transferFailed();
        } else if (payment_.paymentType == Datastructures.PaymentType.USDC) {
            if ((amount_ = Storage.ERC20_USDC_ADDRESS().balanceOf(address(this))) < payment_.amount) {
                revert PaymentProcessor_insufficientBalance(payment_.paymentType, uint256(payment_.amount), amount_);
            }

            // Send USDC from the contract to the recipient
            bool success_ = Storage.ERC20_USDC_ADDRESS().transfer(recipient_, uint256(payment_.amount));
            if (!success_) revert PaymentProcessor_transferFailed();
        } else {
            revert PaymentProcessor_invalidPaymentType(payment_.paymentType);
        }
    }

    function _getPayoutAddress(bytes32 tld_) internal pure override returns (address) {
        // TODO: Update this to the root owner / custodian
        if (tld_ == _TLD_NODE__BOX) return _WITHDRAWL_ADDRESS__BOX;
        return _WITHDRAWL_ADDRESS__3DNS;
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function ERC20_USDC_ADDRESS() public view override returns (IERC20) {
        return Storage.ERC20_USDC_ADDRESS();
    }

    // function rentPrice(
    //     string memory label_,
    //     bytes32 tld_,
    //     uint256 duration_,
    //     Datastructures.PaymentType paymentType_
    // ) external view returns (uint256 amount_) {
    //     revert PaymentModule_notSupported();
    // }
}
