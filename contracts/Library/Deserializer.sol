pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../DataTypes.sol";

library Deserializer {
    /**
     * @dev deserialize property to Exit instance
     */
    function deserializeExit(types.Property memory _exit)
        public
        pure
        returns (types.Exit memory)
    {
        types.Range memory range = abi.decode(_exit.inputs[0], (types.Range));
        types.Property memory stateUpdateProperty = abi.decode(
            _exit.inputs[1],
            (types.Property)
        );
        return
            types.Exit({
                stateUpdate: deserializeStateUpdate(stateUpdateProperty),
                subrange: range
            });
    }

    /**
     * @dev deserialize property to StateUpdate instance
     */
    function deserializeStateUpdate(types.Property memory _stateUpdate)
        private
        pure
        returns (types.StateUpdate memory)
    {
        address depositAddress = bytesToAddress(_stateUpdate.inputs[0]);
        types.Range memory range = abi.decode(
            _stateUpdate.inputs[1],
            (types.Range)
        );
        uint256 blockNumber = abi.decode(_stateUpdate.inputs[2], (uint256));
        types.Property memory stateObject = abi.decode(
            _stateUpdate.inputs[3],
            (types.Property)
        );
        return
            types.StateUpdate({
                blockNumber: blockNumber,
                depositAddress: depositAddress,
                range: range,
                stateObject: stateObject
            });
    }

    function bytesToAddress(bytes memory addressBytes)
        public
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(addressBytes, 20))
        }
    }
}
