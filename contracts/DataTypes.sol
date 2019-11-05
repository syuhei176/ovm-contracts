pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract DataTypes {
    struct Property {
        address predicateAddress;
        bytes[] inputs;
    }
    
    struct ChallengeGame {
        Property property;
        bytes32[] challenges;
        // 0: undecided, 1: true, 2: false
        uint decision;
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