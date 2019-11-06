pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import "./LogicalConnective.sol";
import {UniversalAdjudicationContract} from "../UniversalAdjudicationContract.sol";

contract AndPredicate is LogicalConnective {
    address uacAddress;

    constructor(address _uacAddress) public {
        uacAddress = _uacAddress;
    }

    struct TestPredicateInput {
        uint value;
    }

    event ValueDecided(bool decision, types.Property property);

    function createPropertyFromInput(bytes[] memory _input) public view returns (types.Property memory) {
        types.Property memory property = types.Property({
            predicateAddress: address(this),
            inputs: _input
        });
        return property;
    }

    /**
     * @dev Validates a child node of And property in game tree.
     */
    function isValidChallenge(bytes[] calldata _inputs, bytes calldata _challengeInput, types.Property calldata _challnge) external returns (bool) {
        // The valid challenge of not(p) is p and _inputs[0] is p here
        uint256 index = abi.decode(_challengeInput, (uint256));
        return keccak256(_inputs[index]) == keccak256(abi.encode(_challnge));
    }
    
    /**
     * @dev Can decide true when all child properties are decided true
     */
    function decideTrue(types.Property[] memory innerProperties, bytes memory _witness) public {
        for (uint i = 0;i < innerProperties.length;i++) {
            require(
                UniversalAdjudicationContract(uacAddress).isDecided(innerProperties[i]),
                "This property isn't true"
            );
        }
        bytes[] memory inputs = new bytes[](innerProperties.length);
        for (uint i = 0;i < innerProperties.length;i++) {
            inputs[i] = abi.encode(innerProperties[i]);
        }
        types.Property memory property = createPropertyFromInput(inputs);
        UniversalAdjudicationContract(uacAddress).decideProperty(property, true);

        emit ValueDecided(true, property);
    }
}
