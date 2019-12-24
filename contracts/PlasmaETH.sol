pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DepositContract.sol";

contract PlasmaETH is ERC20 {
    address public depositContractAddress;
    constructor() public {}

    function setDepositContractAddress(address _depositContractAddress) public {
        depositContractAddress = _depositContractAddress;
    }

    /**
     * @dev deposit is the way to skip wrap and approve in deposit flow.
     * This method execute deposit flow automatically.
     */
    function deposit(uint256 _amount, types.Property memory _initialState)
        public
        payable
    {
        wrap(_amount);
        require(
            approve(depositContractAddress, _amount),
            "must succeed to approve"
        );
        DepositContract(depositContractAddress).deposit(_amount, _initialState);
    }

    /**
     * @dev wrap ETH in PlasmaETH
     */
    function wrap(uint256 _amount) public payable {
        require(
            _amount == msg.value,
            "_amount and msg.value must be same value"
        );
        _mint(msg.sender, _amount);
    }

    /**
     * @dev unwrap PlasmaETH
     */
    function unwrap(uint256 _amount) public {
        require(
            balanceOf(msg.sender) >= _amount,
            "PlasmaETH: unwrap amount exceeds balance"
        );
        _burn(msg.sender, _amount);
        msg.sender.transfer(_amount);
    }

}
