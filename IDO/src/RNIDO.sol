// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import  "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract RNIDO {
    IERC20  public  token;
    address public  owner;
    uint256 public  price; // 每个token 的价格 // 筹集的是
    uint256 public softCap; // 软顶 众筹最低金额 单位 wei
    uint256 public hardCap; // 硬顶 众筹最高金额 单位 wei
    uint256 public endTime; // 众筹结束时间
    uint256 public endBalance;  // 众筹结束时的总以太币数额。 
    uint256 public tokenSaleAmount; //众筹的代币总量。

    mapping (address => uint256) balances; // 记录每个参与者的金额

    using Address for address payable ;

    event InitIDO(uint256 price,uint256 softCap,uint256 hardCap,uint256 endTime);
    event Buy(uint256);
    event Refund(uint256);
    event WithdrawToken(uint256);
    event WithdrawOwner(uint256);
    event RefundOwner(uint256);

    constructor(IERC20 _token){

        token = _token;
        owner = msg.sender;

    }
    function initIDO ( uint256 _price, uint256 _softCap, uint256 _hardCap,uint256 _endTime) public {

        require(msg.sender == owner, 'no owner');

        // 众筹是以代币的形式进行的 代币的数量符合设定的硬顶金额
        tokenSaleAmount = token.balanceOf(address(this)); // 当前合约代币的数量

        require(tokenSaleAmount == _hardCap / _price, "Please transfer enough tokens in IDO contract");
        require(_endTime > block.timestamp, "Please transfer enough tokens in IDO contract");
        require(_softCap < _hardCap, "error softCap > hardCap");

        price = _price;
        softCap = _softCap;
        hardCap = _hardCap;
        endTime = _endTime;

        emit InitIDO( _price,_softCap,_hardCap,_endTime);

    }

    // 用户购买 ，筹集的是token， 用户付eth，买走token
    // 1. 判断募集是否结束 2.付的eth要大于0 3. 判断用户是否已经购买过，如果没有，则本次付的eth数量
    // 如果已经购买过，需要本次付的eth+之前的数量加起来做记录 4.将用户付的以太币添加记录
    function buy() external payable {

       require(block.timestamp < endTime, "Crowdfunding has ended");

       uint256 balance = balances[msg.sender];

       if(balance == 0 ){

        balances[msg.sender] = msg.value;

       } else {

        balances[msg.sender] = balance + msg.value;

       }

       endBalance += msg.value; // 记录总的eth的数量
       emit Buy( endBalance);
    
    }

    // 未达到软顶 ，用户可以退款
    // 1.判断是否过期  2.eth总金额为达到软顶 3.判断用户的eft > 0 则可以退费 
    // 4.余额设置为0  5.提取所有eth  payable(msg.sender).sendValue(investAmount);
    function refund() public{
        require(block.timestamp < endTime, "Crowdfunding has ended");
        require(tokenSaleAmount < softCap, "tokenSaleAmount < softCap");

        uint256 balance = balances[msg.sender];
        require(balance > 0, "user eth < 0");
        balances[msg.sender] = 0;

        payable(msg.sender).sendValue(balance); // sendValue 是library ，使用usingy语法 == sendValue（msg.sender，balance）

        emit Refund(balance);

        

    }
    // 到达硬顶 ，用户可以提取token 
    // 1.判断是否过期，2.判断筹集的eft 到达硬顶 3.分情况处理，是否超过硬顶，未超过则 给用户转 用户的eth设置为0
    // 超过了则  需要退  
    //tokenSaleAmount 众筹代币数量      investBalance 用户的众筹中投资的代币   endBalance 众筹结束时的代币总量
    function withdrawToken() public {

        require(block.timestamp < endTime, "Crowdfunding has ended");
        require(endBalance >= hardCap , "endBalance "); // 众筹总的eth是否超过硬顶

        uint256 investBalance = balances[msg.sender];

        if(endBalance <=  hardCap ){ //未超过 hardCap  不需要退，用户拿到 投的 eth 对应数量的token

          token.transfer(msg.sender, investBalance / price); 
          balances[msg.sender] = 0;

        }else { // 超过 hardCap  1.转给用户应该获得的token , 退还用户的eth 

        // 用户应该获得的数量 = 总数量 * 用户投资金额占总金额的比例
        uint256 tokenAmount = tokenSaleAmount * investBalance / endBalance;
        token.transfer(msg.sender, tokenAmount);
        balances[msg.sender] = 0;

        // 退还给用户的eth  用户投资的总的 eth - 用户获得的token数量 * token的单价
         uint256 ethValue = investBalance - (tokenAmount * price);
         payable(msg.sender).sendValue(ethValue); 

         emit WithdrawToken(ethValue)
   
        }

        
    }
    // 到达软顶
    function withdrawOwner() public {

        require(msg.sender == owner, "Only owner can withdraw");
        // require(block.timestamp < endTime, "Crowdfunding has ended");
        require(endBalance >= softCap , "endBalance "); // 众筹总的eth是否超过硬顶

        if(endBalance >= hardCap){
 
            // 超过硬顶处理逻辑  如果合约的余额 < 硬顶 ，提取合约的余额给到管理员，反之把硬顶的余额给到管理员  202 
           uint256 min = address(this).balance < hardCap ? address(this).balance : hardCap;  // 取合约余额 和 硬顶最小
           payable(owner).sendValue(min);
              
        }else { // 超过软顶没超过硬顶，管理员提取对应的eth和token
       // 真正筹到的eth的数量 = 众筹etn的总量- 结束时的数量*单价 
        //   uint256 ownerWithdrawAmount =   tokenSaleAmount - endBalance * price ; // 

          token.transfer( owner,token.balanceOf(address(this)));

          payable(owner).sendValue(endBalance);

         emit WithdrawOwner(endBalance);

        }

    }

    // 未达到软顶，管理员可以提取token

    function refundOwner() public {

        require(msg.sender == owner, "no owner");

        require(block.timestamp > endTime, "Crowdfunding has ended");
        require(endBalance < softCap, 'not softCap');

        token.transfer(owner, tokenSaleAmount);
        emit RefundOwner(tokenSaleAmount);

    }
   
}

// 编写 IDO 合约，实现 Token 预售，需要实现如下功能：

// 开启预售: 支持对给定的任意ERC20开启预售，设定预售价格，募集ETH目标，超募上限，预售时长。
// 任意用户可支付ETH参与预售；
// 预售结束后，如果没有达到募集目标，则用户可领会退款；
// 预售成功，用户可领取 Token，且项目方可提现募集的ETH；