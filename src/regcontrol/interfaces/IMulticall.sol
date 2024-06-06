// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {AddressUpgradeable} from "openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

import {IWETH} from "src/utils/interfaces/IWETH.sol";

/// Multicall ----------------------------------------------------------------------------------

interface IMulticall {
    /// @dev Receives and executes a batch of function calls on this contract. Payable. All ETH 
    ///  paid via msg.value is wrapped to WETH and used to execute the function calls. Any 
    ///  remaining WETH is returned to the sender.
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}
