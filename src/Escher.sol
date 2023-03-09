// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

contract Escher {
    uint256 constant private price = 0.000777 ether;
    uint256 constant private max_per_tx = 5;

    address immutable private owner;
    address immutable private receiver;
    address immutable private _this;

    constructor() {
        owner = msg.sender;
        receiver = msg.sender;
        _this = address(this);
    }

    function mint(uint256 start_index) external payable {
        address r = receiver;

        assembly {
            function R(ptr, s, size) {
                if iszero(s) { 
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize()) 
                }
                if gt(size, 0) {
                    returndatacopy(ptr, 0, size)
                }
            }

            let p := mload(0x40)
            let success
            
            /* purchase */
            mstore(p, 0xefef39a100000000000000000000000000000000000000000000000000000000) 
            mstore(add(p, 0x04), max_per_tx)

            success := call(gas(), 0x1bbec3ef715cce96b715bc0aa8fef8989f7ad3b2, callvalue(), p, 0x24, 0, 0)
            R(p, success, 0x00)

            /* transferFrom */
            mstore(p, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(p, 0x04), address())
            mstore(add(p, 0x24), r)

            for { let i := 0 } lt(i, max_per_tx) { i := add(i, 0x01) } { 
                mstore(add(p, 0x44), add(start_index, i))

                success := call(gas(), 0x1bbec3ef715cce96b715bc0aa8fef8989f7ad3b2, 0, p, 0x64, 0, 0)
                R(p, success, 0x00)
            }
        }
    }

    receive() external payable {
        require(msg.sender == owner, "owner");
        require(address(this) == _this, "no delegate call allowed");
        
        address o = owner;

        assembly {
            function R(ptr, s, size) {
                if iszero(s) { 
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize()) 
                }
                if gt(size, 0) {
                    returndatacopy(ptr, 0, size)
                }
            }

            let p := mload(0x40)
            let success

            if gt(callvalue(), 0) {
                let v := mul(price, max_per_tx)
                let n := div(callvalue(), v)

                if iszero(n) {
                    mstore(0x00, "n = 0")
                    revert(0x00, 0x20)
                }

                mstore(p, shl(0x60, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73))
                mstore(add(p, 0x14), shl(0x60, address()))
                mstore(add(p, 0x28), shl(0x88, 0x5af43d82803e903d91602b57fd5bf3))

                let proxy_pointer := p
                p := add(p, 0x40)

                /* totalsupply  */
                mstore(p, 0x18160ddd00000000000000000000000000000000000000000000000000000000)

                success := staticcall(gas(), 0x1BBEC3ef715ccE96b715bC0Aa8feF8989F7aD3B2, p, 0x04, 0, 0)
                R(p, success, returndatasize())

                let t := add(mload(p), 0x01)

                /* mint */
                mstore(p, 0xa0712d6800000000000000000000000000000000000000000000000000000000) 

                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } { 
                    let proxy_address := create(0, proxy_pointer, 0x37)

                    mstore(add(p, 0x04), add(t, mul(i, max_per_tx)))

                    success := call(gas(), proxy_address, v, p, 0x24, 0, 0)
                    R(p, success, 0x00)
                }
            }

            success := call(gas(), o, balance(address()), 0, 0, 0, 0)
            R(p, success, returndatasize())
        }
    }
}