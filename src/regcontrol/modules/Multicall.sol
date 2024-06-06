// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {AddressUpgradeable} from "openzeppelin-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

import {ReentrancyGuardDiamond} from "src/utils/access/ReentrancyGuardDiamond.sol";
import {SponsorShieldDiamond} from "src/utils/access/SponsorShieldDiamond.sol";

import {IMulticall} from "src/regcontrol/interfaces/IMulticall.sol";
import {IWETH} from "src/utils/interfaces/IWETH.sol";

// import {RegControl} from "src/regcontrol/RegControl.sol";

/// Multicall ----------------------------------------------------------------------------------

contract Multicall is 
    IMulticall, 
    Initializable,
    ReentrancyGuardDiamond,
    SponsorShieldDiamond 
{

    /// @dev Disable initializers for template contracts, as they are not meant to be initialized.
    constructor(bool embed) {
        if (!embed) __Multicall_init__self();
    }

    function __Multicall_init__self() internal initializer {
        __ReentrancyGuard_init();
    }

    /// @dev Initializes the contract state.
    function __Multicall_init() internal onlyInitializing {
        __ReentrancyGuard_init();
    }

    /// @dev WETH address

    address payable private constant WETH = payable(0x4200000000000000000000000000000000000006);

    /// @dev Receives and executes a batch of function calls on this contract.
    function multicall(bytes[] calldata data) external payable override nonReentrant returns (bytes[] memory results) {
        bool hasValue_ = false;
        if (msg.value > 0) {
            // Take passed ETH and convert to WETH
            IWETH(WETH).deposit{value: msg.value}();

            hasValue_ = true;
        }

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // @audit 'delegatecall' forwards 'msg.value' 
            results[i] = AddressUpgradeable.functionDelegateCall(address(this), data[i]);
        }

        // Clear hooks
        _clearHooks();

        // Transfer any remaining WETH back to the sender
        if (hasValue_ && IWETH(WETH).balanceOf(address(this)) > 0) {
            IWETH(WETH).transfer(msg.sender, IWETH(WETH).balanceOf(address(this)));
        }

        return results;
    }

    function _clearHooks() private {
        // Clear sponsor shield hook
        _cleanupSponsorShield();
    }
}
