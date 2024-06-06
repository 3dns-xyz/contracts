//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {StringsUpgradeable} from "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {ICustomToken} from "src/regcontrol/interfaces/tokens/ICustomToken.sol";

import {AbstractDomainController} from "src/regcontrol/modules/types/abstracts/AbstractDomainController.sol";
import {HybridMetadataStorage} from "src/regcontrol/storage/Storage.sol";

/// Errors -------------------------------------------------------------------------------------

error HybridMetadataService__uri__tokenDoesNotExist(uint256 tokenId_);

abstract contract HybridMetadataService is ICustomToken, AbstractDomainController {
    /// Libraries ---------------------------------------------------------------------------------

    using StringsUpgradeable for uint256;

    /// Accessor Functions ---------------------------------------------------------------------

    /// @dev See {IERC721Metadata-name}.
    function name() external pure returns (string memory) {
        return HybridMetadataStorage.name();
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() external pure returns (string memory) {
        return HybridMetadataStorage.symbol();
    }

    /// Function overrides -----------------------------------------------------------------------------

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        return uri(tokenId_);
    }

    /// @dev See {IERC1155MetadataURI-URI}.
    function uri(uint256 tokenId_) public view returns (string memory) {
        if (!_tokenExists(tokenId_)) {
            revert HybridMetadataService__uri__tokenDoesNotExist(tokenId_);
        }

        (string memory fqdn_, bytes32 tld_) = _getFQDN(bytes32(tokenId_));

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                HybridMetadataStorage.base64(
                    abi.encodePacked(
                        '{"name":"',
                        fqdn_,
                        '","description":"',
                        _renderDescription(fqdn_, tld_),
                        '","traits":[],"image":"',
                        _imageUrl(tld_, bytes32(tokenId_)),
                        '"}'
                    )
                )
            )
        );
    }

    function _imageUrl(bytes32 tld_, bytes32 node_) private view returns (string memory url_) {
        return string(
            abi.encodePacked(HybridMetadataStorage.baseUrl(tld_), HybridMetadataStorage.bytes32ToHexString(node_))
        );
    }

    function _renderDescription(string memory fqdn_, bytes32 tld_) private view returns (string memory) {
        return string(abi.encodePacked(fqdn_, HybridMetadataStorage.description(tld_)));
    }

    /// Abstract Accessor Functions ===============================================================

    function _getFQDN(bytes32 node_) internal view virtual returns (string memory, bytes32);
}
