// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import { EnumerableSetUpgradeable } from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import { LeadingHashStorage } from "src/utils/storage/LeadingHashStorage.sol";

library CommitmentStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__COMMITMENT_STORAGE__V1 = keccak256("3dns.reg_control.commitment.v1.state");

    /// Datastructures ----------------------------------------------------------------------------
    
    /// @dev Struct used to define a payment object...
    struct RegistrationCommitment {
        // 32 Bytes Packed Data
        // | 32 bits | address - 160 bits |     uint64 - 64 bits      |
        // |   ...   |   Owner Address    | Expiration (unix seconds) |
        bytes32 data;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the commitment store.
    struct Layout {
        /// @param commitments Mapping of commitment hash to commitment data.
        mapping (bytes32 => RegistrationCommitment) commitments;

        uint64 commitmentHalfLife;
        uint64 signatureHalfLife;
        uint64 transferCommitmentHalfLife;

        /// @param domainTransferFlags Mapping of pending transfers for a user.
        mapping (address => mapping (bytes32 => uint72)) domainTransferFlags;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__COMMITMENT_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize() internal {
        layout().commitmentHalfLife = 90 minutes;
        layout().transferCommitmentHalfLife = 30 minutes;
        layout().signatureHalfLife = 5 minutes;
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    function setCommitmentData(bytes32 commitmentHash_, address committer_, uint64 revokableAt_) internal {
        bytes32 commitmentData_;

        assembly {
            commitmentData_ := shl(64, committer_)
            commitmentData_ := or(commitmentData_, revokableAt_)
        }

        layout().commitments[commitmentHash_].data = commitmentData_;
    }

    function getCommitmentData(bytes32 commitmentHash_) internal view returns (address committer_, uint64 revokableAt_) {
        bytes32 commitmentData_ = layout().commitments[commitmentHash_].data;

        assembly {
            committer_ := shr(64, commitmentData_)
            revokableAt_ := commitmentData_
        }
    }

    function deleteCommitment(bytes32 commitmentHash_) internal {
        delete layout().commitments[commitmentHash_];
    }

    function setDomainTransferFlag(address registrant_, bytes32 commitmentHash_, uint64 duration_, bool isTrader_) internal {
        layout().domainTransferFlags[registrant_][commitmentHash_] = duration_ | (isTrader_ ? 1 << 64 : 0);
    }

    function hasDomainTransferFlag(address registrant_, bytes32 commitmentHash_) internal view returns (bool) {
        (uint64 duration_, ) = getDomainTransferFlag(registrant_, commitmentHash_);
        return duration_ > 0;
    }

    function getDomainTransferFlag(address registrant_, bytes32 commitmentHash_) internal view returns (uint64, bool) {
        uint64 flag = uint64(layout().domainTransferFlags[registrant_][commitmentHash_]);
        bool isTrader = layout().domainTransferFlags[registrant_][commitmentHash_] & (1 << 64) > 0;
        return (flag, isTrader);
    }

    function deleteDomainTransferFlag(address registrant_, bytes32 commitmentHash_) internal {
        delete layout().domainTransferFlags[registrant_][commitmentHash_];
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function COMMITMENT_HALF_LIFE() internal view returns (uint64) {
        return layout().commitmentHalfLife;
    }

    function MAX_SIG_HALF_LIFE() internal view returns (uint64) {
        return layout().signatureHalfLife;
    }
}
