// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from  "../lib//openzeppelin-contracts//contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { RNT } from "./RNT.sol";  // 项目方代币 RNT(自定义的ERC20)token 
import {ESRNT} from "./ESRNT.sol"; // 项目方Token(esRNT) -> NFT

contract RNTStake {

    RNT public rnt; //token
    ESRNT public esRNT; // nft

    // 质押挖矿
    mapping (address => Stake[]) public esStakes;
    mapping(address => Stake) public stakes;

    event _Stake(uint256);
    event Claim(uint256);
    event Unstake(uint256);

    struct Stake {
    uint256 debt; // 用户质押获取可以领取的 esRNT 数量
    uint256 lastUpdate; // 上次质押时间戳
    uint256 amount; // 质押的RNT数量
} 

    //挖矿速率（单位时间产生的币）
    uint256 public mintSpeedPersecond = uint256(1e18) / 24*60*60;
    uint256 public  constant TIRTY_DAYS  = 30 * 24 * 60 * 60;
    uint256 public constant esTokenSpeedPersecond = uint256(1e18) / TIRTY_DAYS;

    constructor(RNT _rnt, ESRNT _esRNT){
        rnt  = _rnt;
        esRNT = _esRNT;
    }

    modifier before() {

        Stake memory stk = stakes[msg.sender];
         if(stk.amount > 0){
            stk.debt += stk.amount * (block.timestamp - stk.lastUpdate) * mintSpeedPersecond/1e18;
            stk.lastUpdate = block.timestamp;
        }
        _;
    }
    

    // 质押挖矿逻辑  用户质押rnt代币 
    // 1. 判断用户是否有质押，如果有 则更新用户的质押挖矿奖励金额 和 挖矿时间； 挖矿奖励 = 质押数量 * 挖矿时间 * 挖矿速率（单位内产生的币）
    // 2. 用户将代币转移到合约， 3.更新用户的质押数量 

    function stake (uint256 _amount) external  before{

        Stake storage stk = stakes[msg.sender];
        rnt.transferFrom(msg.sender, address(this) , _amount );
        stk.amount += _amount; 

        emit _Stake(_amount);
    }

       // 如果有质押 随时解押提取已质押的 RNT；
       function claim() external before {
        Stake storage stk = stakes[msg.sender];
        if (stk.debt > 0) {
            esRNT.mint(msg.sender, stk.debt);
        }
        stk.debt = 0;

        emit  Claim(stk.debt);
    }

     // 用户可以随时提取已经质押的代币 rnt 
    // 1.确保用户有足够的提取金额，更新用户提取代币状态 并提取

    function unstake( uint256 _amount) public {

        Stake memory stk = stakes[msg.sender];
        require(stk.amount >= _amount, "error: stk.amount < _amount");
        stk.amount -= _amount;
        rnt.transfer(msg.sender,_amount);
        emit Unstake(_amount);
    }

   
 
}