pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "./DataTypes.sol";

/**
 * @title CommitmentChain
 * @notice This is mock commitment chain contract. Spec is http://spec.plasma.group/en/latest/src/02-contracts/commitment-contract.html
 */
contract CommitmentContract{
    uint64 public blockNumber;
    // Event definitions
    event BlockSubmitted(
        uint64 blockNumber,
        bytes32 root
    );

    function submit_root(uint64 blkNumber, bytes32 _root) public {
        emit BlockSubmitted(blkNumber, _root);
    }

    // Predicate checks this
    function verifyInclusion(types.StateUpdate memory _stateUpdate, bytes memory _inclusionProof) public returns (bool) {
        // Always return true for now until we can verify inclusion proofs.
        return true;
    }

}
