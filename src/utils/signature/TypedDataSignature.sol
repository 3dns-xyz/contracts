// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {BaseSignature} from "src/utils/signature/BaseSignature.sol";

abstract contract TypedDataSignature is Initializable, BaseSignature {

    function signatureType() public override pure returns (string memory) {
        return "EIP712";
    }
    
    /// Domain Variables --------------------------------------------------------------------------

    /// @dev Internal variable calculated from the domain name, version, chainId, and contract address.
    bytes32 public DOMAIN_SEPARATOR;

    /// @dev Internal variable specifing the domain name of the 712 typed signature.
    string public DOMAIN_NAME;
    /// @dev Internal variable specifing the version of the 712 typed signature.
    string public DOMAIN_VERSION;
    /// @dev Internal variable specifing the chainId of the 712 typed signature.
    uint64 public CHAIN_ID;


    function TYPED_DATA_SIGNATURE_TYPEHASH() external view virtual returns (bytes32);

    /// Initializer ----------------------------------------------------------------------------

    /// @dev Initializes an internal helper contract used for verifying 712 typed signatures.
    function __TypedDataSignature_init(
        string memory domainName_,
        string memory domainVersion_,
        uint64 chainId_
    ) internal onlyInitializing {
        DOMAIN_NAME = domainName_;
        DOMAIN_VERSION = domainVersion_;
        CHAIN_ID = chainId_;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint64 chainId,address verifyingContract)"
                ),
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                CHAIN_ID,
                address(this)
            )
        );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function _calculateDigest(
        bytes memory data_
    ) internal view override returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01", 
                    DOMAIN_SEPARATOR, 
                    _calculateTypeHash(data_)
                )
            );
    }

    /// Abstract Function Declarations ============================================================
    
    function _calculateTypeHash(bytes memory data_) internal view virtual returns (bytes32);
}
