pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/* External Imports */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* Internal Imports */
import {DataTypes as types} from "./DataTypes.sol";
import {CommitmentContract} from "./CommitmentContract.sol";
import {UniversalAdjudicationContract} from "./UniversalAdjudicationContract.sol";

contract DepositContract {
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

    constructor(address _erc20, address _commitmentContract, address _universalAdjudicationContract) public {
        erc20 = ERC20(_erc20);
        commitmentContract = CommitmentContract(_commitmentContract);
        universalAdjudicationContract = UniversalAdjudicationContract(_universalAdjudicationContract);
    }

    /**
     * @dev deposit ERC20 token to deposit contract with initial state.
     *     following https://docs.plasma.group/projects/spec/en/latest/src/02-contracts/deposit-contract.html#deposit
     */
    function deposit(uint256 _amount, types.Property memory _initialState) public {
        erc20.transferFrom(msg.sender, address(this), _amount);
        types.Range memory depositRange = types.Range({start:totalDeposited, end:totalDeposited + _amount});
        types.StateUpdate memory stateUpdate = types.StateUpdate({
            stateObject: _initialState,
            range: depositRange,
            plasmaBlockNumber: getLatestPlasmaBlockNumber() - 1,
            depositAddress: address(this)
        });
        types.Checkpoint memory checkpoint = types.Checkpoint({
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
        require(
            isSubrange(_range, depositedRanges[_depositedRangeId]),
            "range must be of a depostied range (the one that has not been exited)"
        );
        types.Range storage encompasingRange = depositedRanges[_depositedRangeId];
        /*
         * depositedRanges makes O(1) checking existence of certain range.
         * Since _range is subrange of encompasingRange, we only have to check is each start and end are same or not.
         * So, there are 2 patterns for each start and end of _range and encompasingRange.
         * There are nothing todo for _range.start is equal to encompasingRange.start.
         */
         // Check start of range
        if (_range.start != encompasingRange.start) {
            types.Range memory leftSplitRange = types.Range({start:encompasingRange.start, end:_range.start});
            depositedRanges[leftSplitRange.end] = leftSplitRange;
        }
         // Check end of range
        if (_range.end == encompasingRange.end) {
            /*
             * Deposited range Id is end value of the range, we must remove the range from depositedRanges
             *     when range.end is changed.
             */
            delete depositedRanges[encompasingRange.end];
        } else {
            encompasingRange.start = _range.end;
        }
    }

    function finalizeCheckpoint(types.Property memory _checkpointProperty) public {
        require(universalAdjudicationContract.isDecided(_checkpointProperty), "Checkpointing claim must be decided");
        types.Checkpoint memory checkpoint = deserializeCheckpoint(_checkpointProperty);
        bytes32 checkpointId = getCheckpointId(checkpoint);
        // store the checkpoint
        checkpoints[checkpointId] = checkpoint;
        emit CheckpointFinalized(checkpointId);
        emit LogCheckpoint(checkpoint);
    }

    /**
     * finalizeExit
     * @param _exitProperty Property for exit
     * @param _depositedRangeId Id of deposited range
     */
    function finalizeExit(types.Property memory _exitProperty, uint256 _depositedRangeId) public {
        types.Exit memory exit = deserializeExit(_exitProperty);
        bytes32 exitId = getExitId(exit);
        // Check that we are authorized to finalize this exit
        require(universalAdjudicationContract.isDecided(_exitProperty), "Exit must be decided after this block");
        require(exit.stateUpdate.stateObject.predicateAddress == msg.sender, "finalizeExit must be called from StateObject contract");
        require(exit.stateUpdate.depositAddress == address(this), "StateUpdate.depositAddress must be this contract address");
        // Remove the deposited range
        removeDepositedRange(exit.subrange, _depositedRangeId);
        //Transfer tokens to its predicate
        uint256 amount = exit.subrange.end - exit.subrange.start;
        erc20.transfer(exit.stateUpdate.stateObject.predicateAddress, amount);
        emit ExitFinalized(exitId);
    }

    /* Helpers */
    function getLatestPlasmaBlockNumber() private returns (uint256) {
        return commitmentContract.currentBlock();
    }

    function getCheckpointId(types.Checkpoint memory _checkpoint) private pure returns (bytes32) {
        return keccak256(abi.encode(_checkpoint));
    }

    function getExitId(types.Exit memory _exit) private pure returns (bytes32) {
        return keccak256(abi.encode(_exit));
    }

    /**
     * @dev deserialize property to Checkpoint instance
     */
    function deserializeCheckpoint(types.Property memory _checkpoint) private pure returns (types.Checkpoint memory) {
        types.Range memory range = abi.decode(_checkpoint.inputs[0], (types.Range));
        return types.Checkpoint({
            subrange: range
        });
    }

    /**
     * @dev deserialize property to Exit instance
     */
    function deserializeExit(types.Property memory _exit) private pure returns (types.Exit memory) {
        types.Range memory range = abi.decode(_exit.inputs[0], (types.Range));
        types.Property memory stateUpdateProperty = abi.decode(_exit.inputs[1], (types.Property));
        return types.Exit({
            stateUpdate: deserializeStateUpdate(stateUpdateProperty),
            subrange: range
        });
    }

    /**
     * @dev deserialize property to StateUpdate instance
     */
    function deserializeStateUpdate(types.Property memory _stateUpdate) private pure returns (types.StateUpdate memory) {
        types.Property memory stateObject = abi.decode(_stateUpdate.inputs[0], (types.Property));
        types.Range memory range = abi.decode(_stateUpdate.inputs[1], (types.Range));
        uint256 plasmaBlockNumber = abi.decode(_stateUpdate.inputs[2], (uint256));
        address depositAddress = abi.decode(_stateUpdate.inputs[3], (address));
        return types.StateUpdate({
            stateObject: stateObject,
            range: range,
            plasmaBlockNumber: plasmaBlockNumber,
            depositAddress: depositAddress
        });
    }


    function getExitId(types.Property memory _exit) private pure returns (bytes32) {
        return keccak256(abi.encode(_exit));
    }

    function isSubrange(types.Range memory _subrange, types.Range memory _surroundingRange) public pure returns (bool) {
        return _subrange.start >= _surroundingRange.start && _subrange.end <= _surroundingRange.end;
    }
}