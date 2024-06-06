// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IThreeDNSAuthority} from "./IThreeDNSAuthority.sol";

interface IThreeDNSAccessControlled {
  event AuthorityChanged(IThreeDNSAuthority indexed previousAuthority, IThreeDNSAuthority indexed newAuthority);

  function authority() external view returns (IThreeDNSAuthority);
  function changeAuthority(IThreeDNSAuthority _newAuthority) external;
}