// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// External References ---------------------------------------------------------------------------

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// Internal References ---------------------------------------------------------------------------

import {IRegistrarController} from "src/regcontrol/interfaces/IRegistrarController.sol";

// import {AbstractAccessControlled} from "src/utils/access/abstracts/AbstractAccessControlled.sol";

import {ThreeDNSAccessControlled} from "src/utils/access/ThreeDNSAccessControlled.sol";
import {IThreeDNSAuthority} from "src/utils/access/interfaces/IThreeDNSAuthority.sol";

import {Registry} from "src/regcontrol/modules/types/Registry.sol";

import {RegistryStorage, RegistrarStorage, PaymentStorage} from "src/regcontrol/storage/Storage.sol";
import {Datastructures} from "src/regcontrol/storage/Datastructures.sol";
import {HybridMetadataStorage} from "src/regcontrol/storage/Storage.sol";

/// Errors ----------------------------------------------------------------------------------------

error RegistrarController_accessDenied();
error RegistrarController_tldExists();
error RegistrarController_tldDoesntExist();
error RegistrarController_invalidLabel(bytes label);

/// Contract --------------------------------------------------------------------------------------
contract RegistrarController is
    IRegistrarController,

    Initializable,
    ThreeDNSAccessControlled,
    Registry
{
    
    constructor(IThreeDNSAuthority _authority) initializer {
        ThreeDNSAccessControlled.__ThreeDNSAccessControlled_init(_authority);
    }    

    /// Management Functions ----------------------------------------------------------------------

    function registerTLD(bytes calldata tld_) external {
        // Run access control check
        _callerIsRegistrarAdmin__validate();

        // Validate & register the tld
        _registerTLD(tld_);
    }

    function setTLDMetadata(bytes32 tld_, string calldata baseUrl_, string calldata description_) external {
        // Run access control check
        _callerIsRegistrarAdmin__validate();

        // Validate tld is registered
        if (tld_ != bytes32(0) && !_isRegisteredTLD(tld_))
            revert RegistrarController_tldDoesntExist();
            
        // Set the metadata
        HybridMetadataStorage.setMetadata(tld_, baseUrl_, description_);
    }

    // TODO: Add updateTLD and disableTLD functions

    /// Inforcement Functions ---------------------------------------------------------------------

    event UDRPDecision(bytes32 indexed node, address recipient, string caseLink);

    function processUDRPdecision(bytes32 node_, address recipient_, string memory caseLink_) external {
        // Run access control check
        _callerIsRegistrarAdmin__validate();

        // If recipient address is 0, burn the domain
        if (recipient_ == address(0)) {
            // Burn the domain
            _burnRegistration(node_);
        } else {
            // Transfer the domain to the recipient
            _transferRegistration(node_, recipient_);
        }

        emit UDRPDecision(node_, recipient_, caseLink_);
    }

    function lockRegistration(bytes32 node_, uint64 duration_) external {
        // Run access control check
        _callerIsRegistrarAdmin__validate();

        // Lock the domain
        _lockRegistration(node_, duration_);
    }

    function unlockRegistration(bytes32 node_) external {
        // Run access control check
        _callerIsRegistrarAdmin__validate();

        // Unlock the domain
        _removeRegistrationLock(node_);
    }

    /// Accessor Functions ------------------------------------------------------------------------

    function getTLDData(bytes32 tld_) external view returns (bool enabled_) {
        // Return the tld data
        return _isRegisteredTLD(tld_);
    }

    function getTLDMetadata(bytes32 tld_) external view returns (string memory baseUrl_, string memory description_) {
        // Validate tld is registered
        if (!_isRegisteredTLD(tld_)) 
            revert RegistrarController_tldExists();

        return HybridMetadataStorage.getMetadata(tld_);
    }

    /// Internal Helper Functions -----------------------------------------------------------------

    function _registerTLD(bytes calldata tld_) internal {
        // Validate the tld & accessory data
        bytes32 node_ = _tld__prepare(tld_);

        // Validate uniqueness and register the tld
        _tld__register(tld_, node_);

        // Emit events //

        // ERC721 Event
        emit Transfer(address(0x00), address(this), uint256(node_));

        // ERC1155 Event
        emit TransferSingle(msg.sender, address(0x00), address(this), uint256(node_), 1);

        // ENS Event
        emit NewOwner(bytes32(0x00), keccak256(tld_), address(this));
        emit Transfer(node_, address(this));
    }
    
    /// Validation Functions ----------------------------------------------------------------------

    function _tld__prepare(bytes calldata tld_) internal pure returns (bytes32 node_) {
        // Validate the tld
        if (!_isValidTLDLabel(tld_)) {
            revert RegistrarController_invalidLabel(tld_);
        }

        // Calculate node
        node_ = _calculateNode(tld_, bytes32(0));

        // TODO: Add additional state specific validations

        // Return the node
        return node_;
    }

    /// Private State Management Functions --------------------------------------------------------

    function _tld__register(bytes calldata label_, bytes32 node_) private {
        // Validate tld is not already registered
        if (_isRegisteredTLD(node_)) 
            revert RegistrarController_tldExists();

        /// @dev Registry Storage
        // Store node in root registry with a parent of 0x00

        // Initialize the record data
        // Set the registrant as self and the expiration to max uint64
        RegistryStorage.createNewRecord(node_, address(this), 0, ~uint64(0));

        // Track the ownership
        RegistryStorage.trackNewOwnership(node_, address(this));

        // Build a reverse record mapping for the tld to the root label
        RegistryStorage.trackReverseRecord(bytes32(0x00), label_);

        /// @dev Registrar Storage
        // Register the tld in the registrar
        RegistrarStorage.registerTLD(node_);
    }

    /// Validation Helper Functions ---------------------------------------------------------------

    function _isRegisteredTLD(bytes32 node_) internal view returns (bool) {
        (bool enabled) = RegistrarStorage.getTLDData(node_);
        return enabled;
    }

    function _isValidTLDLabel(bytes calldata label_) internal pure returns (bool) {
        // Check if label is less than 2 or exceeds 18 characters
        if (label_.length < 0x02 || label_.length > 0x12) return false;

        // Check if label contains invalid characters
        for (uint256 i = 0; i < label_.length; i++) {
            bytes1 char_ = label_[i];

            // Ensure alphanumeric.
            if (!(char_ >= 0x61 && char_ <= 0x7A)) {
                return false;
            }
        }
        return true;
    }

    /// Access Control Functions ------------------------------------------------------------------

    function _callerIsRegistrarAdmin__validate() internal view {
        if (!_isValidRegistrarAdmin(msg.sender)) {
            revert RegistrarController_accessDenied();
        }
    }

    /// Administrative Action Validators ----------------------------------------------------------

    function _isValidRegistrarAdmin(address sender_) internal view returns (bool) {
        return authority().isRole(authority().ROLE__REGISTRAR_ADMIN(), sender_);
    }
}
