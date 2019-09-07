pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";

contract reducer {
    function reduce (types.Property memory _toQuantify) public returns (bool) {
    return true;
    }
}

contract LessThanQuantifier {

    struct LessThanQuantifierParameters {
        address reducer;
        uint upperBound;
    }
    function quantify(LessThanQuantifierParameters memory _parameters, types.Property memory _toQuantify) public returns (bool){
        //uint valueToQuantify = _parameters.reducer.reduce(_toQuantify);
        //return valueToQuantify < _parameters.upperBound;
    }
}
