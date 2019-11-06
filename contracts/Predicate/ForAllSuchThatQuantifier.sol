pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import "./AtomicPredicate.sol";
import "./LogicalConnective.sol";
import {UniversalAdjudicationContract} from "../UniversalAdjudicationContract.sol";

contract ForAllSuchThatQuantifier is LogicalConnective {
    address uacAddress;
    address notPredicateAddress;

    constructor(address _uacAddress, address _notPredicateAddress) public {
        uacAddress = _uacAddress;
        notPredicateAddress = _notPredicateAddress;
    }

    /**
     * @dev Validates a child node of ForAllSuchThat property in game tree.
     */
    function isValidChallenge(
        types.Property calldata _property,
        bytes calldata _challengeInput,
        types.Property calldata _challnge
    ) external returns (bool) {
        types.Property memory quantifier = abi.decode(_property.properties[0], (types.Property));
        bytes[] memory qInputs = new bytes[](quantifier.inputs.length + 1);
        for (uint i = 0;i < quantifier.inputs.length;i++) {
            qInputs[i] = quantifier.inputs[i];
        }
        qInputs[quantifier.inputs.length] = _challengeInput;
        require(AtomicPredicate(quantifier.predicateAddress).decide(qInputs), "should be quantified");

        // challenge should be not(p[quantified])
        require(_challnge.predicateAddress == notPredicateAddress, "should be Not Predicate");
        // check inner property
        require(keccak256(replaceVariable(_property.properties[1], _property.inputs[0], _challengeInput)) == keccak256(_challnge.properties[0]), "should be valid inner property");
        return true;
    }

    /**
     * @dev Replace placeholder by quantified in propertyBytes recursively
     */
    function replaceVariable(bytes memory propertyBytes, bytes memory placeholder, bytes memory quantified) private pure returns(bytes memory) {
        types.Property memory property = abi.decode(propertyBytes, (types.Property));
        for (uint i = 0;i < property.inputs.length;i++) {
            if(keccak256(property.inputs[i]) == keccak256(placeholder)) {
                property.inputs[i] = quantified;
            }
        }
        for (uint i = 0;i < property.properties.length;i++) {
            property.properties[i] = replaceVariable(property.properties[i], placeholder, quantified);
        }
        return abi.encode(property);
    }
}
