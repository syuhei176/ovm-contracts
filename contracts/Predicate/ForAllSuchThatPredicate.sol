pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import {LessThanQuantifier} from "./LessThanQuantifier.sol";

contract ForAllSuchThatPredicate {
    LessThanQuantifier public lessThanQuantifier;
    constructor(address lessThanQuantifier_address) public {
        lessThanQuantifier = LessThanQuantifier(lessThanQuantifier_address);
    }

    struct QuantifierInput {
        address quantifierAddress;
        bytes input;
    }
    struct QuantifierImplicationWitness {
        uint QuantifierIndex;
    }

    function verifyImplication(
        QuantifierInput memory _quantifierInput,
        types.ImplicationProofElement memory _implicationProofElement,
        QuantifierImplicationWitness memory _implicationWitness
    ) public returns (bool) {
        bytes memory input = _quantifierInput.input;
        types.Property memory implication = _implicationProofElement.implication;
        return (lessThanQuantifier.quantify(input, implication));
    }
}
