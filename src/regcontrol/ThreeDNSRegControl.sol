// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {IThreeDNSAuthority} from "src/utils/access/interfaces/IThreeDNSAuthority.sol";
import {ThreeDNSAccessControlled} from "src/utils/access/ThreeDNSAccessControlled.sol";

import {CommitmentOrderflow} from "src/regcontrol/modules/CommitmentOrderflow.sol";
import {DomainController} from "src/regcontrol/modules/DomainController.sol";
import {PaymentProcessor} from "src/regcontrol/modules/PaymentProcessor.sol";
import {RegistrarController} from "src/regcontrol/modules/RegistrarController.sol";

import {Multicall} from "src/regcontrol/modules/Multicall.sol";

import {RegControlStorage} from "src/regcontrol/storage/Storage.sol";
import {ReentrancyGuardStorage} from "src/utils/access/storage/ReentrancyGuardStorage.sol";

/// Diamond Params --------------------------------------------------------------------------------

import {IDiamondCut} from "src/regcontrol/interfaces/diamond/IDiamondCut.sol";
import {LibDiamond} from "src/regcontrol/libraries/LibDiamond.sol";

/// Errors ----------------------------------------------------------------------------------------

error ThreeDNSRegControl_accessDenied();

contract ThreeDNSRegControl is
    Initializable,
    ThreeDNSAccessControlled
    // CommitmentOrderflow              -> Moved into diamond facets
    // CommitmentOrderflowExtensions    -> Moved into diamond facets
    // DomainController                 -> Moved into diamond facets
    // RegistrarController,             -> Moved into diamond facets
    // Multicall                        -> Moved into diamond facets
{

    /// Initialization Functions ------------------------------------------------------------------

    /// @dev Disable initializers for template contracts, as they are not meant to be initialized.
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        IThreeDNSAuthority _authority,
        address resolver_,
        string memory domainName_,
        string memory domainVersion_,
        uint64 chainId_,
        IERC20 usdc_
    ) public initializer {
        ThreeDNSAccessControlled.__ThreeDNSAccessControlled_init(_authority);

        // Moved into diamond facets
        // CommitmentOrderflow.__CommitmentOrderflow_init(domainName_, domainVersion_, chainId_, usdc_);

        ReentrancyGuardStorage.initialize();
        RegControlStorage.setPrimaryResolver(resolver_);
    }

    /// @note Have done 5 initializations
    //   next -> function initializeV6(...) public reinitializer(5) { }

    /// Diamond Fallback Functions ----------------------------------------------------------------

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        // require(msg.sender == address(WETH));
    }
    
    /// Diamond Management Functions --------------------------------------------------------------

    function diamondCut(IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external {
        _callerIsProxyAdmin__validate();

        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    function trackInterface(bytes4 interfaceId_, bool enabled_) external {
        // Run access control validation
        _callerIsProxyAdmin__validate();

        // Track interface
        LibDiamond.diamondStorage().supportedInterfaces[interfaceId_] = enabled_;
    }

    /// ERC165 Functions --------------------------------------------------------------------------

    /// @dev ERC165 introspection support.
    function supportsInterface(bytes4 interfaceId_) public view returns (bool) {
        return LibDiamond.diamondStorage().supportedInterfaces[interfaceId_];
    }

    /// Access Control Functions ------------------------------------------------------------------

    function _callerIsProxyAdmin__validate() internal view {
        if (!authority().isRole(authority().ROLE__PROXY_ADMIN(), msg.sender)) {
            revert ThreeDNSRegControl_accessDenied();
        }
    }
}
