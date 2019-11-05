pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

/* Internal Contract Imports */
import "./Utils.sol";
import {DataTypes as types} from "./DataTypes.sol";
import "./Predicate/AtomicPredicate.sol";
import "./Predicate/OperatorPredicate.sol";

contract UniversalAdjudicationContract {

    uint DISPUTE_PERIOD = 7;
    mapping (bytes32 => types.ChallengeGame) public claims;
    mapping (bytes32 => bool) contradictions;
    enum RemainingClaimIndex {Property, CounterProperty}

    function claimProperty(types.Property memory _claim) public {
        // get the id of this property
        bytes32 claimedPropertyId = Utils.getPropertyId(_claim);
        // make sure a claim on this property has not already been made
        require(Utils.isEmptyClaim(claims[claimedPropertyId]), "claim isn't empty");

        // create the claim status. Always begins with no proven contradictions
        types.ChallengeGame memory newGame = types.ChallengeGame(_claim, new bytes32[](0), 0, block.number);

        // store the claim
        claims[claimedPropertyId] = newGame;
    }

    function decideClaimToTrue(bytes32 _gameId) public {
        types.ChallengeGame storage game = claims[_gameId];
        // check all _game.challenges should be false
        for (uint256 i = 0;i < game.challenges.length; i++) {
            types.ChallengeGame memory challengingGame = claims[game.challenges[i]];
            require(challengingGame.decision == 2, "all _game.challenges should be false");
        }
        // should check dispute period
        require(game.createdBlock < block.number - DISPUTE_PERIOD, "Dispute period haven't passed yet.");
        // game should be decided true
        game.decision = 1;
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
        require(challengingGame.decision == 1, "challenging game haven't been decided true.");
        // game should be decided false
        game.decision = 2;
    }

    function removeChallenge(types.ChallengeGame memory _game, types.ChallengeGame memory _challenge) public {
    }

    function decideProperty(types.Property memory _property, bool _decision) public {
        // only the prodicate can decide a claim
        require(msg.sender == _property.predicateAddress, "msg.sender should be predicateAddress");
        bytes32 decidedPropertyId = Utils.getPropertyId(_property);

        // if the decision is true, automatically decide its claim now
        if (_decision) {
            claims[decidedPropertyId].decision = 1; // True
        } else {
            claims[decidedPropertyId].decision = 2; // False
        }
    }

    function challenge(
        bytes32 gameId,
        bytes[] memory _challengeInputs,
        bytes32 _challengingGameId
    ) public returns (bool) {
        types.ChallengeGame storage game = claims[gameId];
        types.ChallengeGame memory challengingGame = claims[_challengingGameId];
        require(
            OperatorPredicate(game.property.predicateAddress).isValidChallenge(game.property.inputs, _challengeInputs[0], challengingGame.property),
            "_challenge isn't valid"
        );
        game.challenges.push(_challengingGameId);
        return true;
    }

    /* Helpers */
    function isWhiteListedProperty(types.Property memory _property) private returns (bool) {
        return true; // Always return true until we know what to whitelist
    }

    function isDecided(types.Property memory _property) public returns (bool) {
        return claims[Utils.getPropertyId(_property)].decision == 1;
    }

    function getGame(bytes32 claimId) public view returns (types.ChallengeGame memory) {
        return claims[claimId];
    }

    function getPropertyId(types.Property memory _property) public view returns (bytes32) {
        return Utils.getPropertyId(_property);
    }
}
