// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Escher.sol";

contract ContractTest is Test {

    Escher escher;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("archive_mainnet"));

        vm.deal(alice, 100 ether);
        vm.startPrank(alice, alice);

        escher = new Escher();
    }

    function testMint() public {
        uint256 price = 0.000777 ether;
        uint256 q = 5 * 5;

        (bool success, bytes memory response) = address(escher).call{value: price * q}("");
        require(success, string(response));

        (success, response) = address(0x1BBEC3ef715ccE96b715bC0Aa8feF8989F7aD3B2).call(abi.encodeWithSignature("balanceOf(address)", alice));
        uint256 b = abi.decode(response, (uint256));
        assertEq(b, q);
    }
    
}