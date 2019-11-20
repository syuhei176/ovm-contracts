pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import "./AtomicPredicate.sol";
import "./LogicalConnective.sol";
import {UniversalAdjudicationContract} from "../UniversalAdjudicationContract.sol";

contract ForAllSuchThatQuantifier is LogicalConnective {
    address uacAddress;
    address notPredicateAddress;
    address andPredicateAddress;

    constructor(address _uacAddress, address _notPredicateAddress, address _andPredicateAddress) public {
        uacAddress = _uacAddress;
        notPredicateAddress = _notPredicateAddress;
        andPredicateAddress = _andPredicateAddress;
    }

    /**
     * @dev Validates a child node of ForAllSuchThat property in game tree.
     */
    function isValidChallenge(
        bytes[] calldata _inputs,
        bytes calldata _challengeInput,
        types.Property calldata _challnge
    ) external returns (bool) {
        // challenge should be not(p[quantified])
        require(
            _challnge.predicateAddress == notPredicateAddress,
            "_challenge must be Not predicate"
        );
        // check inner property
        require(
            keccak256(replaceVariable(_inputs[2], _inputs[1], _challengeInput)) == keccak256(_challnge.inputs[0]),
            "must be valid inner property"
        );
        return true;
    }

    /**
     * @dev Replace placeholder by quantified in propertyBytes
     */
    function replaceVariable(bytes memory propertyBytes, bytes memory placeholder, bytes memory quantified) private view returns(bytes memory) {
        types.Property memory property = abi.decode(propertyBytes, (types.Property));
        if(property.predicateAddress == notPredicateAddress) {
            property.inputs[0] = replaceVariable(property.inputs[0], placeholder, quantified);
        } else if(property.predicateAddress == address(this)) {
            property.inputs[2] = replaceVariable(property.inputs[2], placeholder, quantified);
        } else if(property.predicateAddress == andPredicateAddress) {
            for (uint i = 0;i < property.inputs.length;i++) {
                property.inputs[i] = replaceVariable(property.inputs[i], placeholder, quantified);
            }
        } else {
            for (uint i = 0;i < property.inputs.length;i++) {
                if(isPlaceholder(property.inputs[i])) {
                    if(keccak256(getPlaceholderName(property.inputs[i])) == keccak256(placeholder)) {
                        property.inputs[i] = quantified;
                    }
                }
            }
        }
        return abi.encode(property);
    }

    function isPlaceholder(bytes memory target) private pure returns (bool) {
        return keccak256(subBytes(target, 0, 12)) == keccak256(bytes("__VARIABLE__"));
    }

    function getPlaceholderName(bytes memory target) private pure returns (bytes memory) {
        return subBytes(target, 12, target.length);
    }

    function subBytes(bytes memory target, uint startIndex, uint endIndex) private pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = target[i];
        }
        return result;
    }
}