// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Receivooooor} from "./Receivooooor.sol";

contract ReceivooooorTest is Test {
    Receivooooor test;

    event Received();

    function setUp() public {
        test = new Receivooooor();
    }

    function testReceive() public {
        vm.expectEmit(false, false, false, false);
        emit Received();
        payable(test).transfer(1);
    }

    function testReceiveZeroAmount() public {
        vm.expectEmit(false, false, false, false);
        emit Received();
        payable(test).transfer(0);
    }
}
