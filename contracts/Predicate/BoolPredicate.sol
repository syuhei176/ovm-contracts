pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract DataTypes {
    struct Property {
        address predicateAddress;
        bytes input;
    }
}

contract UniversalAdjudicationContract {
    function decideProperty(DataTypes.Property memory, bool) public {}
}

contract BoolPredicate {
    address uacAddress;

    constructor(address _uacAddress) public {
        uacAddress = _uacAddress;
    }

    event ValueDecided(bool decision, uint value);

    function decideTrue() public {
        DataTypes.Property memory property = DataTypes.Property({
            predicateAddress: address(this),
            input: ''
        });
        UniversalAdjudicationContract(uacAddress).decideProperty(property, true);
    }

}