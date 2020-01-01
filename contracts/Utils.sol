pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "./DataTypes.sol";

contract Utils {
    function bytesToAddress(bytes memory addressBytes)
        public
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(addressBytes, 20))
        }
    }

    function bytesToBytes32(bytes memory source)
        public
        pure
        returns (bytes32 result)
    {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytesToUint(bytes memory source)
        public
        pure
        returns (uint256 result)
    {
        result = bytesToUintWithOffset(source, 0);
    }

    function bytesToRange(bytes memory _bytes)
        public
        pure
        returns (types.Range memory)
    {
        uint256 start = bytesToUintWithOffset(_bytes, 0);
        uint256 end = bytesToUintWithOffset(_bytes, 32);
        return types.Range({start: start, end: end});
    }

    function bytesToUintWithOffset(bytes memory _bytes, uint256 _start)
        private
        pure
        returns (uint256 result)
    {
        require(
            _bytes.length >= (_start + 32),
            "_bytes do not have enough length"
        );

        assembly {
            result := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function getPropertyId(types.Property memory _property)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_property));
    }

    function isPlaceholder(bytes memory target) public pure returns (bool) {
        return
            target.length < 20 &&
            keccak256(subBytes(target, 0, 1)) == keccak256(bytes("V"));
    }

    function isLabel(bytes memory target) public pure returns (bool) {
        return
            target.length < 20 &&
            keccak256(subBytes(target, 0, 1)) == keccak256(bytes("L"));
    }

    function isConstant(bytes memory target) public pure returns (bool) {
        return
            target.length < 20 &&
            keccak256(subBytes(target, 0, 1)) == keccak256(bytes("C"));
    }

    function getInputValue(bytes memory target)
        public
        pure
        returns (bytes memory)
    {
        return subBytes(target, 1, target.length);
    }

    function subBytes(bytes memory target, uint256 startIndex, uint256 endIndex)
        private
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = target[i];
        }
        return result;
    }

    function subArray(
        bytes[] memory target,
        uint256 startIndex,
        uint256 endIndex
    ) public pure returns (bytes[] memory) {
        bytes[] memory result = new bytes[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = target[i];
        }
        return result;
    }

    function prefixConstant(bytes memory _source)
        public
        pure
        returns (bytes memory)
    {
        return prefix(bytes1("C"), _source);
    }

    function prefixLabel(bytes memory _source)
        public
        pure
        returns (bytes memory)
    {
        return prefix(bytes1("L"), _source);
    }

    function prefixVariable(bytes memory _source)
        public
        pure
        returns (bytes memory)
    {
        return prefix(bytes1("V"), _source);
    }

    function prefix(bytes1 _prefix, bytes memory _source)
        public
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(_source.length + 1);
        result[0] = _prefix;
        for (uint256 i = 1; i < result.length; i++) {
            result[i] = _source[i - 1];
        }
        return result;
    }
}
