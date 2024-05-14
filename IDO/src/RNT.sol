// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RNT is ERC20, Ownable {

    address public stakeContract; // 被授权铸币的合约地址

    event Mint(address indexed to ,uint256 amount );

    constructor() ERC20("TWC","twc") Ownable(msg.sender){}
    
    // Ownable 里的modifier
    function setstakeContract (address _stakeContract) public onlyOwner {
     stakeContract = _stakeContract;

    }

    function mint(address to, uint256 amount) public{
        require(msg.sender == stakeContract || msg.sender  == owner() ,  "no owner || no stakeContract");

        _mint(to, amount);

        emit Mint(to,amount);
    }


}