// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {ICommitmentOrderflow} from "src/regcontrol/interfaces/ICommitmentOrderflow.sol";

import {ThreeDNSAccessControlled} from "src/utils/access/ThreeDNSAccessControlled.sol";
import {PaymentProcessor} from "src/regcontrol/modules/PaymentProcessor.sol";
import {RegistrationAuthorizor} from "src/regcontrol/modules/types/RegistrationAuthorizor.sol";
import {ReentrancyGuardDiamond} from "src/utils/access/ReentrancyGuardDiamond.sol";
import {SponsorShieldDiamond} from "src/utils/access/SponsorShieldDiamond.sol";

import {Registry} from "src/regcontrol/modules/types/Registry.sol";

import {BytesUtils} from "src/regcontrol/libraries/BytesUtils.sol";
import {CommitmentStorage as Storage} from "src/regcontrol/storage/Storage.sol";
import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";

import {IWETH} from "src/utils/interfaces/IWETH.sol";

/// Errors -------------------------------------------------------------------------------------

error CommitmentOrderflow_invalidCommitter();
error CommitmentOrderflow_accessDenied();
error CommitmentOrderflow_transferDoesNotExist();

error CommitmentOrderflow_notCalledThroughMulticall();

error CommitmentOrderflow_invalidCommitmentType(Datastructures.CommitmentType commitmentType_);
error CommitmentOrderflow_invalidDuration(uint64 duration_);
error CommitmentOrderflow_invalidPaymentType(Datastructures.PaymentType paymentType_);
error CommitmentOrderflow_invalidNonce();

error CommitmentOrderflow_commitmentTypeNonRefundable(Datastructures.CommitmentType commitmentType_);
error CommitmentOrderflow_commitmentDoesNotExist(bytes32 commitmentHash_);
error CommitmentOrderflow_commitmentAlreadyExists(bytes32 commitmentHash_);

error CommitmentOrderflow_commitmentNotRefundable(bytes32 commitmentHash_);
error CommitmentOrderflow_commitmentNotRevokable(bytes32 commitmentHash_, uint64 revokableAt_);

/// Contract -----------------------------------------------------------------------------------
contract CommitmentOrderflow is
    Initializable,
    ICommitmentOrderflow,

    RegistrationAuthorizor,
    PaymentProcessor,
    Registry,

    // Access Control
    ThreeDNSAccessControlled,
    ReentrancyGuardDiamond,
    SponsorShieldDiamond 
{
    /// Constants ------------------------------------------------------------------------------

    address private constant WETH = 0x4200000000000000000000000000000000000006;

    /// Initialization Functions ==================================================================

    function __CommitmentOrderflow_init(string memory domainName_, string memory domainVersion_, uint64 chainId_, IERC20 usdc_)
        internal
        onlyInitializing
    {
        // Initialize the RegistrationAuthorizor contract
        RegistrationAuthorizor.__RegistrationAuthorizor_init(domainName_, domainVersion_, chainId_);
        PaymentProcessor.__PaymentProcessor_init(usdc_);
        
        ReentrancyGuardDiamond.__ReentrancyGuard_init();
        SponsorShieldDiamond.__SponsorShield_init();

        Storage.initialize();
    }

    /// Purchase Orderflows -----------------------------------------------------------------------

    function validateCommitmentV2(
        bytes calldata fqdn_,
        address registrant_,
        bytes32 nonce_,
        Datastructures.RegistrationRequest memory req_
    ) public view returns (bytes32 secretHash_) {
        // Validate the commitment
        secretHash_ = _commitment__validate(fqdn_, registrant_, nonce_, req_);

        // Prepare the commitment
        _twoPhase__validateMake(_twoPhase__prepare(req_, secretHash_));

        // Return the secret hash
        return secretHash_;
    }

    function makeCommitmentV2(
        bytes32 secretHash_,
        Datastructures.RegistrationRequest memory req_,
        Datastructures.AuthorizationSignature memory sig_,
        address committer_
    ) public payable {
        // If sender is not the committer, verify this is being called in a permit flow
        if (msg.sender != committer_) {
            // Track and validate the sponsored action
            _trackSponsoredPayment(
                committer_,
                uint256(req_.registrationPayment.paymentType), 
                req_.registrationPayment.amount + req_.servicePayment.amount
            );
        }

        // Verify this is only being called in a nonReentrant context
        if (!_reentrancyGuardEntered()) 
            revert CommitmentOrderflow_notCalledThroughMulticall();

        // Prepare the commitment
        bytes32 commitmentHash_ = _twoPhase__prepare(req_, secretHash_);

        // Validate commitment type is not offchain
        if (_isOffchainCommitment(req_.commitmentType)) {
            revert CommitmentOrderflow_invalidCommitmentType(req_.commitmentType);
        }

        // Validate the commitment
        _twoPhase__validateMake(commitmentHash_);

        // Verify the commitment
        _commitment__verify(commitmentHash_, sig_);

        // Handle the payment
        _handlePayment(req_.registrationPayment, true, committer_);
        if (req_.servicePayment.amount > 0) _handlePayment(req_.servicePayment, true, committer_);

        // Handle and store the commitment
        uint64 revocableAt_ = _commitment__store(commitmentHash_, req_.commitmentType, committer_);

        // Emit the event
        emit PendingCommitment(
            commitmentHash_,
            revocableAt_,
            msg.sender,
            req_.registrationPayment,
            req_.servicePayment,
            sig_.v,
            sig_.r,
            sig_.s
        );
    }

    function processCommitmentV2(  
        bytes calldata fqdn_,
        address registrant_,
        bytes32 nonce_,
        Datastructures.RegistrationRequest calldata req_,
        uint64 customDuration_
    ) public {
        // Run access control check
        _callerIsIssuer__validate();

        // Validate, prepare, and process the commitment
        bytes32 commitmentHash_ = _commitment__process(_twoPhase__prepare(req_, _commitment__validate(fqdn_, registrant_, nonce_, req_)));

        if (customDuration_ > req_.duration) {
            revert CommitmentOrderflow_invalidDuration(customDuration_);
        }

        bytes32 tld_;
        if(_isRegistrationCommitment(req_.commitmentType, false)) {
            // Register the domain
            (, tld_) = _createRegistration(
                fqdn_, registrant_, 
                _setTraderTokenizationTier(0, _isTraderTokenization(req_.commitmentType)), 
                customDuration_
            );
        } else if (_isRenewalCommitment(req_.commitmentType, false)) {
            // Parse the label from the fqdn
            (, bytes32 labelHash_, uint256 offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

            // Parse the tld from the fqdn
            tld_ = BytesUtils.namehash(fqdn_, offset_);

            // Extend the registration
            _extendRegistration(labelHash_, tld_, customDuration_);
        } else if (_isTransferCommitment(req_.commitmentType)) {
            // Parse the label from the fqdn
            (, bytes32 labelHash_, uint256 offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

            // Parse the tld from the fqdn
            tld_ = BytesUtils.namehash(fqdn_, offset_);

            // Calculate the node
            bytes32 node_ = _calculateNode(labelHash_, tld_);

            // Track the transfer so it can be completed / claimed later
            Storage.setDomainTransferFlag(registrant_, node_, customDuration_, _isTraderTokenization(req_.commitmentType));
        } else {
            revert CommitmentOrderflow_invalidCommitmentType(req_.commitmentType);
        }

        // Move the payment
        _handlePayout(req_.registrationPayment, _getPayoutAddress(tld_));
        if (req_.servicePayment.amount > 0) _handlePayout(req_.servicePayment, _getPayoutAddress(0x0));

        // Emit the event
        emit ProcessCommitment(commitmentHash_, msg.sender);
    }

    function refundCommitment(Datastructures.RegistrationRequest calldata req_, bytes32 secretHash_) external {
        // Run access control check
        _callerIsIssuer__validate();

        // Prepare the commitment
        bytes32 commitmentHash_ = _twoPhase__prepare(req_, secretHash_);

        // Verify the action
        _twoPhase__validateRefund(commitmentHash_);

        // Proccess the refund
        address committer_ = _commitment__refund(commitmentHash_, req_);

        // Emit the event
        emit RefundCommitment(
            commitmentHash_, msg.sender, committer_, req_.commitmentType, req_.registrationPayment, req_.servicePayment
        );
    }

    function revokeCommitment(Datastructures.RegistrationRequest calldata req_, bytes32 secretHash_) external {
        // Prepare the commitment
        bytes32 commitmentHash_ = _twoPhase__prepare(req_, secretHash_);

        // Verify the action
        _twoPhase__validateRevoke(commitmentHash_);

        // Proccess the refund
        address committer_ = _commitment__refund(commitmentHash_, req_);

        // Emit the event
        emit RevokeCommitment(
            commitmentHash_, committer_, req_.commitmentType, req_.registrationPayment, req_.servicePayment
        );
    }

    function processOffchainCommitment(
        bytes calldata fqdn_, 
        address registrant_, 
        uint64 duration_, 
        Datastructures.CommitmentType commitmentType_,
        Datastructures.AuthorizationSignature memory sig_
    ) external {
        // Calculate the node
        bytes32 node_ = _calculateNode(fqdn_);

        // Validate the request
        _offchainCommitment__validate(node_, registrant_, duration_, commitmentType_, sig_);

        if (_isRegistrationCommitment(commitmentType_, true)) {
            // Create the registration
            _createRegistration(
                fqdn_, registrant_, 
                _setTraderTokenizationTier(0, _isTraderTokenization(commitmentType_)), 
                duration_
            );
        
            // Lock the domain 
            _lockRegistration(node_, 30 * 24 * 60 * 60);

            // Emit the event
            emit IssuedDomainName(node_, msg.sender);
        } else if (_isRenewalCommitment(commitmentType_, true)) {
            // Parse the label from the fqdn
            (, bytes32 labelHash_, uint256 offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

            // Parse the tld from the fqdn
            bytes32 tld_ = BytesUtils.namehash(fqdn_, offset_);

            // Extend the registration
            _extendRegistration(labelHash_, tld_, duration_);

            // If the renewal is a trader tokenization, downgrade the registration to the trader tier
            if (_isTraderTokenization(commitmentType_)) {
                // TODO: Implement downgrade
                // _downgradeTraderTokenizationTier(labelHash_, tld_);
                revert CommitmentOrderflow_invalidCommitmentType(commitmentType_);
            }
        } else {
            revert CommitmentOrderflow_invalidCommitmentType(commitmentType_);
        }
    }

    function issueTransferredDomainName(
        bytes calldata fqdn_,
        address registrant_
    ) external {
        bytes32 node_ = _calculateNode(fqdn_);

        // Validate the request
        _transferCommitment__validate(node_, registrant_);

        (uint64 duration_, bool isTrader_) = Storage.getDomainTransferFlag(registrant_, node_);

        // Create the registration
        _createRegistration(
            fqdn_, registrant_, 
            _setTraderTokenizationTier(0, isTrader_), 
            duration_
        );

        // Remove the transfer flag
        Storage.deleteDomainTransferFlag(registrant_, node_);
    }

    /// Access Control Functions ==================================================================

    function _callerIsIssuer__validate() internal view {
        if (!_isValidIssuer(msg.sender)) {
            revert CommitmentOrderflow_accessDenied();
        }
    }

    /// Validation Functions ----------------------------------------------------------------------

    function _commitment__validate(
        bytes calldata fqdn_,
        address registrant_,
        bytes32 nonce_,
        Datastructures.RegistrationRequest memory req_
    ) internal view returns (bytes32 secretHash_) {
        bytes32 tld_;
        bytes32 node_;
        
        // Validate the registration relative to the commitment type
        if(_isRegistrationCommitment(req_.commitmentType, false) || _isTransferCommitment(req_.commitmentType)) {
            bytes memory label_;
            (label_, tld_) = _createRegistration__validate(fqdn_, registrant_, req_.duration);

            // Calculate the target node
            node_ = _calculateNode(label_, tld_);
        } else if (_isRenewalCommitment(req_.commitmentType, false)) {
            // Parse the label from the fqdn
            (, bytes32 labelHash_, uint256 offset_) = BytesUtils.readAndReturnLabel(fqdn_, 0);

            // Parse the tld from the fqdn
            tld_ = BytesUtils.namehash(fqdn_, offset_);

            // Validate the renewal
            _extendRegistration__validate(labelHash_, tld_, req_.duration);

            // Calculate the node
            node_ = _calculateNode(labelHash_, tld_);
        } else {
            revert CommitmentOrderflow_invalidCommitmentType(req_.commitmentType);
        }

        // Validate the request
        _validateRegistrationRequest(tld_, req_);

        // Validate nonce is not null nonce
        if (nonce_ == NULL_NONCE) 
            revert CommitmentOrderflow_invalidNonce();

        // Build the secret
        Datastructures.RegistrationSecret memory secret_;
        secret_.registrant = registrant_;
        secret_.node = node_;
        secret_.nonce = nonce_;

        // Calculate the secret hash
        return _calculateSecretHash(secret_);
    }

    bytes32 constant private NULL_NONCE = 0xf490de2920c8a35fabeb13208852aa28c76f9be9b03a4dd2b3c075f7a26923b4;

    function _offchainCommitment__validate(
        bytes32 node_,
        address registrant_,
        uint64 duration_,
        Datastructures.CommitmentType commitmentType_,
        Datastructures.AuthorizationSignature memory sig_
    ) internal view {
        // Run access control check
        _callerIsIssuer__validate();

        // Validate the commitment type
        if (!_isOffchainCommitment(commitmentType_)) {
            revert CommitmentOrderflow_invalidCommitmentType(commitmentType_);
        }

        // Build the issue domain request
        Datastructures.RegistrationRequest memory req_;
        req_.commitmentType = commitmentType_;
        req_.duration = duration_;
                
        // Build the secret
        Datastructures.RegistrationSecret memory secret_;
        secret_.registrant = registrant_;
        secret_.node = node_;
        secret_.nonce = NULL_NONCE;

        // Build and verify the commitment hash
        _commitment__verify(
            _twoPhase__prepare(req_, _calculateSecretHash(secret_)), 
            sig_
        );
    }    

    function _transferCommitment__validate(bytes32 node_, address registrant_) internal view {
        // Run access control check
        _callerIsIssuer__validate();

        // Confirm that the registrant has a transfer flag enabled for the node
        if (!Storage.hasDomainTransferFlag(registrant_, node_))
            revert CommitmentOrderflow_transferDoesNotExist();
    }    

    function _commitment__verify(bytes32 commitmentHash_, Datastructures.AuthorizationSignature memory sig_)
        internal
        view
    {
        // Build the RegistrationAuthorization struct
        RegistrationAuthorization memory authorization_;
        authorization_.commitmentHash_ = commitmentHash_;
        authorization_.issuedAt = sig_.issuedAt;
        authorization_.expiresAt = sig_.expiresAt;

        // Validate the signature
        _validateSignature(authorization_, sig_.v, sig_.r, sig_.s);
    }

    function _commitment__store(
        bytes32 commitmentHash_,
        Datastructures.CommitmentType commitmentType_,
        address committer_
    ) private returns (uint64 revocableAt_) {
        // Calculate recovableAt from COMMITMENT_HALF_LIFE
        revocableAt_ = uint64(block.timestamp + Storage.COMMITMENT_HALF_LIFE());

        // Store the commitment
        Storage.setCommitmentData(commitmentHash_, committer_, revocableAt_);
    }

    function _commitment__process(bytes32 commitmentHash_) private returns (bytes32) {
        // Get the commitment data
        (address committer_, uint64 revokableAt_) = Storage.getCommitmentData(commitmentHash_);

        // Validate the commitment
        if (committer_ == address(0) || revokableAt_ == 0) {
            revert CommitmentOrderflow_commitmentDoesNotExist(commitmentHash_);
        }

        // Remove the commitment
        Storage.deleteCommitment(commitmentHash_);

        return commitmentHash_;
    }

    function _commitment__refund(bytes32 commitmentHash_, Datastructures.RegistrationRequest calldata req_)
        private
        returns (address recipient_)
    {
        // Get the commitment data
        (address committer_, uint64 revokableAt_) = Storage.getCommitmentData(commitmentHash_);

        // Validate the commitment
        if (committer_ == address(0) || revokableAt_ == 0) {
            revert CommitmentOrderflow_commitmentDoesNotExist(commitmentHash_);
        }

        // Remove the commitment
        Storage.deleteCommitment(commitmentHash_);

        // Refund the registration payment & service payment
        if (_isTransferCommitment(req_.commitmentType)) {
            _handlePayout(req_.registrationPayment, _getPayoutAddress(0x0));
        } else {
            _handlePayout(req_.registrationPayment, committer_);
        }
        if (req_.servicePayment.amount > 0) _handlePayout(req_.servicePayment, committer_);

        return committer_;
    }

    /// Two Phase Helpers ///

    function _twoPhase__prepare(Datastructures.RegistrationRequest memory req_, bytes32 secretHash_)
        private
        pure
        returns (bytes32 commitmentHash_)
    {
        // Build the secret hash & the commitment hash
        //
        // The secret hash shields the registration details from the public
        // and the commitment hash binds the payment to the secret hash.
        // The commitment hash is valid until the commitment is either
        // processed, extended, or revoked.
        //
        // The commitment hash half life is calculated when the commitment
        // is made ~ it is valid till block.timestamp + COMMITMENT_HALF_LIFE.
        Datastructures.InternalCommitment memory commitment_;
        commitment_.request = req_;
        commitment_.secretHash_ = secretHash_;

        return _calculateCommitmentHash(commitment_);
    }

    function _twoPhase__validateMake(bytes32 commitmentHash_) private view {
        (address committer_, uint64 revokableAt_) = Storage.getCommitmentData(commitmentHash_);
        // Validate the uniqueness of the commitment
        if (committer_ != address(0) || revokableAt_ != 0) {
            revert CommitmentOrderflow_commitmentAlreadyExists(commitmentHash_);
        }
    }

    function _twoPhase__validateRefund(bytes32 commitmentHash_) private view {
        // Get the commitment data
        (address committer_, uint64 revokableAt_) = Storage.getCommitmentData(commitmentHash_);

        // Validate the commitment exists
        if (committer_ == address(0) || revokableAt_ == 0) {
            revert CommitmentOrderflow_commitmentDoesNotExist(commitmentHash_);
        }

        // Verify the commitment has not expired, if so, let the user revoke it
        if (block.timestamp >= revokableAt_) {
            revert CommitmentOrderflow_commitmentNotRefundable(commitmentHash_);
        }
    }

    function _twoPhase__validateRevoke(bytes32 commitmentHash_) private view {
        // Get the commitment data
        (address committer_, uint64 revokableAt_) = Storage.getCommitmentData(commitmentHash_);

        // Validate the commitment exists
        if (committer_ == address(0) || revokableAt_ == 0) {
            revert CommitmentOrderflow_commitmentDoesNotExist(commitmentHash_);
        }

        // Verify the commitment has expired, if not, reject the revocation
        if (block.timestamp < revokableAt_) {
            revert CommitmentOrderflow_commitmentNotRevokable(commitmentHash_, revokableAt_);
        }
    }

    /// Accessor Functions ------------------------------------------------------------------------

    /// ... ///
    
    /// Helper Functions --------------------------------------------------------------------------

    function _setTraderTokenizationTier(uint32 controlBitmap_, bool isTrader_) internal returns (uint32) {
        return isTrader_ ? controlBitmap_ | 1 << 16 : controlBitmap_; // & ~(1 << 16);
    }

    function _isRegistrationCommitment(Datastructures.CommitmentType commitmentType_, bool offchain_) internal pure returns (bool) {
        return offchain_ ? (
            commitmentType_ == Datastructures.CommitmentType.OFFCHAIN__FULL_TOKENIZATION || 
            commitmentType_ == Datastructures.CommitmentType.OFFCHAIN__TRADER_TOKENIZATION
        ) : (
            commitmentType_ == Datastructures.CommitmentType.REGISTRATION__FULL_TOKENIZATION || 
            commitmentType_ == Datastructures.CommitmentType.REGISTRATION__TRADER_TOKENIZATION
        );
    }

    function _isTransferCommitment(Datastructures.CommitmentType commitmentType_) internal pure returns (bool) {
        return 
            commitmentType_ == Datastructures.CommitmentType.TRANSFER__FULL_TOKENIZATION || 
            commitmentType_ == Datastructures.CommitmentType.TRANSFER__TRADER_TOKENIZATION;
    }

    function _isRenewalCommitment(Datastructures.CommitmentType commitmentType_, bool offchain_) internal pure returns (bool) {
        return offchain_ ? (
            commitmentType_ == Datastructures.CommitmentType.OFFCHAIN_RENEWAL || 
            commitmentType_ == Datastructures.CommitmentType.OFFCHAIN_RENEWAL__TRADER_TOKENIZATION
        ) : (
            commitmentType_ == Datastructures.CommitmentType.RENEWAL ||
            commitmentType_ == Datastructures.CommitmentType.RENEWAL__TRADER_TOKENIZATION
        );
    }

    function _isTraderTokenization(Datastructures.CommitmentType commitmentType_) internal pure returns (bool) {
        return commitmentType_ == Datastructures.CommitmentType.REGISTRATION__TRADER_TOKENIZATION||
        commitmentType_ == Datastructures.CommitmentType.TRANSFER__TRADER_TOKENIZATION ||
        commitmentType_ == Datastructures.CommitmentType.RENEWAL__TRADER_TOKENIZATION ||
        commitmentType_ == Datastructures.CommitmentType.OFFCHAIN__TRADER_TOKENIZATION ||
        commitmentType_ == Datastructures.CommitmentType.OFFCHAIN_RENEWAL__TRADER_TOKENIZATION;
    }

    function _isOffchainCommitment(Datastructures.CommitmentType commitmentType_) internal pure returns (bool) {
        return commitmentType_ == Datastructures.CommitmentType.OFFCHAIN__FULL_TOKENIZATION || 
        commitmentType_ == Datastructures.CommitmentType.OFFCHAIN__TRADER_TOKENIZATION ||
        commitmentType_ == Datastructures.CommitmentType.OFFCHAIN_RENEWAL || 
        commitmentType_ == Datastructures.CommitmentType.OFFCHAIN_RENEWAL__TRADER_TOKENIZATION;
    }

    /// Misc Validators ---------------------------------------------------------------------------

    function _validateRegistrationRequest(bytes32 tld_, Datastructures.RegistrationRequest memory req_) internal view {
        // Validate the commitment type
        /// @note duration is validated in _createRegistration__validate

        // Validate the registration & service payments
        _validateRegistrationPayment(req_.registrationPayment, tld_, req_.duration);
        _validatePayment(req_.servicePayment, true);

        // Validate the service payment type matches the registration
        if (req_.registrationPayment.paymentType != req_.servicePayment.paymentType) {
            revert CommitmentOrderflow_invalidPaymentType(req_.servicePayment.paymentType);
        }
    }

    /// Administrative Action Validators ==========================================================

    /// @dev Message signature function override for signer role check.
    function _isValidSigner(address signer_) internal view override returns (bool) {
        return authority().isRole(authority().ROLE__SIGNER(), signer_);
    }

    /// @dev Internal function for issuer role check.
    function _isValidIssuer(address issuer_) internal view returns (bool) {
        return authority().isRole(authority().ROLE__ISSUER(), issuer_);
    }
}
