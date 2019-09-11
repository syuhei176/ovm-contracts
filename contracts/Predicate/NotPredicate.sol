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
        types.Property memory _claim0,
        types.Property memory _claim1,
        bytes memory _contradictionWitness
    ) public returns (bool) {
        (uint256 notIndex) = abi.decode(_contradictionWitness, (uint256));
        //a Not property contradicts to a base property if notProperty.input == baseProperty
        types.Property[2] memory claims = [_claim0, _claim1];
        require(notIndex == 0 || notIndex == 1,
            "contradictionWitness's Index should be either 0 or 1");
        types.Property memory baseClaim = claims[notIndex];
        types.Property memory NOTBaseClaim = claims[1 - notIndex];
        return (
            (NOTBaseClaim.predicateAddress == address(this))
            && (keccak256(NOTBaseClaim.input) == keccak256(abi.encode(baseClaim.predicateAddress, baseClaim.input))));
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