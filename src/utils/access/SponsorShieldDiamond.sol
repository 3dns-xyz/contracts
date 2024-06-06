// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {SponsorShieldStorage as Storage} from "src/utils/access/storage/SponsorShieldStorage.sol";

error sponsorShield_invalidPaymentType();
error sponsorShield_insufficientAmount();
error sponsorShield_alreadySponsored();
error sponsorShield_unsponsoredPayment();

abstract contract SponsorShieldDiamond is Initializable {
    function __SponsorShield_init() internal onlyInitializing {
        __SponsorShield_init_unchained();
    }

    function __SponsorShield_init_unchained() internal onlyInitializing {
        Storage.initialize();
    }

    function _startSponsorShield(address payee_, uint256 paymentType_, uint256 paymentAmount_) internal {
        // Validate guard is not already active
        if (Storage._getStatus() == Storage._SPONSORED) 
            revert sponsorShield_alreadySponsored();

        // Start guard
        Storage._setStatus(Storage._SPONSORED);

        // Track action
        Storage._setPayee(payee_);
        Storage._setPaymentType(paymentType_);
        Storage._setPaymentAmount(paymentAmount_);
    }

    function _trackSponsoredPayment(address payee_, uint256 paymentType_, uint256 paymentAmount_) internal {
        // Validate guard is active
        if (Storage._getStatus() != Storage._SPONSORED) 
            revert sponsorShield_unsponsoredPayment();

        // Track action
        if (Storage._getPayee() != payee_) 
            revert sponsorShield_unsponsoredPayment();
        if (Storage._getPaymentType() != paymentType_) 
            revert sponsorShield_invalidPaymentType();
        if (!Storage._decrementPaymentAmount(paymentAmount_)) 
            revert sponsorShield_insufficientAmount();
    }

    function _cleanupSponsorShield() internal {
        if (Storage._getStatus() == Storage._SPONSORED) {
            // Cleanup guard
            Storage._setStatus(Storage._NOT_SPONSORED);
            Storage._clearPayment();
        }
    }
}
