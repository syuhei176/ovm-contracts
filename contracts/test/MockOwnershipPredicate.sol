pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import { AtomicPredicate } from "../Predicate/AtomicPredicate.sol";
import "../DepositContract.sol";

/**
 * @title MockOwnershipPredicate
 * @notice Mock of compiled ownership predicate
 */
contract MockOwnershipPredicate is AtomicPredicate {
    address public depositContractAddress;
    constructor(address _depositContractAddress) public {
        depositContractAddress = _depositContractAddress;
    }
    function decideTrue(bytes[] calldata _inputs) external {
    }
    function finalizeExit(types.Property memory _exitProperty, uint256 _depositedRangeId) public {
        DepositContract(depositContractAddress).finalizeExit(_exitProperty, _depositedRangeId);
    }
}
