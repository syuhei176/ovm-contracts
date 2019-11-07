pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

/* Internal Contract Imports */
import "./Utils.sol";
import {DataTypes as types} from "./DataTypes.sol";
import "./Predicate/AtomicPredicate.sol";
import "./Predicate/LogicalConnective.sol";

contract UniversalAdjudicationContract {

    uint DISPUTE_PERIOD = 7;
    mapping (bytes32 => types.ChallengeGame) public claims;
    mapping (bytes32 => bool) contradictions;
    enum RemainingClaimIndex {Property, CounterProperty}
    address public notPredicateAddress;

    function setNotPredicateAddress(address _notPredicateAddress) public {
        notPredicateAddress = _notPredicateAddress;
    }

    function claimProperty(types.Property memory _claim) public {
        // get the id of this property
        bytes32 claimedPropertyId = Utils.getPropertyId(_claim);
        // make sure a claim on this property has not already been made
        require(Utils.isEmptyClaim(claims[claimedPropertyId]), "claim isn't empty");

        // create the claim status. Always begins with no proven contradictions
        types.ChallengeGame memory newGame = types.ChallengeGame(_claim, new bytes32[](0), types.Decision.Undecided, block.number);

        // store the claim
        claims[claimedPropertyId] = newGame;
    }

    function decideClaimToTrue(bytes32 _gameId) public {
        types.ChallengeGame storage game = claims[_gameId];
        // check all _game.challenges should be false
        for (uint256 i = 0;i < game.challenges.length; i++) {
            types.ChallengeGame memory challengingGame = claims[game.challenges[i]];
            require(challengingGame.decision == types.Decision.False, "all _game.challenges should be false");
        }
        // should check dispute period
        require(game.createdBlock < block.number - DISPUTE_PERIOD, "Dispute period haven't passed yet.");
        // game should be decided true
        game.decision = types.Decision.True;
    }

    function decideClaimToFalse(
        bytes32 _gameId,
        bytes32 _challengingGameId
    ) public {
        types.ChallengeGame storage game = claims[_gameId];
        types.ChallengeGame memory challengingGame = claims[_challengingGameId];
        // check _challenge is in _game.challenges
        bytes32 challengingGameId = Utils.getPropertyId(challengingGame.property);
        bool isValidChallenge = false;
        for (uint256 i = 0;i < game.challenges.length; i++) {
            if(game.challenges[i] == challengingGameId) {
                isValidChallenge = true;
            }
        }
        require(isValidChallenge, "challenge isn't valid");
        // _game.createdBlock > block.number - dispute
        // check _challenge have been decided true
        require(challengingGame.decision == types.Decision.True, "challenging game haven't been decided true.");
        // game should be decided false
        game.decision = types.Decision.False;
    }

    function removeChallenge(
        bytes32 _gameId,
        bytes32 _challengingGameId
    ) public {
    }

    function decideProperty(types.Property memory _property, bool _decision) public {
        // only the prodicate can decide a claim
        require(msg.sender == _property.predicateAddress, "msg.sender should be predicateAddress");
        bytes32 decidedPropertyId = Utils.getPropertyId(_property);

        // if the decision is true, automatically decide its claim now
        if (_decision) {
            claims[decidedPropertyId].decision = types.Decision.True; // True
        } else {
            claims[decidedPropertyId].decision = types.Decision.False; // False
        }
    }

    /**
     * @dev Challenges game with challenges
     */
    function challenge(
        bytes32 gameId,
        types.Challenge[] memory _challenges,
        bytes32 _challengingGameId
    ) public returns (bool) {
        types.ChallengeGame storage game = claims[gameId];
        types.ChallengeGame memory challengingGame = claims[_challengingGameId];
        // check the first valid challenge
        require(
            LogicalConnective(game.property.predicateAddress).isValidChallenge(game.property.inputs, _challenges[0].challengeInput, _challenges[0].challengeProperty),
            "_challenge[0] isn't valid"
        );
        // check left challenges
        for(uint i = 0;i < _challenges.length - 1;i++) {
            // if i % 2 is 0, it's counter parties turn. it can be skipped if challenge.predicate is NotPredicate.
            // Challenge can be skipped if it is NotPredicate because Not(something) don't require challengeInput
            if(i % 2 == 0) {
                require(_challenges[i].challengeProperty.predicateAddress == notPredicateAddress, "skipping challenge should be NotPredicate");
            }
            require(
                LogicalConnective(game.property.predicateAddress).isValidChallenge(_challenges[i].challengeProperty.inputs, _challenges[i].challengeInput, _challenges[i + 1].challengeProperty),
                "_challenge[i] isn't valid"
            );
        }
        require(
            keccak256(abi.encode(_challenges[_challenges.length - 1].challengeProperty)) == keccak256(abi.encode(challengingGame.property)),
            ""
        );
        game.challenges.push(_challengingGameId);
        return true;
    }

    /* Helpers */
    function isWhiteListedProperty(types.Property memory _property) private returns (bool) {
        return true; // Always return true until we know what to whitelist
    }

    function isDecided(types.Property memory _property) public returns (bool) {
        return claims[Utils.getPropertyId(_property)].decision == types.Decision.True;
    }

    function getGame(bytes32 claimId) public view returns (types.ChallengeGame memory) {
        return claims[claimId];
    }

    function getPropertyId(types.Property memory _property) public view returns (bytes32) {
        return Utils.getPropertyId(_property);
    }
}
