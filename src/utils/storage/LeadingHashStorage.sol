// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library LeadingHashStorage {
    struct LHBytes {
        bytes32 leadingHash;
        bytes data;
    }

    function get(LHBytes storage self) internal view returns (bytes memory) {
        return self.data;
    }

    function getLeadingHash(LHBytes storage self) internal view returns (bytes32) {
        return self.leadingHash;
    }

    function set(LHBytes storage self, bytes memory data) internal {
        self.leadingHash = keccak256(data);
        self.data = data;
    }

    struct LHString {
        LHBytes lhBytes;
    }

    function get(LHString storage self) internal view returns (string memory) {
        return string(LeadingHashStorage.get(self.lhBytes));
    }

    function getLeadingHash(LHString storage self) internal view returns (bytes32) {
        return LeadingHashStorage.getLeadingHash(self.lhBytes);
    }

    function set(LHString storage self, string memory data) internal {
        LeadingHashStorage.set(self.lhBytes, bytes(data));
    }
}