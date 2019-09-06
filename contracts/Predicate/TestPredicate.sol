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

contract TestPredicate {
    address uacAddress;

    constructor(address _uacAddress) public {
        uacAddress = _uacAddress;
    }

    struct TestPredicateInput {
        uint value;
    }

    event ValueDecided(bool decision, uint value);

    function createPropertyFromInput(TestPredicateInput memory _input) public view returns (DataTypes.Property memory) {
        DataTypes.Property memory property = DataTypes.Property({predicateAddress:address(this), input:abi.encode(_input)});
        return property;
    }

    function decideTrue(TestPredicateInput memory _input) public {
        DataTypes.Property memory property = createPropertyFromInput(_input);

        UniversalAdjudicationContract(uacAddress).decideProperty(property, true);

        emit ValueDecided(true, _input.value);
    }

    function decideFalse(TestPredicateInput memory _input) public {
        DataTypes.Property memory property = createPropertyFromInput(_input);

        UniversalAdjudicationContract(uacAddress).decideProperty(property, false);

        emit ValueDecided(false, _input.value);
    }
}