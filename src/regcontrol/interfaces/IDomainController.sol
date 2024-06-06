// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Internal References ---------------------------------------------------------------------------

import {IENS} from "src/regcontrol/interfaces/tokens/IENS.sol";
import {ICustomToken} from "src/regcontrol/interfaces/tokens/ICustomToken.sol";

interface IDomainController is 
    IENS,
    ICustomToken
{
    function setApprovalForAll(address operator_, bool approved_) external override(IENS, ICustomToken);

    function isApprovedForAll(address account_, address operator_)
        external
        view
        override(IENS, ICustomToken)
        returns (bool);
}
