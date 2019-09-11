pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/* Internal Contract Imports */
import "./Utils.sol";
import {DataTypes as types} from "./DataTypes.sol";

/* Imports to run a test*/
contract Predicate {
    function verifyImplication(bytes memory, types.ImplicationProofElement memory) public returns (bool) {}
    function verifyContradiction(types.Property memory, types.Property memory, bytes memory) public returns (bool) {}
}

contract UniversalAdjudicationContract {

    uint DISPUTE_PERIOD = 7;
    mapping (bytes32 => types.ClaimStatus) public claims;
    mapping (bytes32 => bool) contradictions;
    enum RemainingClaimIndex {Property, CounterProperty}

    function claimProperty(bytes memory _claimBytes) public {
        (address predicate, bytes memory input) = abi.decode(_claimBytes, (address, bytes));
        types.Property memory claim = types.Property({
            predicateAddress: predicate,
            input: input
        });
        // get the id of this property
        bytes32 claimedPropertyId = Utils.getPropertyId(claim);
        // make sure a claim on this property has not already been made
        require(Utils.isEmptyClaim(claims[claimedPropertyId]));

        // create the claim status. Always begins with no proven contradictions
        types.ClaimStatus memory status = types.ClaimStatus(claim, 0, block.number + DISPUTE_PERIOD);

        // store the claim
        claims[claimedPropertyId] = status;
    }

    function decideProperty(types.Property memory _property, bool _decision) public {
        // only the prodicate can decide a claim
        require(msg.sender == _property.predicateAddress);
        bytes32 decidedPropertyId = Utils.getPropertyId(_property);

        // if the decision is true, automatically decide its claim now
        if (_decision) {
            claims[decidedPropertyId].decidedAfter = block.number - 1;
        } else {
        // when decision is false -- delete its claim (all fields with this key got initialized)
        delete claims[decidedPropertyId];
        }
    }

    function verifyImplicationProof(
        types.Property memory _rootPremise,
        types.ImplicationProofElement[] memory _implicationProof
    ) public returns (bool) {
        if (_implicationProof.length == 1) {
            // properties are always implications of themselves
            return _rootPremise.predicateAddress == _implicationProof[0].implication.predicateAddress
                && keccak256(_rootPremise.input) == keccak256(_implicationProof[0].implication.input);
        }
        // check the first implication (i.e. with the rootPremise)
        require(isWhiteListedProperty(_rootPremise)); // make sure all properties are on the whitelist
        require(Predicate(_rootPremise.predicateAddress).verifyImplication(_rootPremise.input, _implicationProof[1]));
        for (uint i = 0; i < _implicationProof.length -1; i++) {
            types.Property memory premise = _implicationProof[i].implication;
            types.ImplicationProofElement memory implication = _implicationProof[i+1];
            require(isWhiteListedProperty(premise));

            // if this is the implication's conclusion property, also check that it is in fact whitelisted
            if (i == _implicationProof.length - 1) {
                require(isWhiteListedProperty(_implicationProof[i].implication));
            }
            require(Predicate(premise.predicateAddress).verifyImplication(premise.input, implication));
        }
    }

    function verifyContradictingImplications(
        types.Property memory _root1,
        types.ImplicationProofElement[] memory _implicationProof1,
        types.Property memory _root2,
        types.ImplicationProofElement[] memory _implicationProof2,
        bytes memory _contradictionWitness
    ) public returns (bool) {
        require(verifyImplicationProof(_root1, _implicationProof1));
        require(verifyImplicationProof(_root2, _implicationProof2));
        types.Property memory implication1 = _implicationProof1[_implicationProof1.length - 1].implication;
        types.Property memory implication2 = _implicationProof2[_implicationProof2.length - 1].implication;
        require(Predicate(implication1.predicateAddress).verifyContradiction(implication1, implication2, _contradictionWitness));
        return true;
    }

    function proveClaimContradictsDecision(
        bytes memory _decidedProperty,
        bytes[] memory _decidedImplicationProof,
        bytes memory _contradictingClaim,
        bytes[] memory _contradictionImplicationProof,
        bytes memory _contradictionWitness
    ) public {
        types.Property memory decidedProperty = decodeProperty(_decidedProperty);
        types.ImplicationProofElement[] memory decidedImplicationProof = new types.ImplicationProofElement[](_decidedImplicationProof.length);
        for(uint i = 0;i < _decidedImplicationProof.length; i++) {
            decidedImplicationProof[i] = decodeImplicationProof(_decidedImplicationProof[i]);
        }
        types.Property memory contradictingClaim = decodeProperty(_contradictingClaim);
        types.ImplicationProofElement[] memory contradictionImplicationProof = new types.ImplicationProofElement[](_contradictionImplicationProof.length);
        for(uint i = 0;i < _contradictionImplicationProof.length; i++) {
            contradictionImplicationProof[i] = decodeImplicationProof(_contradictionImplicationProof[i]);
        }

        bytes32 contraditingClaimId = Utils.getPropertyId(contradictingClaim);

        // make sure the decided property is already decided before the current block number
        require(isDecided(decidedProperty));
        // make sure the two properties contradict one another
        require(verifyContradictingImplications(decidedProperty, decidedImplicationProof, contradictingClaim, contradictionImplicationProof, _contradictionWitness));
        // delete the contradicting claim
        delete claims[contraditingClaimId];
    }

    function proveUndecidedContradiction(
        bytes memory _contradiction,
        bytes[] memory _implicationProof0,
        bytes[] memory _implicationProof1,
        bytes memory _contradictionWitness
    ) public {
        types.Contradiction memory contradiction = decodeContradiction(_contradiction);
        types.ImplicationProofElement[] memory implicationProof0 = new types.ImplicationProofElement[](_implicationProof0.length);
        types.ImplicationProofElement[] memory implicationProof1 = new types.ImplicationProofElement[](_implicationProof1.length);
        for(uint i = 0;i < _implicationProof0.length; i++) {
            implicationProof0[i] = decodeImplicationProof(_implicationProof0[i]);
        }
        for(uint i = 0;i < _implicationProof1.length; i++) {
            implicationProof1[i] = decodeImplicationProof(_implicationProof1[i]);
        }

        // get the unique ID corresponding to this contradiction
        bytes32 contradictionId = Utils.getContradictionId(contradiction);
        bytes32[2] memory propertyIds = [Utils.getPropertyId(contradiction.property), Utils.getPropertyId(contradiction.counterProperty)];

        // make sure both cliams have been made and not decided false
        require(!Utils.isEmptyClaim(claims[propertyIds[0]]) && !Utils.isEmptyClaim(claims[propertyIds[1]]));

        // make sure the contradicting properties have contradicting implications
        require(verifyContradictingImplications(contradiction.property, implicationProof0, contradiction.counterProperty, implicationProof1, _contradictionWitness));

        // increment the number of contradictions
        claims[propertyIds[0]].numProvenContradictions += 1;
        claims[propertyIds[1]].numProvenContradictions += 1;

        // store the unresolved contradiction
        contradictions[contradictionId] = true;
    }

    function removeContradiction(
        types.Contradiction memory _contradiction,
        RemainingClaimIndex _remainingClaimIndex // 0:xxx 1:xxx
        ) public {
        bytes32 remainingClaimId;
        bytes32 falsifiedClaimId;
        types.Property memory remainingClaim;
        types.Property memory falsifiedClaim;

        // get the claims and their Ids when property is the true one
        if (RemainingClaimIndex.Property == _remainingClaimIndex) {
            remainingClaim = _contradiction.property;
            falsifiedClaim = _contradiction.counterProperty;
            falsifiedClaimId = Utils.getPropertyId(falsifiedClaim);
        } else {
            remainingClaim = _contradiction.counterProperty;
            falsifiedClaim = _contradiction.property;
        }
        remainingClaimId = Utils.getPropertyId(remainingClaim);
        falsifiedClaimId = Utils.getPropertyId(falsifiedClaim);

        // get the contradiction Id
        bytes32 contradictionId = Utils.getContradictionId(_contradiction);

        // make sure the falsified claim was decided false
        require(Utils.isEmptyClaim(claims[falsifiedClaimId]));

        // make sure the contradiction is still unresolved
        require(contradictions[contradictionId]);

        // resolve the contradiction
        contradictions[contradictionId] = false;

        // decrement the remaining claim numProvenContradictions
        claims[remainingClaimId].numProvenContradictions -= 1;
    }


    /* Helpers */
    function isWhiteListedProperty(types.Property memory _property) private returns (bool) {
        return true; // Always return true until we know what to whitelist
    }

    function isDecided(types.Property memory _property) public returns (bool) {
        return claims[Utils.getPropertyId(_property)].decidedAfter < block.number;
    }

    function getClaim(bytes32 claimId) public view returns (types.Property memory) {
        return claims[claimId].property;
    }

    function getPropertyId(types.Property memory _property) public view returns (bytes32) {
        return Utils.getPropertyId(_property);
    }

    function decodeProperty(bytes memory _propertyBytes) private pure returns (types.Property memory) {
        (address predicate, bytes memory input) = abi.decode(_propertyBytes, (address, bytes));
        return types.Property({
            predicateAddress: predicate,
            input: input
        });
    }

    function decodeImplicationProof(bytes memory _implicationProof) private pure returns (types.ImplicationProofElement memory) {
        (bytes memory implication, bytes[] memory witness) = abi.decode(_implicationProof, (bytes, bytes[]));
        return types.ImplicationProofElement({
            implication: decodeProperty(implication),
            witness: witness
        });
    }

    function decodeContradiction(bytes memory _contradictionBytes) private pure returns (types.Contradiction memory) {
        (bytes memory property, bytes memory counterProperty) = abi.decode(_contradictionBytes, (bytes, bytes));
        return types.Contradiction({
            property: decodeProperty(property),
            counterProperty: decodeProperty(counterProperty)
        });
    }
}