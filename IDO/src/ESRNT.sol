// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ESRNT is ERC20, Ownable {

    address public stakeContract; // 被授权铸币的合约地址

    event Mint(address indexed to ,uint256 amount );

    constructor(string memory name, string memory symbol, address initialOwner ) ERC20(name,symbol) Ownable(initialOwner){}
    
    // Ownable 里的modifier
    function setstakeContract (address _stakeContract) public onlyOwner {
     stakeContract = _stakeContract;

    }

    function mint(address to, uint256 amount) public{
        
        require(msg.sender == stakeContract || msg.sender  == owner() ,  "no owner || no stakeContract");

        _mint(to, amount);

        emit Mint(to,amount);
    }

    // 代币销毁就是把对应数量的代币转移到 address(0)

     function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
     
    //  function _burn(address account, uint256 value) internal {
    //     if (account == address(0)) {
    //         revert ERC20InvalidSender(address(0));
    //     }
    //     _update(account, address(0), value);
    // }

}