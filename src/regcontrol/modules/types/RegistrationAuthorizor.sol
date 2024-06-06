// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";
import {TypedDataSignature} from "src/utils/signature/TypedDataSignature.sol";

abstract contract RegistrationAuthorizor is TypedDataSignature {
    /// Datastructures ----------------------------------------------------------------------------

    /// @title RegistrationAuthorization
    /// @notice Represents the details of a typed data signature.
    /// @param commitment The commitment being signed.
    /// @param payment The payment details for the order.
    /// @param issuedAt The timestamp of when the signature was issued.
    /// @param expiresAt The timestamp of when the signature expires.
    struct RegistrationAuthorization {
        Datastructures.InternalCommitment commitment;
        uint64 issuedAt;
        uint64 expiresAt;

        bytes32 commitmentHash_;
    }

    /// Peusdo Constants ---------------------------------------------------------------------------

    // Define the EIP712 Type for the TypedDataSignature struct
    bytes32 public immutable override TYPED_DATA_SIGNATURE_TYPEHASH;

    constructor() {
        TYPED_DATA_SIGNATURE_TYPEHASH = keccak256(
            "RegistrationAuthorizationV2(InternalCommitment commitment,uint64 issuedAt,uint64 expiresAt)InternalCommitment(RegistrationRequest request,RegistrationSecret secret)RegistrationRequest(CommitmentType commitmentType,uint64 duration,OrderPayment registrationPayment,OrderPayment servicePayment)RegistrationSecret(address registrant,bytes32 node,bytes32 nonce)OrderPayment(PaymentType paymentType,uint248 amount)"
        );
    }

    /// Initializer ----------------------------------------------------------------------------

    function __RegistrationAuthorizor_init(
        string memory domainName_,
        string memory domainVersion_,
        uint64 chainId_
    ) internal onlyInitializing {
        TypedDataSignature.__TypedDataSignature_init(domainName_, domainVersion_, chainId_);
    }

    /// Typed Data Signature Functions ============================================================

    function _validateSignature(RegistrationAuthorization memory sig_, uint8 v_, bytes32 r_, bytes32 s_) internal view {
        _validateSignature(
            abi.encode(sig_),
            v_, r_, s_
        );
    }

    function _calculateTypeHash(bytes memory data_) internal view override returns (bytes32) {
        RegistrationAuthorization memory sig_ = abi.decode(data_, (RegistrationAuthorization));

        if (sig_.commitmentHash_ == bytes32(0))
            sig_.commitmentHash_ = _calculateCommitmentHash(sig_.commitment);

        // Return the internale type-hash of the data
        return keccak256(
            abi.encode(
                TYPED_DATA_SIGNATURE_TYPEHASH,
                sig_.commitmentHash_,
                sig_.issuedAt,
                sig_.expiresAt
            )
        );
    }

    function _calculateCommitmentHash(Datastructures.InternalCommitment memory commitment_) internal pure returns (bytes32) {
        if (commitment_.secretHash_ == bytes32(0))
            commitment_.secretHash_ = _calculateSecretHash(commitment_.secret);

        // Return the internale type-hash of the commitment
        return keccak256(
            abi.encode(
                _calculateRequestHash(commitment_.request),
                commitment_.secretHash_
            )
        );
    }

    function _calculateRequestHash(Datastructures.RegistrationRequest memory req) internal pure returns (bytes32) {
        // Return the internale type-hash of the req
        return keccak256(
            abi.encode(
                req.commitmentType,
                req.duration,
                _calculatePaymentHash(req.registrationPayment),
                _calculatePaymentHash(req.servicePayment)
            )
        );
    }

    function _calculateSecretHash(Datastructures.RegistrationSecret memory secret) internal pure returns (bytes32) {
        // Return the internale type-hash of the secret
        return keccak256(
            abi.encode(
                secret.registrant,
                secret.node,
                secret.nonce
            )
        );
    }

    function _calculatePaymentHash(Datastructures.OrderPayment memory payment_) internal pure returns (bytes32) {
        // Return the internale type-hash of the payment
        return keccak256(
            abi.encode(
                payment_.paymentType,
                payment_.amount
            )
        );
    }


    function _validPayload(bytes memory data_) internal view virtual override returns (bool) {
        RegistrationAuthorization memory sig_ = abi.decode(data_, (RegistrationAuthorization));

        // Verify that the signature is not expired and not issued in the future
        return (block.timestamp < sig_.expiresAt) && (block.timestamp > sig_.issuedAt);
    }
}
