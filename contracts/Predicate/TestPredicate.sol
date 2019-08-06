pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract TestPredicate {
    struct TestPredicateInput {
        uint value;
    }

    event ValueDecided(bool decision, uint value);

    function decideTrue(TestPredicateInput memory _input) public {
        emit ValueDecided(true, _input.value);
    }

    function decideFalse(TestPredicateInput memory _input) public {
        emit ValueDecided(false, _input.value);
    }
}