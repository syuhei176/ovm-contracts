pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {DataTypes as types} from "./DataTypes.sol";

contract UniversalDecisionContract {
  uint DISPUTE_PERIOD = 7;
  mapping (bytes32 => types.ClaimStatus) claims;
  mapping (bytes32 => bool) contradictions;

  function claimProperty(types.Property memory _claim) public {

  }

  function decideProperty(types.Property memory _claim, bool _decision) public {
  }

  function verifyImplication(
    types.Property memory _rootPremise,
    types.ImplicationProofElement[] memory _implicationProof
  ) public returns (bool) {
      return true;
  }

  function verifyContradictingImplications(
    types.Property memory _root1,
    types.ImplicationProofElement[] memory _implicationProof1,
    types.Property memory _root2,
    types.ImplicationProofElement[] memory _implicationProof2,
    bytes memory _contradictionWitness
  ) public returns (bool) {
    return true;
  }

  function proveClaimContradictsDecision(
    types.Property memory _decidedProperty,
    types.ImplicationProofElement[] memory _decidedImplicationProof,
    types.Property memory _contradictingClaim,
    types.ImplicationProofElement[] memory _contradictionImplicationProof,
    bytes memory _contradictionWitness
  ) public {

  }

  function proveUndecidedContradiction(
    types.Contradiction memory _contradiction,
    types.ImplicationProofElement[] memory _implicationProof0,
    types.ImplicationProofElement[] memory _implicationProof1,
    bytes memory _contradictionWitness
  ) public {

  }

  function removeContradiction(
    types.Contradiction memory _contradiction,
    uint _remainingClaimIndex
  ) public {
    require(_remainingClaimIndex == 0 || _remainingClaimIndex == 1, "ClaimIndex must be 0 or 1.");
  }
}