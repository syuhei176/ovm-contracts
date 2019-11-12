pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import { AtomicPredicate } from "../Predicate/AtomicPredicate.sol";
import "../DepositAndExit.sol";


/**
 * @dev Mock of compiled ownership predicate
 */
contract MockOwnershipPredicate is AtomicPredicate {
    address public depositContractAddress;
    constructor(address _depositContractAddress) public {
        depositContractAddress = _depositContractAddress;
    }
    function decideTrue(bytes[] calldata _inputs, bytes calldata _witness) external {
    }
    function finalizeExit(types.Property memory _exitProperty, uint256 _depositedRangeId) public {
        DepositAndExit(depositContractAddress).finalizeExit(_exitProperty, _depositedRangeId);
    }
}
