pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


/* External Imports */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/* Internal Imports */
import {DataTypes as types} from "./DataTypes.sol";
import {CommitmentContract} from "./CommitmentContract.sol";
import {UniversalAdjudicationContract} from "./UniversalAdjudicationContract.sol";

contract DepostiAndExit {
    /* Events */
    event CheckpointFinalized(
        bytes32 checkpointId
    );

    event LogCheckpoint(
        types.Checkpoint checkpoint
    );

    event ExitFinalized(
        bytes32 exitId
    );

    /* Public Variables and Mappings*/
    ERC20 public erc20;
    CommitmentContract public commitmentContract;
    UniversalAdjudicationContract public universalAdjudicationContract;
    uint256 public totalDeposited;
    mapping (uint256 => types.Range) public depositedRanges;
    mapping (bytes32 => types.Checkpoint) public checkpoints;
    mapping (bytes32 => bool) public checkpointsExist;

    constructor(address _erc20, address _commitmentContract, address _universalAdjudicationContract) public {
        erc20 = ERC20(_erc20);
        commitmentContract = CommitmentContract(_commitmentContract);
        universalAdjudicationContract = UniversalAdjudicationContract(_universalAdjudicationContract);
    }

    function deposit(uint256 _amount, types.Property memory _initialState) public {
        erc20.transferFrom(msg.sender, address(this), _amount);
        types.Range memory depositRange = types.Range({start:totalDeposited, end:totalDeposited + _amount});
        types.StateUpdate memory stateUpdate = types.StateUpdate({
            property:_initialState,
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
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

    function extendDepositedRanges(uint256 _amount) public {
        uint256 oldStart = depositedRanges[totalDeposited].start;
        uint256 oldEnd = depositedRanges[totalDeposited].end;
        uint256 newStart;
        if (oldStart == 0 && oldEnd == 0) {
            // Creat a new range when the rightmost range has been removed
            newStart = totalDeposited;
        } else {
            // Delete the old range and make a new one with the total length
            delete depositedRanges[oldEnd];
            newStart = oldStart;
        }
        uint256 newEnd = totalDeposited + _amount;
        depositedRanges[newEnd] = types.Range({start:newStart, end:newEnd});
        totalDeposited += _amount;
    }

    function removeDepositedRange(types.Range memory _range, uint256 _depositedRangeId) public {
        types.Range memory encompasingRange = depositedRanges[_depositedRangeId];
        if (_range.start != encompasingRange.start) {
            types.Range memory leftSplitRange = types.Range({start:encompasingRange.start, end:_range.start});
            depositedRanges[leftSplitRange.end] = leftSplitRange;
            return;
        }
        delete depositedRanges[encompasingRange.end];
    }

    function finalizeCheckpoint(types.Checkpoint memory _checkpoint) public {
        require(universalAdjudicationContract.isDecided(_checkpoint.stateUpdate.property), "Checkpointing claim must be decided");
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        // store the checkpoint
        checkpoints[checkpointId] = _checkpoint;
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(_checkpoint);
    }

    function finalizeExit(types.Checkpoint memory _checkpoint, uint256 _depositedRangeId) public {
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        // Check that we are authorized to finalize this exit
        require(_checkpoint.stateUpdate.property.predicateAddress == msg.sender, "Exiting claim must be finalized by its predicate");
        require(isFinalized(_checkpoint), "Checkpoint must be finalized to finalize an exit");
        require(universalAdjudicationContract.isDecided(_checkpoint.stateUpdate.property), "Exit must be decided after this block");
        require(isSubrange(_checkpoint.subrange, depositedRanges[_depositedRangeId]), "Exit must be of a depostied range (the one that has not been exited)");
        // Remove the deposited range
        removeDepositedRange(_checkpoint.subrange, _depositedRangeId);
        //Transfer tokens to its predicate
        uint256 amount = _checkpoint.subrange.end - _checkpoint.subrange.start;
        erc20.transfer(_checkpoint.stateUpdate.property.predicateAddress, amount);
        emit ExitFinalized(checkpointId);
    }

    /* Helpers */
    function getLatestPlasmaBlockNumber() private returns (uint256) {
        return 0;
    }

    function getCheckpointId(types.Checkpoint memory _checkpoint) private pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint.stateUpdate, _checkpoint.subrange));
    }

    function isSubrange(types.Range memory _subrange, types.Range memory _surroundingRange) public pure returns (bool) {
        return _subrange.start >= _surroundingRange.start && _subrange.end <= _surroundingRange.end;
    }
    function isFinalized(types.Checkpoint memory _checkpoint) public view returns (bool) {
        bytes32 checkpointId = getCheckpointId(_checkpoint);
        return checkpointsExist[checkpointId];
    }
}