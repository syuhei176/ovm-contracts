pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import "./OperatorPredicate.sol";
import {UniversalAdjudicationContract} from "../UniversalAdjudicationContract.sol";

contract NotPredicate is OperatorPredicate {
    address uacAddress;

    constructor(address _uacAddress) public {
        uacAddress = _uacAddress;
    }

    struct TestPredicateInput {
        uint value;
    }

    event ValueDecided(bool decision, types.Property innerProperty);

    function createPropertyFromInput(bytes[] memory _input) public view returns (types.Property memory) {
        types.Property memory property = types.Property({
            predicateAddress: address(this),
            inputs: _input
        });
        return property;
    }

    function isValidChallenge(bytes[] calldata _inputs, bytes calldata _challengeInput, types.Property calldata _challnge) external returns (bool) {
        return keccak256(_inputs[0]) == keccak256(abi.encode(_challnge));
    }
    
    function decideTrue(types.Property memory innerProperty, bytes memory _witness) public {
        require(
            UniversalAdjudicationContract(uacAddress).isDecided(innerProperty),
            "This property isn't true"
        );
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(innerProperty);
        types.Property memory property = createPropertyFromInput(inputs);
        UniversalAdjudicationContract(uacAddress).decideProperty(property, true);

        emit ValueDecided(true, innerProperty);
    }
}
