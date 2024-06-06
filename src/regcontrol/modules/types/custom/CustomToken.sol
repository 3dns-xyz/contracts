// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {ICustomToken} from "src/regcontrol/interfaces/tokens/ICustomToken.sol";

import {IERC721, IERC721Receiver} from "src/regcontrol/interfaces/tokens/IERC721.sol";
import {IERC1155, IERC1155MetadataURI, IERC1155Receiver} from "src/regcontrol/interfaces/tokens/IERC1155.sol";

import {IIAM} from "src/regcontrol/interfaces/IIAM.sol";

import {HybridMetadataService} from "src/regcontrol/modules/types/metadata/HybridMetadataService.sol";

import {Registry} from "src/regcontrol/modules/types/Registry.sol";
import {AccessManagement} from "src/regcontrol/modules/types/AccessManagement.sol";

import {AddressUpgradeable} from "openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

/// Errors -------------------------------------------------------------------------------------

error CustomToken_ArrayLengthMismatch();
error CustomToken_InsufficientBalance();

error CustomToken_SenderNotOwnerOrOperator();

error CustomToken_ZeroAddress();
error CustomToken_InvalidAddress();

error CustomToken_ERC721ReceiverRejectedTokens();
error CustomToken_ERC1155ReceiverRejectedTokens();
error CustomToken_NotTokenReceiver();

abstract contract CustomToken is
    ICustomToken,
    AccessManagement,
    Registry,
    HybridMetadataService
{
    /// Libraries ---------------------------------------------------------------------------------

    using AddressUpgradeable for address;

    /// Accessor Functions ------------------------------------------------------------------------

    function _getFQDN(bytes32 node_) internal view override returns (string memory fqdn_, bytes32 tld_) {
        if (node_ == bytes32(0x00)) {
            return ("", bytes32(0x00));
        }

        (fqdn_, tld_) = _getFQDN(_getParent(node_));
        if (tld_ == bytes32(0x00)) {
            tld_ = _getParent(node_);
        }

        if (bytes(fqdn_).length == 0) {
            fqdn_ = string(_getLabel(node_));
        } else {
            fqdn_ = string(abi.encodePacked(_getLabel(node_), ".", fqdn_));
        }

        return (fqdn_, tld_);
    }

    /// Approval Functions ------------------------------------------------------------------------

    function approve(address to, uint256 tokenId) external override {
        // Validate caller has permission to approve the operator
        if (!_permissionCheck_registration(bytes32(tokenId), msg.sender, IIAM.IAMRole.ADMIN, IIAM.IAMPermission.MANAGE)) {
            revert CustomToken_SenderNotOwnerOrOperator();
        }

        // Function uses msg.sender for account indexed operations
        _setRegistrationApproval(bytes32(tokenId), to);
    }

    function getApproved(uint256 tokenId) external view returns (address operator) {
        if ((operator = ownerOf(tokenId)) == address(0)) {
            revert CustomToken_ZeroAddress();
        }
        return _getApprovedRegistrationOperator(bytes32(tokenId));
    }

    /// ERC721 ------------------------------------------------------------------------------------

    function totalSupply() external view returns (uint256) {
        return _getRecordCount();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _getRegistrant(bytes32(tokenId));
    }

    function balanceOf(address owner_) external view returns (uint256) {
        if (owner_ == address(0)) {
            revert CustomToken_ZeroAddress();
        }
        return _getDomainNameOwnershipCount(owner_);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) external override {
        // Run access control check
        _transfer__validate(from_, to_, tokenId_, 1);

        // Execute the transfer
        _transfer__execute(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) external override {
        // Run access control check
        _transfer__validate(from_, to_, tokenId_, 1);

        // Execute the transfer
        _transfer__execute(from_, to_, tokenId_);

        // Run the callback
        _transfer__callback(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) external override {
        // Run access control check
        _transfer__validate(from_, to_, tokenId_, 1);

        // Execute the transfer
        _transfer__execute(from_, to_, tokenId_);

        // Run the callback
        _transfer__callback(from_, to_, tokenId_, "");
    }

    /// ERC1155 Methods ---------------------------------------------------------------------------

    /// @dev See {IERC1155-balanceOf}.
    function balanceOf(address account_, uint256 id_) public view virtual override returns (uint256) {
        if (account_ == address(0)) {
            revert CustomToken_ZeroAddress();
        }
        return account_ == ownerOf(id_) ? 1 : 0;
    }

    /// @dev See {IERC1155-balanceOfBatch}.
    function balanceOfBatch(address[] calldata accounts_, uint256[] calldata ids_)
        public
        view
        virtual
        override
        returns (uint256[] memory balances_)
    {
        if (accounts_.length != ids_.length) {
            revert CustomToken_ArrayLengthMismatch();
        }

        balances_ = new uint256[](accounts_.length);
        for (uint256 i = 0; i < accounts_.length; ++i) {
            balances_[i] = balanceOf(accounts_[i], ids_[i]);
        }
    }

    /// @dev See {IERC1155-safeTransferFrom}.
    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes calldata data_)
        public
        virtual
        override
    {
        _transfer__validate(from_, to_, id_, amount_);
        _transfer__execute(from_, to_, id_);
        _transfer__callback(from_, to_, id_, data_);
    }

    /// @dev See {IERC1155-safeBatchTransferFrom_}.
    function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) public virtual override {
        if (ids_.length != amounts_.length) {
            revert CustomToken_ArrayLengthMismatch();
        }

        uint256 index_ = 0;
        for (; index_ < ids_.length; ++index_) {
            uint256 id_ = ids_[index_];

            // Validate the transfer
            _transfer__validate(from_, to_, id_, amounts_[index_]);

            // Execute the transfer
            _transfer__execute(from_, to_, id_);
        }

        // emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from_, to_, ids_, amounts_, data_);
    }

    /// Transfer Functions ------------------------------------------------------------------------

    function _transfer__validate(address from_, address to_, uint256 id_, uint256 amount_) internal view virtual {
        if (from_ == address(0) || to_ == address(0)) {
            revert CustomToken_ZeroAddress();
        }
        if (amount_ != 1) {
            revert CustomToken_ArrayLengthMismatch();
        }
        if (from_ != _getRegistrant(bytes32(id_))) {
            revert CustomToken_InsufficientBalance();
        }

        // Caller is node operator
        if(!_permissionCheck_registration(bytes32(id_), msg.sender, IIAM.IAMRole.ADMIN, IIAM.IAMPermission.MANAGE)) {
            revert CustomToken_SenderNotOwnerOrOperator();
        }
    }

    function _transfer__execute(address from_, address to_, uint256 id_) internal {
        if (from_ == to_) {
            return;
        }

        // TODO: Determine if other checks are needed
        _transferRegistration(bytes32(id_), to_);
    }

    /// @dev internal helper function for transfering a node
    function _transfer__callback(address from_, address to_, uint256 id_, bytes memory data_) internal {
        _doSafeTransferAcceptanceCheck(msg.sender, from_, to_, id_, 1, data_);
    }

    /// Internal Helper Functions =================================================================

    /// @dev internal helper function for performing a post transfer check on non-EOA receivers.
    function _doSafeTransferAcceptanceCheck(
        address operator_,
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) private {
        if (to_.isContract()) {
            /* ERC1155 handling */
            (bool success1, bytes memory data1) = to_.call(abi.encodeCall(IERC1155Receiver.onERC1155Received, (operator_, from_, id_, amount_, data_)));
            if (success1 && data1.length != 0) {  // success AND has return data -> check return data, expect it to have 4 bytes
                if (abi.decode(data1, (bytes4)) != IERC1155Receiver.onERC1155Received.selector) {
                    revert CustomToken_ERC1155ReceiverRejectedTokens();
                }
            } else { // failure OR no return data: fallback OR low-level failure (without error message) OR high-level error message
                /* ERC721 handling */
                (bool success2, bytes memory data2) = to_.call(abi.encodeCall(IERC721Receiver.onERC721Received, (operator_, from_, id_, data_)));
                if (data2.length != 0) { // has return data
                    if (success2) { // success -> check return data, expect it to have 4 bytes
                        if (abi.decode(data2, (bytes4)) != IERC721Receiver.onERC721Received.selector) {
                            revert CustomToken_ERC721ReceiverRejectedTokens();
                        }
                    }
                    else { // failure -> forward error message
                        /// @solidity memory-safe-assembly
                        assembly {
                            revert(add(32, data2), mload(data2))
                        }
                    }
                } else  { // no return data: failure without error message -> forward previous error message
                    if (data1.length != 0) {
                        /// @solidity memory-safe-assembly
                        assembly {
                            revert(add(32, data1), mload(data1))
                        }
                    }
                    else {
                        revert CustomToken_NotTokenReceiver();
                    }
                }
            }
        }
    }

    /// @dev internal helper function for performing a post batch-transfer check on non-EOA receivers.
    function _doSafeBatchTransferAcceptanceCheck(
        address operator_,
        address from,
        address to_,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data_
    ) private {
        if (to_.isContract()) {
            try IERC1155Receiver(to_).onERC1155BatchReceived(operator_, from, ids, amounts, data_) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to_).onERC1155BatchReceived.selector) {
                    revert CustomToken_ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert CustomToken_NotTokenReceiver();
            }
        }
    }
}
