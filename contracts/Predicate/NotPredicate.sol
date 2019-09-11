pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";

// Predicate returning true if a given proeprty is false
contract NotPredicate {
    struct NOTContradictionWitness {
        uint NOTIndex;
    }
    struct NOTPredicateInput {
        types.Property property;
    }

    function verifyContradiction(
        NOTPredicateInput memory _claim0,
        NOTPredicateInput memory _claim1,
        NOTContradictionWitness memory _contradictionWitness
    ) public returns (bool) {
        //a Not property contradicts to a base property if notProperty.input == baseProperty
        NOTPredicateInput[2] memory claims = [_claim0, _claim1];
        require(_contradictionWitness.NOTIndex == 0 || _contradictionWitness.NOTIndex == 1,
        "contradictionWitness's Index should be either 0 or 1");
        NOTPredicateInput memory baseClaim = claims[_contradictionWitness.NOTIndex];
        NOTPredicateInput memory NOTBaseClaim = claims[(_contradictionWitness.NOTIndex - 1)**2];
        return ((NOTBaseClaim.property.predicateAddress == address(this)) && (keccak256(NOTBaseClaim.property.input) == keccak256(abi.encode(baseClaim))));
    }

    function verifyImplication(
        NOTPredicateInput memory _thisClaim,
        NOTPredicateInput memory _implication
    ) public returns (bool) {
        //NOT(NOT(P)) implies P
        if ((_thisClaim.property.predicateAddress == address(this)) && (keccak256(_thisClaim.property.input) == keccak256(abi.encode(_implication)))
        ) {
            return true;
        } else {
            return false;
        }
    }
}