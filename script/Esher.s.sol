// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Escher.sol";

contract ContractScript is Script {
    
    function run() public {
        vm.startBroadcast();

        new Escher();
    }

    function mint(address e, uint256 iter) public {
        vm.startBroadcast();

        uint256 price = 0.000777 ether;
        uint256 q = 5 * iter;

        (bool success, bytes memory response) = e.call{value: price * q}("");
        require(success, string(response));
    }
}