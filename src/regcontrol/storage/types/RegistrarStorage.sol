// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library RegistrarStorage {
    /// SLO Offsets -------------------------------------------------------------------------------

    /// @dev Constant specifing the storage location of the registry state
    bytes32 public constant THREE_DNS__REGISTRAR_STORAGE__V1 = keccak256("3dns.reg_control.registrar.v1.state");

    /// Datastructures ----------------------------------------------------------------------------

    /// @dev Struct used to define a record, the base notion of ownership for a zone (primary/apex domain name).
    struct TopLevelDomain {
        // 32 Bytes Packed Data
        // | address  |   uint64   |            bytes4             |
        // |  x[20]   |    x[8]    |      x[3]      | Enabled Flag |
        // | IPremium | Base Price | Accessory Data + Enabled Flag |
        bytes32 data;
    }

    /// Contract State ----------------------------------------------------------------------------

    /// @dev Struct used to define the state variables for the 3dns registry.
    struct Layout {
        /// @param tlds Mapping of node to TopLevelDomain definition.
        mapping(bytes32 => TopLevelDomain) tlds;
        /// @param domainLocks Mapping of domain to 32 byte slot
        /// | uint192 |        uint64       |
        /// |   ...   | settlementTimestamp |
        mapping(bytes32 => bytes32) domainLocks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = THREE_DNS__REGISTRAR_STORAGE__V1;

        /// @solidity memory-safe-assembly
        assembly {
            l.slot := slot
        }
    }

    /// State Management Functions ----------------------------------------------------------------

    /// TLD Actions ///

    function registerTLD(bytes32 tld) internal {
        bytes32 data_ = bytes32(uint256(1));
        return _registerTLD(layout().tlds[tld], data_);
    }

    function getTLDData(bytes32 tld) internal view returns (bool enabled) {
        return _getTLDData(layout().tlds[tld]);
    }

    function disableTLD(bytes32 tld) internal {
        return _disableTLD(layout().tlds[tld]);
    }

    /// DomainLocks Actions ///

    function getDomainLockData(bytes32 node_) internal view returns (uint64 settlementTimestamp) {
        return _getDomainLockData(layout().domainLocks[node_]);
    }

    function setDomainLockData(bytes32 node_, uint64 settlementTimestamp) internal {
        _setDomainLockData(node_, settlementTimestamp);
    }

    /// Attribute Specific Helper Functions -------------------------------------------------------

    /// TLD Actions ///

    function _registerTLD(TopLevelDomain storage tld_, bytes32 data_) private {
        tld_.data = data_;
    }

    function _getTLDData(TopLevelDomain storage tld_) private view returns (bool enabled_) {
        bytes32 data_ = tld_.data;

        assembly {
            enabled_ := shr(7, shl(255, data_))
        }

        return enabled_;
    }

    function _disableTLD(TopLevelDomain storage tld_) private {
        tld_.data = tld_.data & ~bytes32(uint256(1));
    }

    /// DomainLocks Actions ///

    function _getDomainLockData(bytes32 domainLock_) private pure returns (uint64 settlementTimestamp) {
        assembly {
            settlementTimestamp := shr(192, domainLock_)
        }
    }

    function _setDomainLockData(bytes32 node_, uint64 settlementTimestamp_) private {
        bytes32 data_;
        assembly {
            data_ := shl(192, settlementTimestamp_)
        }
        layout().domainLocks[node_] = data_;
    }
}
