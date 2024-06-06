// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";

interface ICommitmentOrderflow {
    /// Events ---------------------------------------------------------------------------------

    /// Two Phase Commitments ///

    // Commitment V1 Signature
    // event PendingCommitment(
    //     bytes32 indexed commitmentHash_, uint64 indexed revocableAt_, address indexed committer,
    //     Datastructures.OrderPayment payment,
    //     uint8 v_, bytes32 r_, bytes32 s_
    // );
    //
    // event RefundCommitment(
    //     bytes32 indexed commitmentHash_, address indexed issuer,  address indexed committer,
    //     Datastructures.OrderPayment payment
    // );
    //
    // event RevokeCommitment(
    //     bytes32 indexed commitmentHash_, address indexed committer,
    //     Datastructures.OrderPayment payment
    // );

    event PendingCommitment(
        bytes32 indexed commitmentHash_,
        uint64 indexed revocableAt_,
        address indexed committer,
        Datastructures.OrderPayment registrationPayment,
        Datastructures.OrderPayment servicePayment,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    );

    event RefundCommitment(
        bytes32 indexed commitmentHash_,
        address indexed issuer,
        address indexed committer,
        Datastructures.CommitmentType commitmentType,
        Datastructures.OrderPayment registrationPayment,
        Datastructures.OrderPayment servicePayment
    );

    event RevokeCommitment(
        bytes32 indexed commitmentHash_,
        address indexed committer,
        Datastructures.CommitmentType commitmentType,
        Datastructures.OrderPayment registrationPayment,
        Datastructures.OrderPayment servicePayment
    );

    event ProcessCommitment(bytes32 indexed commitmentHash_, address indexed processor);

    /// Offchain Commitments ///

    event IssuedDomainName(bytes32 indexed node_, address indexed issuer_);
    // event IssuedDomainName(bytes32 indexed node_, address indexed issuer_, uint64 indexed lockedUntil_);

    /// Service Orderflows ///

    event PurchasedService(
        bytes32 indexed commitment_, address indexed registrant_, Datastructures.OrderPayment payment
    );

    /// Purchase Orderflows -----------------------------------------------------------------------

    /// Two Phase Orderflows ///

    function validateCommitmentV2(
        bytes calldata fqdn_,
        address registrant_,
        bytes32 nonce_,
        Datastructures.RegistrationRequest memory req_
    ) external view returns (bytes32 secretHash_);

    function makeCommitmentV2(
        bytes32 secretHash_,
        Datastructures.RegistrationRequest memory req_,
        Datastructures.AuthorizationSignature memory sig_,
        address committer_
    ) external payable;

    // // Purchasing a domain will trigger a series of events:
    // // 1. A NewRegistration event will be emitted
    // // 2. A TransferSingle event will be emitted
    // // 3. A Renewed event will be emitted with the expiry date of the domain
    // // function validateCommitment(
    // //     bytes calldata fqdn_,
    // //     address registrant_,
    // //     uint64 duration_,
    // //     bytes32 nonce_,
    // //     Datastructures.OrderPayment calldata payment_
    // // ) external view returns (bytes32 secretHash_);

    // function validateCommitmentV2(
    //     bytes calldata fqdn_,
    //     address registrant_,
    //     bytes32 nonce_,
    //     Datastructures.RegistrationRequest calldata req_
    // ) external view returns (bytes32 secretHash_);

    // // function makeCommitment(
    // //     bytes32 secretHash_,
    // //     uint64 duration_,
    // //     Datastructures.OrderPayment calldata payment_,
    // //     uint64 issuedAt_,
    // //     uint64 expiresAt_,
    // //     uint8 v_,
    // //     bytes32 r_,
    // //     bytes32 s_
    // // ) external payable;

    // function processCommitment(
    //     bytes calldata fqdn_,
    //     address registrant_,
    //     bytes32 nonce_,
    //     Datastructures.RegistrationRequest calldata req_
    // ) external;

    // function refundCommitment(Datastructures.RegistrationRequest calldata req_, bytes32 secretHash_) external;

    // function revokeCommitment(Datastructures.RegistrationRequest calldata req_, bytes32 secretHash_) external;

    /// Off-Chain Issuance ------------------------------------------------------------------------

    /// Off-Chain Orderflows ///

    // // Issued domain names cant be transferred for the first 30 days
    // function issueDomainName(
    //     bytes calldata fqdn_, address registrant_, uint64 duration_, 
    //     Datastructures.AuthorizationSignature memory sig_
    // ) external;
}
