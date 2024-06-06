// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// Errors ---------------------------------------------------------------------------------

error InvalidPayload();
error InvalidSignature();

abstract contract BaseSignature {

    /// Functions ------------------------------------------------------------------------------

    function signatureType() public virtual pure returns (string memory) {
        return "EIP191";
    }

    function _validateSignature(
        bytes memory data_,
        uint8 v_, bytes32 r_, bytes32 s_
    ) internal view {
        // Verify payload
        if (!_validPayload(data_))
            revert InvalidPayload();

        address signer_ = ecrecover(
            _calculateDigest(data_), 
            v_, r_, s_
        );

        if (
            signer_ == address(0) || 
            !_isValidSigner(signer_)
        ) revert InvalidSignature();
    }

    /// Abstract Function Declarations ============================================================
    
    function _validPayload(bytes memory data_) internal view virtual returns (bool);

    function _calculateDigest(bytes memory data_) internal view virtual returns (bytes32);

    function _isValidSigner(address signer) internal view virtual returns (bool);
}
