// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RNTStake } from "../src/RNTstake.sol";
import {ESRNT} from "../src/ESRNT.sol";
import {RNT} from "../src/RNT.sol";

contract RNTStakeTest is Test {
    RNTStake public rntstake;
    RNT public rnt;
    ESRNT public esrnt;
    address owner;
    // address alice;
    // address bom;
    address admin;

    function setUp() public {

        admin = makeAddr("admin");
        vm.startPrank(admin);
        
        rnt = new RNT();
        esrnt = new ESRNT("TWC","T",admin);
        rntstake = new RNTStake(rnt,esrnt);
        rnt.mint(admin, 200 * 1e18);
        rnt.setstakeContract(address(rntstake));
        esrnt.setstakeContract(address(rntstake));
        vm.stopPrank();

    }

    function test_stake () public {

        vm.startPrank(admin);
        rnt.approve(address(rntstake), 200 * 1e18);
        rntstake.stake(100 * 1e18); 
        vm.warp(block.timestamp + 1 days);
        rntstake.stake(100 * 1e18); 
        vm.warp(block.timestamp + 1 days);
        rntstake.unstake(200 * 1e18);   
        console.log(rnt.balanceOf(admin),9999999);
        assertEq(rnt.balanceOf(admin), 200 * 1e18);

    }


    function test_claim () public {

        test_stake ();
        rntstake.claim();
        assertEq(rnt.balanceOf(admin), 200 * 1e18);
    }

 
    
}
