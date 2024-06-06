// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// Internal References ---------------------------------------------------------------------------

import {AbstractAccessControlled} from "src/utils/access/abstracts/AbstractAccessControlled.sol";

abstract contract AbstractDomainController /* is AbstractAccessControlled */ {
    /// Accessor Functions ------------------------------------------------------------------------

    function _tokenExists(uint256 node_) internal view virtual returns (bool);


    // function _callerIsMetadataAdmin__validate() internal view virtual;
}
