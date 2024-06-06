//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error IndexOutOfBounds(uint256 index, uint256 length);
error NoLabelAtSpecifiedIndex();
error SubstringOverflow();
error JunkAtEndOfName();

error BytesUtils_notFullyQualified();

library BytesUtils {
    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(bytes memory self, uint256 offset, uint256 len) internal pure returns (bytes32 ret) {
        if (offset + len > self.length) revert IndexOutOfBounds(offset + len, self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Returns the ENS namehash of a DNS-encoded name.
     * @param self The DNS-encoded name to hash.
     * @param offset The offset at which to start hashing.
     * @return The namehash of the name.
     */
    function namehash(bytes memory self, uint256 offset) internal pure returns (bytes32) {
        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            if (offset != self.length - 1) revert JunkAtEndOfName();
            return bytes32(0);
        }
        return keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    }

    /**
     * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
     * @param self The byte string to read a label from.
     * @param idx The index to read a label at.
     * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
     * @return newIdx The index of the start of the next label.
     */
    function readLabel(bytes memory self, uint256 idx) internal pure returns (bytes32 labelhash, uint256 newIdx) {
        if (idx >= self.length) revert IndexOutOfBounds(idx, self.length);
        uint256 len = uint256(uint8(self[idx]));
        if (len > 0) {
            labelhash = keccak(self, idx + 1, len);
        } else {
            labelhash = bytes32(0);
        }
        newIdx = idx + len + 1;
    }

    /**
     * @dev Qualifies that the host is fully qualified relative to the parent node & returns the ending index of the label.
     * @param self The wire-encoded host.
     * @param parent The namehash of the parent node.
     * @return hostNodes The namehash of all children leading up to the host.
     */
    function validateHost(
        bytes memory self,
        bytes32 parent,
        bool qualifyHost
    ) internal pure returns (bytes32[] memory hostNodes) {
        // Calculate all label hashes
        (bytes32[] memory labelhashes) = hashParts(self, 0);

        // Calculate the namehash
        bytes32 node;
        bool qualified;
        uint256 pos = labelhashes.length;

        if (!qualifyHost) {
            node = parent;
            qualified = true;
            hostNodes = new bytes32[](pos);
        }
        for (; pos > 0; pos--) {
            node = keccak256(abi.encodePacked(node, labelhashes[pos - 1]));
            if (!qualified) {
                if (node == parent) {
                    qualified = true;
                    hostNodes = new bytes32[](pos - 1);
                }
            } else {
                // Once we are qualified, we can start storing the host nodes
                hostNodes[hostNodes.length - pos] = node;
            }
        }

        // Ensure that the name is fully qualified
        if (!qualified) revert BytesUtils_notFullyQualified();
        return hostNodes;
    }

    /**
     * @dev Returns the keccak-256 hash of a wire-encoded labeles.
     * @param self The wire-encoded host.
     * @param idx The index to start reading labels from.
     * @return labelhashes The hash of the label from the wire-encoded host.
     */
    function hashParts(
        bytes memory self,
        uint256 idx
    ) internal pure returns (bytes32[] memory labelhashes) {
        // Count the number of labels
        uint256 count;
        uint256 offset = idx;
        while (offset < self.length && self[offset] != 0x00) {
            offset += uint256(uint8(self[offset])) + 1;
            count++;
        }

        // Ensure that we consumed the entire input
        require(isEnd(self, offset), "hashParts: Junk at end of name");

        // Initialize the output array
        labelhashes = new bytes32[](count);

        // Hash the labels
        offset = idx;
        for (uint256 i = 0; i < count; i++) {
            (labelhashes[i], offset) = readLabel(self, offset);
        }

        // Return the output
        return labelhashes;
    }

    function isEnd(bytes memory self, uint256 offset) internal pure returns (bool) {
        return offset == self.length - 1 && self[offset] == 0x00;
    }

    function readAndReturnLabel(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes memory label, bytes32 labelhash, uint256 newIdx)
    {
        (labelhash, newIdx) = readLabel(self, idx);
        if (idx == newIdx) {
            revert NoLabelAtSpecifiedIndex();
        }
        label = substring(self, idx + 1, uint256(uint8(self[idx])));
    }

    /*
     * @dev Copies a substring into a new byte string.
     * @param self The byte string to copy from.
     * @param offset The offset to start copying at.
     * @param len The number of bytes to copy.
     */
    function substring(bytes memory self, uint256 offset, uint256 len) internal pure returns (bytes memory) {
        if (offset + len > self.length) revert SubstringOverflow();

        bytes memory ret = new bytes(len);
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        _memcpy(dest, src, len);

        return ret;
    }

    function _memcpy(uint256 dest, uint256 src, uint256 len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}
