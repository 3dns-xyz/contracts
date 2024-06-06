// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library Datastructures {
    /// Registration Datastructures ---------------------------------------------------------------

    /// Payment Datastructures --------------------------------------------------------------------

    /// @title OrderPayment
    /// @notice Represents the details of the payment for an order.
    /// @param paymentType The method/type of payment chosen.
    /// @param amount The amount of the payment made, stored in the smallest unit (like wei for ETH).
    struct OrderPayment {
        PaymentType paymentType; // Type of payment (e.g., ETH or USDC)
        uint248 amount; // Amount of payment made. Using uint248 can save storage if combined with other small types in future.
    }

    /// @title PaymentType
    /// @notice Enumerated types of accepted payment methods.
    enum PaymentType {
        UNDEFINED,
        USDC,
        ETH
    }

    /// Commitment Datastructures -----------------------------------------------------------------

    /// @title InternalCommitment
    /// @notice Represents the details of a commitment.
    /// @param secret The registration secret being committed to.
    /// @param request The duration of the registration.
    struct InternalCommitment {
        RegistrationRequest request;
        RegistrationSecret secret;
        bytes32 secretHash_;
    }

    /// @title RegistrationRequest
    /// @notice Represents the details of a registration request.
    /// (uint8,uint64,(uint8,uint248),(uint8,uint248))
    struct RegistrationRequest {
        CommitmentType commitmentType;
        uint64 duration;
        OrderPayment registrationPayment;
        OrderPayment servicePayment;
    }

    /// @title RegistrationSecret
    /// @notice Represents the details of a registration secret.
    /// @param registrant The address of the registrant.
    /// @param node The namehash-encoded domain name being registered.
    /// @param nonce The nonce of the registration secret.
    struct RegistrationSecret {
        address registrant;
        bytes32 node;
        bytes32 nonce;
    }

    /// @title CommitmentType
    /// @notice Enumerated types of commitments.
    enum CommitmentType {
        UNDEFINED,
        REGISTRATION__FULL_TOKENIZATION,  
        RENEWAL,        
        OFFCHAIN__FULL_TOKENIZATION,
        TRANSFER__FULL_TOKENIZATION,
        REGISTRATION__TRADER_TOKENIZATION,
        OFFCHAIN__TRADER_TOKENIZATION,
        TRANSFER__TRADER_TOKENIZATION,
        OFFCHAIN_RENEWAL,
        OFFCHAIN_RENEWAL__TRADER_TOKENIZATION,
        RENEWAL__TRADER_TOKENIZATION,
        SERVICE_PAYMENT
    }

    /// @title Signature
    /// @notice
    /// (uint64,uint64,uint8,bytes32,bytes32)
    struct AuthorizationSignature {
        uint64 issuedAt;
        uint64 expiresAt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
