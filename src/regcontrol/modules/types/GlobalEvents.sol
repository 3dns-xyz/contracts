// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

contract GlobalEvents {

    /// ERC721 ---------------------------------------------------------------------------------

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// ERC1155 --------------------------------------------------------------------------------

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    // /**
    // * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
    // * transfers.
    // */
    // event TransferBatch(
    //     address indexed operator,
    //     address indexed from,
    //     address indexed to,
    //     uint256[] ids,
    //     uint256[] values
    // );

    // /**
    // * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
    // * `approved`.
    // */
    // event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /// ENS ------------------------------------------------------------------------------------

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // // Logged when an operator is added or removed.
    // event ApprovalForAll(
    //     address indexed owner,
    //     address indexed operator,
    //     bool approved
    // );

    /// 3DNS -----------------------------------------------------------------------------------

    event RegistrationCreated(
        bytes32 indexed node, bytes32 indexed tld, bytes fqdn, address registrant, uint32 controlBitmap, uint64 expiry
    );

    event RegistrationExtended(bytes32 indexed node, uint64 indexed duration, uint64 indexed newExpiry);

    event RegistrationTransferred(bytes32 indexed node, address indexed newOwner, address indexed operator);

    event RegistrationBurned(bytes32 indexed node, address indexed burner);

    event RegistrationLocked(bytes32 indexed node, uint64 lockedUntil);
    
    event RegistrationUnlocked(bytes32 indexed node);

    event RegistrationIAMAuthorization(bytes32 indexed node, address indexed operator, bytes32 permissions);
    event RegistrationIAMCleared(bytes32 indexed node);
}
