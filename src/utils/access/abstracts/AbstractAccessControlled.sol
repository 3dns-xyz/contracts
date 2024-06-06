// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// Internal References ---------------------------------------------------------------------------

import {IThreeDNSAccessControlled} from "../interfaces/IThreeDNSAccessControlled.sol";
import {IThreeDNSAuthority} from "../interfaces/IThreeDNSAuthority.sol";

abstract contract AbstractAccessControlled is IThreeDNSAccessControlled {

    /// Abstract Authority Accessor ===============================================================

    function authority() public view virtual returns (IThreeDNSAuthority);

    /// Access Control Functions ==================================================================

    function _callerIsOperator__validate() internal view virtual;
    
}
