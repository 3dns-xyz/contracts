// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IRegistrarController {

    /// Registration Functions --------------------------------------------------------------------

    function registerTLD(bytes calldata tld_) external;
    function setTLDMetadata(bytes32 tld_, string calldata baseUrl_, string calldata description_) external;

    // TODO: Add updateTLD and disableTLD functions

    /// Accessor Functions ------------------------------------------------------------------------

    
}
