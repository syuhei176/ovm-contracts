pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract DataTypes {
    struct Property {
        address predicateAddress;
        bytes input;
    }

    struct Contradiction {
        Property property;
        Property counterProperty;
    }

    struct ClaimStatus {
        Property property;
        uint numProvenContradictions;
        uint decidedAfter; // claims can be decided after this block number
    }

    struct ImplicationProofElement {
        Property implication;
        bytes[] witness;
    }

    struct Challenge {
        Checkpoint challengedCheckpoint;
        Checkpoint challengingCheckpoint;
    }

    struct Range {
        uint256 start;
        uint256 end;
    }
    struct StateUpdate {
        Property property;
        Range range;
        uint256 plasmaBlockNumber;
        address depositAddress;
    }
    struct Checkpoint {
        StateUpdate stateUpdate;
        Range subrange;
    }
}