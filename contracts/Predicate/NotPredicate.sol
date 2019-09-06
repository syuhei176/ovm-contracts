pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract DataTypes {
    struct Property {
        address predicateAddress;
        bytes input;
    }

    struct NOTContradictionWitness {
        uint NOTIndex;
    }
}


// Predicate returning true if a given proeprty is false
contract NotPredicate {
    function verifyContradiction(DataTypes.Property memory _claim0, DataTypes.Property memory _claim1, DataTypes.NOTContradictionWitness memory _contradictionWitness) public returns (bool) {
        //a Not property contradicts to a base property if notProperty.input == baseProperty
        DataTypes.Property[2] memory claims = [_claim0, _claim1];
        require(_contradictionWitness.NOTIndex == 0 || _contradictionWitness.NOTIndex == 1);
        DataTypes.Property memory baseClaim = claims[_contradictionWitness.NOTIndex];
        DataTypes.Property memory NOTBaseClaim = claims[(_contradictionWitness.NOTIndex - 1)**2];
        return ((NOTBaseClaim.predicateAddress == address(this)) && (keccak256(NOTBaseClaim.input) == keccak256(abi.encode(baseClaim))));
    }

    function verifyImplication(DataTypes.Property memory _thisClaim, DataTypes.Property memory _implication) public returns (bool) {
        //NOT(NOT(P)) implies P
        if ((_thisClaim.predicateAddress == address(this)) && (keccak256(_thisClaim.input) == keccak256(abi.encode(_implication)))
        ) {
            return true;
        } else {
            return false;
        }
    }
}