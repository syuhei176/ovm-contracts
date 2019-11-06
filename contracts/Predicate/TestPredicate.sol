pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import "./AtomicPredicate.sol";
import {UniversalAdjudicationContract} from "../UniversalAdjudicationContract.sol";

contract TestPredicate is AtomicPredicate {
    address uacAddress;

    constructor(address _uacAddress) public {
        uacAddress = _uacAddress;
    }

    struct TestPredicateInput {
        uint value;
    }

    event ValueDecided(bool decision, bytes[] inputs);

    function createPropertyFromInput(bytes[] memory _input) public view returns (types.Property memory) {
        types.Property memory property = types.Property({
            predicateAddress: address(this),
            inputs: _input
        });
        return property;
    }

    function decideTrue(bytes[] memory _inputs) public {
        require(this.decide(_inputs), "This property is not true");

        types.Property memory property = createPropertyFromInput(_inputs);
        UniversalAdjudicationContract(uacAddress).decideProperty(property, true);

        emit ValueDecided(true, _inputs);
    }

    function decide(bytes[] calldata _inputs) external pure returns (bool) {
        return _inputs.length > 0 && keccak256(_inputs[0]) == keccak256(hex"01");
    }
}
