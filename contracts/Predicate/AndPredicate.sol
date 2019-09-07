pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";
import {UniversalAdjudicationContract as UDC} from "../UniversalAdjudicationContract.sol";

contract AndPredicate {
    UDC public udc;
    constructor(address udc_address) public {
        udc = UDC(udc_address);
    }
    struct ANDPredicateInput {
        types.Property property;
    }
    struct ANDImplicationWitness {
        uint ANDIndex;
    }
    function verifyImplication(
        ANDPredicateInput memory _claim0,
        ANDPredicateInput memory _claim1,
        types.ImplicationProofElement memory _implicationProofElement,
        ANDImplicationWitness memory _implicationWitness
        ) public returns (bool) {
        ANDPredicateInput[2] memory claims = [_claim0, _claim1];
        types.Property memory implication = _implicationProofElement.implication;
        require(_implicationWitness.ANDIndex == 0 || _implicationWitness.ANDIndex == 1,
        "AndImplicationWitness's Index should be either 0 or 1");
        return (keccak256(abi.encode(claims[_implicationWitness.ANDIndex])) == keccak256(abi.encode(implication)));
    }
    function decideTrue(
        types.Property memory _claim0,
        types.Property memory _claim1
    ) public returns (bool){
        if ((udc.isDecided(_claim0)) && (udc.isDecided(_claim1))
        ) {
            return true;
        } else {
            return false;
        }
    }
}
