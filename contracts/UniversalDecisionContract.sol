//works as an interface of predicates 
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import {DataTypes as types} from "./DataTypes.sol";

contract UniversalDecisionContract {
  uint DISPUTE_PERIOD = 7;
  mapping(bytes32 => types.ClaimStatus) public claims;
  mapping(bytes32 => bool) contradictions;

  function isWhiteListedProperty(types.Property memory _property) returns (bool) {
        return true;
    }

  function claimProperty(types.Property memory _claim) public {
    // get the id of this property
    bytes32 claimedPropertyId = Utils.getPropertyId(_claim);
    
    // make sure a claim on this property has not already been made
    require(Utils.isEmptyClaim(claims[claimedPropertyId]));

    // create the claim status. Always begins with no proven contradictions
    types.ClaimStatus memory status = types.ClaimStatus(_claim, 0, block.number + DISPUTE_PERIOD);

    // store the claim
    claims[claimedPropertyId] = status;
  }

  function decideProperty(types.Property memory _property, bool _decision) public {
    // only the prodicate can decide a claim 
    require(msg.sender == _property.predicate);
    bytes32 decidedPropertyId = Utils.getPropertyId(_property);

    // if the decision is true, automatically decide its claim now 
    if (_decision) {
        claims[decidedPropertyId].decidedAfter = block.number - 1;
    } else {
      //when decision is false -- delete its claim (all fields with this key got initialized)
      delete claims[_decidedPropertyId];
    }
  }

  function verifyImplicationProof(
    types.Property memory _rootPremise,
    types.ImplicationProofElement[] memory _implicationProof
  ) public returns (bool) {
    if (_implicationProof.length == 1) {
        // properties are always implications of themselves 
        return _rootPremise == _implicationProof[0].implication;
    }
    // check the first implication (i.e. with the rootPremise)
    require(Utils.isWhitelistedProperty(_rootPremise)); // make sure all properties are on the whitelist 
    require(_rootPremise.predicate.verifyImplication(_rootPremise.input, _implicationProof[0])); 
    for (const i = 0; i < _implicationProof.length -1; i++;) {
        types.Property premise = _implicationProof[i].implecation
        types.ImplicationProofElement implication = _implicationProof[i+1];
        require(Utils.isWhitelistedProperty(premise));

        //if this is the implication's conclusion property, also check that it is in fact whitelisted 
        if (i == _implicationProof.length - 1) {
            require(Utils.isWhitelistedProperty(implication));
        }
        require(premise.predicate.call(bytes4(keccak256(verifyImplication(premise.input, implication)))));
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
    types.Property implecation1 = _implicationProof1[_implicationProof1.length - 1].implecation;
    types.Property implecation2 = _implicationProof2[_implicationProof2.length - 1].implecation;
    require(implication1.predicate.call(bytes4(keccak256(verifyContradiction(implication1, implication2, _contradictionWitness)))));
  }

  function proveClaimContradictsDecision(
    types.Property memory _decidedProperty,
    types.ImplicationProofElement[] memory _decidedImplicationProof,
    types.Property memory _contradictingClaim,
    types.ImplicationProofElement[] memory _contradictionImplicationProof,
    bytes memory _contradictionWitness
  ) public {
    bytes21 decidedPropertyId = Utils.getPropertyId(_decidedProperty);
    bytes32 contraditingClaimId = Utils.getPropertyId(_contradictingClaim)

    // make sure the decided claim is decided 
    require(isDecided(decidedPropertyId));
    //make sure the two properties contradict one another 
    require(verifyContradictingImplications(_decidedProperty, _decidedImplicationProof, _contradictingClaim, _contradictingImplicationProof, _contradictionWitness));

    //delete the contradicting claim
    delete claims[contraditingClaimId]; 
  }

  function proveUndecidedContradiction(
    types.Contradiction memory _contradiction,
    types.ImplicationProofElement[] memory _implicationProof0,
    types.ImplicationProofElement[] memory _implicationProof1,
    bytes memory _contradictionWitness
  ) public {
    // get the unique ID corresponding to this contradiction
    bytes32 contradictionId = Utils.getContradictionId(_contradiction)
    propertyIds = [Utils.getPropertyId(_contradiction[0].property), getClaimId(_contradiction[1])]

    // make sure both cliams have been made and not decided false 
    require(!Utils.isEmptyClaim(claims[propertyIds[0]]) && !Utils.isEmptyClaim(claims[propertyIds[1]]);

    // make sure the contradicting properties have contradicting implications
    require(verifyContradictingImplications(_contradiction[0], _implicationProof0, _contradiction[1], _implicationProof1, _contradictionWitness));

    // increment the number of contradictions
    claims[propertyIds[0]].numProvenContradictions += 1;
    claims[propertyIds[1]].numProvenContradictions += 1;

    // store the unresolved contradiction
    contradictions[contradictionId] = true;
  }

  function removeContradiction(
    types.Contradiction memory _contradiction,
    uint remainingClaimIndex
  ) public {
    // get the claims and their Ids
    types.Contradiction remainingClaim = _contradiction[remainingClaimIndex];
    bytes32 remainingClaimId = getPropertyId(remainingClaim.property);
    types.Contradiction falsifiedClaim = _contradiction[!remainingClaimIndex];
    bytes32 falsifiedClaimId = getPropertyId(falsifiedClaim.property);

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

}