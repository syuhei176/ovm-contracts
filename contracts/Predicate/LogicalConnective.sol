pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";

interface LogicalConnective {
    function isValidChallenge(
        types.Property calldata,
        bytes calldata,
        types.Property calldata
    ) external returns (bool);
}
