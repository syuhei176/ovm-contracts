pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title Deposit And Éxit Contract
 * @notice This is mock contract of Deposit Contract originally written by Plasma Group. Original sourcecodes are https://github.com/plasma-group/pigi/commits/master/packages/contracts/contracts/Deposit.sol
 **/

/* External Imports */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/* Internal Imports */
import {DataTypes as types} from "./DataTypes.sol";
import {CommitmentContract} from "./CommitmentContract.sol";

contract DepostiAndExit {
    /* Events */
    event CheckpointFinalized(
        bytes32 checkpoint
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    /* Public Variables and Mappings*/
    ERC20 public erc20;
    CommitmentContract public commitmentContract;
    uint256 public totalDeposited;
    mapping (bytes32 => types.CheckpointStatus) public checkpoints;
    mapping (uint256 => types.Range) public depositedRanges;

    constructor(address _erc20, address _commitmentContract) public {
        erc20 = ERC20(_erc20);
        commitmentContract = CommitmentContract(_commitmentContract);
    }

    function deposit(uint256 _amount, types.StateObject memory _initialState) public {
        erc20.transferFrom(msg.sender, address(this), _amount);
        types.Range memory depositRange = types.Range({start:totalDeposited, end:totalDeposited + _amount});
        types.StateUpdate memory stateUpdate = types.StateUpdate({
            stateObject:_initialState,
            range: depositRange,
            plasmaBlockNumber: getLatestPlasmaBlockNumber(),
            depositAddress: address(this)
        });
        types.Checkpoint memory checkpoint = types.Checkpoint({
            stateUpdate: stateUpdate,
            subrange: depositRange
        });
        extendDepositedRanges(_amount);
        bytes32 checkpointId = getCheckpointId(checkpoint);
        types.CheckpointStatus memory status = types.CheckpointStatus({
            challengeableUntil: block.number - 1,
            outstandingChallenges: 0
        });
        checkpoints[checkpointId] = status;
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

    function extendDepositedRanges(uint256 _amount) public {
        uint256 oldStart = depositedRanges[totalDeposited].start;
        uint256 oldEnd = depositedRanges[totalDeposited].end;
        uint256 newStart;
        if (oldStart == 0 && oldEnd == 0) {
            newStart = totalDeposited;
        } else {
            delete depositedRanges[oldEnd];
            newStart = oldStart;
        }
        uint256 newEnd = totalDeposited + _amount;
        depositedRanges[newEnd] = types.Range({start:newStart, end:newEnd});
        totalDeposited += _amount;
    }

    function removeDepositedRange(types.Range memory range, uint256 depositedRangeId) public {
        types.Range memory encompasingRange = depositedRanges[depositedRangeId];
        if (range.start != encompasingRange.start) {
            types.Range memory leftSplitRange = types.Range({start:encompasingRange.start, end:range.start});
            depositedRanges[leftSplitRange.end] = leftSplitRange;
            return;
        }
        delete depositedRanges[encompasingRange.end];
    }


    function startExit(types.Checkpoint memory _checkpoint) public {
    }

    function finalizeExit(types.Checkpoint memory _exit, uint256 depositedRangeId) public {
    }

    function deprecateExit(types.Checkpoint memory _exit) public {  
    }

    function challengeCheckpoint(types.Challenge memory _challenge) public {
    }

    function removeChallenge(types.Challenge memory _challenge) public {
    }

    /* Helpers */
    function getLatestPlasmaBlockNumber() private returns (uint256) {
        return 0;
    }
    function getCheckpointId(types.Checkpoint memory _checkpoint) private pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint.stateUpdate, _checkpoint.subrange));
    }
}