// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// Errors -------------------------------------------------------------------------------------

error BaseRegControl_nodeDoesNotExist(bytes32 node_);
error BaseRegControl_nodeExpired(bytes32 node_);
error BaseRegControl_nodeNotTransferable(bytes32 node_);
error BaseRegControl_nodeHasSubdomains(bytes32 node_);

error BaseRegControl_invalidTLD(bytes32 tld_);
error BaseRegControl_invalidLabel(bytes label_);
error BaseRegControl_subdomainUnavailable(bytes label_, bytes32 parent_);

error BaseRegControl_invalidDuration(uint64 duration_);
error BaseRegControl_invalidDurationExtension(uint64 duration_);
error BaseRegControl_invalidRegistrant(address registrant_);

error BaseRegControl_invalidOperator(address operator_);
error BaseRegControl_operatorStateUnchanged(address operator_, bool approved_);
error BaseRegControl_registrantNotCurrent(bytes32 node_, address registrant_);

error BaseRegControl_invalidPermission();

error BaseRegControl_notImplemented();
