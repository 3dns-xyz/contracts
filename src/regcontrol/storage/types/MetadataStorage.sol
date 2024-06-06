// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import { LeadingHashStorage } from "src/utils/storage/LeadingHashStorage.sol";

library MetadataStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the payment state
    bytes32 public constant THREE_DNS__BASIC_METADATA_STORAGE__V1 = keccak256("3dns.nft.metadata.basic.v1.state");

    /// Datastructures ----------------------------------------------------------------------------
    
    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns token metadata.
    struct Layout {
        string baseUri;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__BASIC_METADATA_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    function initialize(string memory _baseUri) internal {
        layout().baseUri = _baseUri;
    }

    /// Shared Helper Functions -------------------------------------------------------------------

    /// Accessor Functions ------------------------------------------------------------------------

    function baseURI() internal view returns (string memory) {
        return layout().baseUri;
    }

    function setBaseURI(string memory _baseUri) internal {
        layout().baseUri = _baseUri;
    }
}