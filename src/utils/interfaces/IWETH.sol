// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}
