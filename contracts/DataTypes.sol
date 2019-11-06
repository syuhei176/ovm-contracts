pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

library DataTypes {
    struct Property {
        address predicateAddress;
        bytes[] inputs;
        bytes[] properties;
    }

    enum Decision {
        Undecided,
        True,
        False
    }

    struct ChallengeGame {
        Property property;
        bytes32[] challenges;
        Decision decision;
        uint createdBlock;
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