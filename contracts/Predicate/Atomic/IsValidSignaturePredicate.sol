pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "../../DataTypes.sol";
import "../AtomicPredicate.sol";
import {UniversalAdjudicationContract} from "../../UniversalAdjudicationContract.sol";
import "../../Utils.sol";
import "../../Library/ECRecover.sol";

contract IsValidSignaturePredicate is AtomicPredicate {
    address uacAddress;
    Utils utils;

    constructor(address _uacAddress, address _utilsAddress) public {
        uacAddress = _uacAddress;
        utils = Utils(_utilsAddress);
    }
    
    function decideTrue(bytes[] memory _inputs) public {
        require(keccak256(abi.encodePacked(string(_inputs[3]))) == keccak256("secp256k1"), "verifierType must be secp256k1");
        require(ECRecover.ecverify(
            keccak256(_inputs[0]),
            _inputs[1],
            utils.bytesToAddress(_inputs[2])
        ), "This property is not true");

        types.Property memory property = types.Property({
            predicateAddress: address(this),
            inputs: _inputs
        });
        UniversalAdjudicationContract(uacAddress).setPredicateDecision(utils.getPropertyId(property), true);
    }
}
