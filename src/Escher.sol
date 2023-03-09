// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

contract Escher {
    bytes constant private code1 = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73";
    bytes constant private code2 = hex"5af43d82803e903d91602b57fd5bf3";

    uint256 constant private price = 0.000777 ether;
    uint256 constant private max_per_tx = 5;

    address immutable owner;
    address immutable receiver;
    address immutable _this;

    constructor() {
        owner = msg.sender;
        receiver = msg.sender;
        _this = address(this);
    }

    function mint(uint256 start_index) external payable {
        require(msg.sender == _this, "delegater");

        address r = receiver;
        uint256 x = max_per_tx;

        assembly {
            let p := mload(0x40)

            mstore(p, 0xefef39a100000000000000000000000000000000000000000000000000000000) // purchase(uint256)
            mstore(add(p, 0x04), x)

            let success := call(gas(), 0x1bbec3ef715cce96b715bc0aa8fef8989f7ad3b2, callvalue(), p, 0x24, 0, 0)
            if eq(success, 0) {
                returndatacopy(p, 0, returndatasize())
                revert(p, returndatasize())
            }

            mstore(p, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // transferFrom(address,address,uint256)
            mstore(add(p, 0x04), address())
            mstore(add(p, 0x24), r)

            for { let i := 0 } lt(i, x) { i := add(i, 0x01) } { 
                mstore(add(p, 0x44), add(start_index, i))

                success := call(gas(), 0x1bbec3ef715cce96b715bc0aa8fef8989f7ad3b2, 0, p, 0x64, 0, 0)
                if eq(success, 0) {
                    returndatacopy(p, 0, returndatasize())
                    revert(p, returndatasize())
                }
            }
        }
    }

    receive() external payable {
        require(msg.sender == owner, "owner");
        require(address(this) == _this, "no delegate call allowed");

        if (msg.value > 0) {

            uint256 x = max_per_tx;
            uint256 v = price * x;
            uint256 n = msg.value / v;

            if (n == 0) {
                revert("n = 0");
            }

            uint256 t;
            bytes memory proxy = abi.encodePacked(code1, address(this), code2);

            assembly {
                let p := mload(0x40)

                mstore(p, 0x18160ddd00000000000000000000000000000000000000000000000000000000) // totalSupply()

                let success := staticcall(gas(), 0x1BBEC3ef715ccE96b715bC0Aa8feF8989F7aD3B2, p, 0x04, 0, 0)
                returndatacopy(p, 0, returndatasize())
                if eq(success, 0) {
                    revert(p, returndatasize())
                }

                t := add(mload(p), 0x01)
            }   


            assembly {
                let p := mload(0x40)

                mstore(p, 0xa0712d6800000000000000000000000000000000000000000000000000000000) // mint(uint256)

                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } { 
                    let pr := create(0, add(proxy, 0x20), mload(proxy))

                    mstore(add(p, 0x04), add(t, mul(i, x)))

                    let success := call(gas(), pr, v, p, 0x24, 0, 0)
                    if eq(success, 0) {
                        returndatacopy(p, 0, returndatasize())
                        revert(p, returndatasize())
                    }
                }
            }
        }

        (bool success, bytes memory response) = owner.call{value: address(this).balance}("");
        require(success, string(response));
    }
}