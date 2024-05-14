// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RNIDO} from "../src/RNIDO.sol";
import "../src/BaseERC20.sol";

contract RNIDOTest is Test {
    RNIDO public rnido;
    BaseERC20 public token;
    address owner;
    address alice;
    address bom;

    function setUp() public {

        owner = makeAddr("owner");
        vm.startPrank(owner);
        token = new BaseERC20("TWC","tw",200);
        rnido = new RNIDO(token);
        token.transfer(address(rnido),200);
        rnido.initIDO( 1 ether ,100 ether , 200 ether  , block.timestamp + 1 hours);
        vm.stopPrank();

        alice = makeAddr("alice");
        vm.deal(alice, 100 ether);
        bom = makeAddr("bom");
        vm.deal(bom, 100 ether);

    }

    // 用户购买  &&  未达到软顶
    function test_buy() public {
    
       vm.startPrank(alice);
       rnido.buy{value: 1 ether}();
       vm.stopPrank();
       assertEq( alice.balance ,99 ether);

       vm.warp(block.timestamp + 2 hours);

       vm.startPrank(owner);
       rnido.refundOwner();
       vm.stopPrank();

       assertEq(token.balanceOf(address(owner)) , 200 );
    }
    // 未到达软顶，可以退eth
    function test_refund() public {

       vm.startPrank(alice);
       rnido.buy{value: 1 ether}();
       vm.stopPrank();

       vm.startPrank(alice);
       rnido.refund();
       vm.stopPrank();
       assertEq( alice.balance ,100 ether);
    }
    // 到达硬顶，用户可以提取token
    function test_withdrawToken() public {

       vm.startPrank(alice);
       rnido.buy{value: 100 ether}();
       vm.stopPrank();

       vm.startPrank(bom);
       rnido.buy{value: 100 ether}();
       vm.stopPrank();

       vm.startPrank(alice);
       rnido.withdrawToken();

       assertEq( alice.balance ,0);
       assertEq(token.balanceOf(alice) , 100);
    }

    // withdrawOwner 到达软顶 
    // 分为两种情况 余额是否超过硬顶，超过提取硬顶否提取余额 // owner

    function test_withdrawOwner() public {

       vm.startPrank(alice);
       rnido.buy{value: 100 ether}(); 
       vm.stopPrank();
       console.log(address(rnido).balance, 100 ether);
       assertEq( address(rnido).balance ,100 ether);
       vm.warp(block.timestamp);
       vm.startPrank(owner);
       rnido.withdrawOwner();
       vm.stopPrank();

       console.log(address(owner).balance, 100 ether);
       assertEq( address(owner).balance ,100 ether);

    }




    
}
