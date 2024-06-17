// SPDX-License-Identifier: BUSL-1.1D
pragma solidity ~0.8.17;

import "forge-std/Test.sol";

import {ProxyAdmin} from "openzeppelin-not-upgradeable/proxy/transparent/ProxyAdmin.sol";

import "./Utils.sol";

contract BaseTest is Test {
    Utils public utils;

    // Core wallets
    address public operator;
    address public adminManager;

    // Managers
    address public deploymentManager;
    address public signerManager;
    address public issuerManager;

    // Auditor
    address public auditor;

    // Services
    address public signatureService;
    address public xactService;

    // Deployers
    address public deployer;

    // Registrar Admin
    address public registrarAdmin;

    // Users & non permissioned addresses
    address public alice;
    address public bob;
    address public chris;
    address public derek;

    modifier prankCalls(address _caller) {
        vm.startPrank(_caller);
        _;
        vm.stopPrank();
    }
    
    function setUp() public virtual {
        utils = new Utils();

        // Core wallets
        operator = 0x03F0FA2eB61E913421368203d595Afec7091f269;
        vm.label(operator, "operator");
        adminManager = 0xBBa294D303555032C6BD1021C639654b95e77Fa8;
        vm.label(adminManager, "adminManager");

        // Managers
        deploymentManager = utils.initializeAccount("deploymentManager");
        signerManager = utils.initializeAccount("signerManager");
        issuerManager = utils.initializeAccount("issuerManager");

        // Auditor
        auditor = utils.initializeAccount("auditor");

        // Admin
        registrarAdmin = utils.initializeAccount("registrarAdmin");

        // Services
        signatureService = utils.initializeAccount("signatureService");
        xactService = utils.initializeAccount("xactService");

        // Deployers
        deployer = 0xf2738FdF1837Fea87B7e995b771505E914220f71;
        vm.label(deployer, "deployer");

        // Users & non permissioned addresses
        alice = utils.initializeAccount("alice");
        bob = utils.initializeAccount("bob");
        chris = utils.initializeAccount("chris");
        derek = utils.initializeAccount("derek");
    }

    address constant PROXY_ADDRESS = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function deployContract_create2(bytes32 salt, bytes memory initCode) public {
        (bool success,) = PROXY_ADDRESS.call(abi.encodePacked(salt, initCode));
        require(success, "Deployment via Proxy failed");
    }

    function _calculateNode(bytes32 labelHash_, bytes32 parent_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent_, labelHash_));
    }
}
