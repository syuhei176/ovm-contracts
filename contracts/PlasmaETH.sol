pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DepositContract.sol";

contract PlasmaETH is ERC20 {
    address public depositContractAddress;
    constructor(address _depositContractAddress) public {
        depositContractAddress = _depositContractAddress;
    }

    /**
     * PlasmaETH.deposit execute deposit flow automatically.
     */
    function deposit(uint256 _amount, types.Property memory _initialState)
        public
        payable
    {
        _mint(msg.sender, msg.value);
        require(
            approve(depositContractAddress, _amount),
            "must succeed to approve"
        );
        DepositContract(depositContractAddress).deposit(_amount, _initialState);
    }
}
