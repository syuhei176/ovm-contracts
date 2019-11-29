pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "./DataTypes.sol";

contract Utils {
    function bytesToAddress(bytes memory addressBytes) public pure returns (address addr) {
        assembly {
            addr := mload(add(addressBytes, 20))
        } 
    }
    
    function getPropertyId(types.Property memory _property) public pure returns (bytes32) {
        return keccak256(abi.encode(_property));
    }

    function isPlaceholder(bytes memory target) public pure returns (bool) {
        return keccak256(subBytes(target, 0, 12)) == keccak256(bytes("__VARIABLE__"));
    }

    function getPlaceholderName(bytes memory target) public pure returns (bytes memory) {
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
