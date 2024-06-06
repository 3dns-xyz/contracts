// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/// Internal References ---------------------------------------------------------------------------

// import {IThreeDNSAccessControlled} from "./interfaces/IThreeDNSAccessControlled.sol";
import {IThreeDNSAuthority} from "./interfaces/IThreeDNSAuthority.sol";
import {IThreeDNSAccessControlled} from "./interfaces/IThreeDNSAccessControlled.sol";

import {
    AccessControlledStorage as Storage
} from "./storage/AccessControlledStorage.sol";

/// Errors ---------------------------------------------------------------------------

error ThreeDNSAccessControlled_unauthorized(address);
error ThreeDNSAccessControlled_invalidAuthority();

contract ThreeDNSAccessControlled is 
    Initializable,
    IThreeDNSAccessControlled
{
    /// Modifiers ------------------------------------------------------------------------------

    modifier onlyOperator() {
        _callerIsOperator__validate();
        _;
    }

    /// @dev Included in AccessControlEnumerable
    // modifier onlyRole(bytes32 _role)

    /// Initializer ----------------------------------------------------------------------------

    function __ThreeDNSAccessControlled_init(IThreeDNSAuthority _newAuthority) internal onlyInitializing {
        // Set the authority
        _changeAuthority(_newAuthority);
    }

    /// Accessor Function -------------------------------------------------------------------------

    function authority() 
    public view 
    override 
    returns (IThreeDNSAuthority) 
    {
        return Storage.authority();
    }

    /// External Admin Functions ==================================================================

    function changeAuthority(IThreeDNSAuthority _newAuthority) external override onlyOperator {
        _changeAuthority(_newAuthority);
    }

    /// Internal Admin Functions ==================================================================

    function _setInitialAuthority(IThreeDNSAuthority _newAuthority) internal {
        if (address(Storage.authority()) != address(0)) 
            revert ThreeDNSAccessControlled_invalidAuthority();
        _changeAuthority(_newAuthority);
    }

    /// Private Admin Functions -------------------------------------------------------------------
    
    function _changeAuthority(IThreeDNSAuthority _newAuthority) private {
        if (address(_newAuthority) == address(0)) 
            revert ThreeDNSAccessControlled_invalidAuthority();

        // Get the current authority contract
        IThreeDNSAuthority _oldAuthority = Storage.authority();

        // Set the new authority contract
        Storage.changeAuthority(_newAuthority);

        // Log the mutation
        emit AuthorityChanged(_oldAuthority, _newAuthority);
    }

    /// Access Control Functions ==================================================================

    function _callerIsOperator__validate() internal view {
        if (!_isOperator()) 
            revert ThreeDNSAccessControlled_unauthorized(msg.sender);
    }

    /// Administrative Action Validators ==========================================================

    function _isOperator() internal view returns (bool) {
        return Storage.authority().operator() == msg.sender;
    }
}