// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {IERC721, IERC721Metadata} from "src/regcontrol/interfaces/tokens/IERC721.sol";
import {IERC1155, IERC1155MetadataURI} from "src/regcontrol/interfaces/tokens/IERC1155.sol";

interface ICustomToken is IERC721Metadata, IERC1155MetadataURI {
    /// Shared Function Overrides -----------------------------------------------------------------

    function setApprovalForAll(address operator_, bool approved_) external override(IERC721, IERC1155);

    function isApprovedForAll(address account_, address operator_)
        external
        view
        override(IERC721, IERC1155)
        returns (bool);

    /// ERC-1155 Compliance -----------------------------------------------------------------------

    function uri(uint256 tokenId) external view returns (string memory);
    
}
