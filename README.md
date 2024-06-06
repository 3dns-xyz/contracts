# 3DNS Smart Contracts

**Root repo for all 3DNS related smart contracts & on-chain logic**

![Github Actions](https://github.com/0xpaulio/3dns-smart-contractss/workflows/CI/badge.svg)

## Table of Contents

- [Getting Started](#getting-started)
- [Deployments](#deployments)
  - [Assumptions](#initial-assumption)
  - [Contract Addresses](#3dns-contracts)
  - [Internal Wallets](#3dns-permissioned-wallets)
- [Development](#development)

## Getting Started

Code can be built and tested locally without an **.env** file, but to deploy or interact with any specific contracts, a permissioned user must set up the **.env** file and link their service to the internal management tool.

This project uses [Foundry](https://getfoundry.sh).

### Install foundry

See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

### Compile the code

```sh
forge build
```

### Run the tests

```sh
forge test
```

## Deployments

The deployment scripts use CREATE2 to deploy a counterfactual, 3dns access controlled factory

### Initial Assumption

```js
// Authority contract address based on manager_
contractAuthority = new ThreeDNSAuthority{
    salt: keccak256(Naming.THREE_DNS_AUTHORITY_NAME)
}(manager_);

// Factory based on authority with controller of manager_
factory = new ThreeDNSFactory{
    salt: keccak256(Naming.DEPLOYER_NAME)
}(contractAuthority);
```

### 3dns Contracts

#### Contracts

| Contract Name                  | Contract Address                           | Mainnet | Optimism | OP Testnet |
| ------------------------------ | ------------------------------------------ | :-----: | :------: | :--------: |
| ThreeDNSAuthority              | 0xe4CA879805120f1BD635d4ce5b646e308aA55fFc |   🟢   |    🟢    |     🟢     |
| ThreeDNSFactory                | 0x0AFE114C91348543844Ab790CCfA28909282f64B |   🟢   |    🟢    |     🟢     |
| ThreeDNSAdministeredProxyAdmin | 0x1a4047ad1356305dBc4810A6af1Cbe81A8603dC9 |    -    |    🟢    |     🟢     |
| ThreeDNSContractRegistry       | 0xd3077FF69621Bb880b3c2655B8b301eD767bc2bb |    -    |    🟢    |     🟢     |
| ThreeDNSRegControl             | 0xBB7B805B257d7C76CA9435B3ffe780355E4C4B17 |    -    |    🟢    |     🟢     |
| ThreeDNSResolver               | 0xF97aAc6C8dbaEBCB54ff166d79706E3AF7a813c8 |    -    |    🟢    |     🟢     |

#### Legend

| Symbol | Description |
| :----: | ----------- |
|   🟢   | Deployed    |
|   🟡   | Coming Soon |

## 3dns Permissioned Wallets

### 1. Roles and Networks

#### Role Permissions

|                    | Controller | Manager Admin | Deployment Manager | Issuer Manager | Signer Manager | Deployer | Proxy Admin | Registrar Admin | Signer | Issuer |
| ------------------ | :--------: | :-----------: | :----------------: | :------------: | :------------: | :------: | :---------: | :-------------: | :----: | :----: |
| Controller         |     🔵     |      🔴       |         🔴         |       🔴       |       🔴       |    🔴    |     🔴      |       🔴        |   🔴   |   🔴   |
| Manager Admin      |     -      |       -       |         🔴         |       🔴       |       🔴       |    🔴    |     🟡      |       🔴        |   🟡   |   🟡   |
| Deployment Manager |     -      |       -       |         -          |       -        |       -        |    🔴    |     🔴      |        -        |   -    |   -    |
| Issuer Manager     |     -      |       -       |         -          |       -        |       -        |    -     |      -      |        -        |   -    |   🔴   |
| Signer Manager     |     -      |       -       |         -          |       -        |       -        |    -     |      -      |        -        |   🔴   |   -    |

#### Legend

| Symbol | Description                                           |
| :----: | ----------------------------------------------------- |
|   🔵   | only one can exist                                    |
|   🔴   | full control (can set or remove)                      |
|   🟡   | indirect control (can set or remove that can control) |

## Development

The repo is divided into three main components: `test`, `scripts`, & `src`. All internal logic and contracts are stored and written in `src`, all tests are written in `test`, and all deployment logic and managerial scripts are written in `scripts`.

### Src - Project Structure & Key Components

### Test - Testing Structure & Philosiphy

### Scripts - Key Management Actions & Deployment Scripts
