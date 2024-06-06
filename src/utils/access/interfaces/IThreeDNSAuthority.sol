// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;

interface IThreeDNSAuthority {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event raised when a new gateway URL is set.
    event OperatorChanged(address previousOperator, address newOperator);

    event RoleAdded(bytes32 indexed role, address indexed manager);
    event RoleRemoved(bytes32 indexed role, address indexed manager);

    /*//////////////////////////////////////////////////////////////
                    External Administration Functions
    //////////////////////////////////////////////////////////////*/

    function setRole(bytes32 _role, address _sender) external;
    function removeRole(bytes32 _role, address _sender) external;
    function isRole(bytes32 _role, address _sender) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    function operator() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Super Admin
    function ROLE__OPERATOR() external view returns (bytes32);

    /// @dev Management Admin
    function ROLE__MANAGER_ADMIN() external view returns (bytes32);

    /// @dev Management roles
    function ROLE__DEPLOYMENT_MANAGER() external view returns (bytes32);
    function ROLE__SIGNER_MANAGER() external view returns (bytes32);
    function ROLE__ISSUER_MANAGER() external view returns (bytes32);

    /// @dev Auditor roles
    function ROLE__AUDITOR() external view returns (bytes32);

    /// @dev Constant specifing action specific roles
    function ROLE__DEPLOYER() external view returns (bytes32);
    function ROLE__PROXY_ADMIN() external view returns (bytes32);
    function ROLE__REGISTRAR_ADMIN() external view returns (bytes32);
    function ROLE__SIGNER() external view returns (bytes32);
    function ROLE__ISSUER() external view returns (bytes32);
}
