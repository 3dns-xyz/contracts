// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {IERC165Upgradeable as IERC165} from "openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {IERC721, IERC721Metadata} from "src/regcontrol/interfaces/tokens/IERC721.sol";
import {IERC1155, IERC1155MetadataURI} from "src/regcontrol/interfaces/tokens/IERC1155.sol";

/// Internal References ---------------------------------------------------------------------------

import {ThreeDNSAccessControlled} from "src/utils/access/ThreeDNSAccessControlled.sol";

import {CustomToken} from "src/regcontrol/modules/types/custom/CustomToken.sol";
import {CustomENS} from "src/regcontrol/modules/types/custom/CustomENS.sol";

import {IDomainController} from "src/regcontrol/interfaces/IDomainController.sol";
import {IENS} from "src/regcontrol/interfaces/tokens/IENS.sol";
import {ICustomToken} from "src/regcontrol/interfaces/tokens/ICustomToken.sol";

import {RegControlStorage} from "src/regcontrol/storage/Storage.sol";

/// Errors ----------------------------------------------------------------------------------------


contract DomainController is 
    IDomainController,

    CustomToken, 
    CustomENS,
    
    ThreeDNSAccessControlled
{

    /// Management Functions ----------------------------------------------------------------------
    
    function setPrimaryResolver(address resolver_) external {
        // Run access control validation
        _callerIsOperator__validate();

        RegControlStorage.setPrimaryResolver(resolver_);
    }

    /// Shared Management Functions ---------------------------------------------------------------

    function setApprovalForAll(address operator_, bool approval) public override(IDomainController, IENS, ICustomToken) {
        // Function uses msg.sender for account indexed operations
        _setAccountOperatorApproval(operator_, approval);
    }

    function isApprovedForAll(address account_, address operator_) public view override(IDomainController, IENS, ICustomToken) returns (bool) {
        return _isApprovedAccountOperator(account_, operator_);
    }

    function tokenData(uint256 node_) external view returns (address registrant, uint32 controlBitmap, uint64 expiration) {
        return _getNodeData(bytes32(node_));
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function _tokenExists(uint256 node_) internal view override returns (bool) {
        return _getRegistrant(bytes32(node_)) != address(0x00);
    }

    /// ERC165 Functions ---------------------------------------------------------------------------

    /// @dev ERC165 introspection support.
    function supportsInterface(bytes4 interfaceId_) public view returns (bool) {
        return 
            interfaceId_ == type(IENS).interfaceId || 
            interfaceId_ == type(IERC1155).interfaceId || 
            interfaceId_ == type(IERC1155MetadataURI).interfaceId || 
            interfaceId_ == type(IERC721).interfaceId || 
            interfaceId_ == type(IERC721Metadata).interfaceId || 
            interfaceId_ == type(IERC165).interfaceId;
    }
}
