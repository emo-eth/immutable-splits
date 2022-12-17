// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Reenterooooor {
    uint256 numCalled;

    constructor() {}

    receive() external payable {
        if (numCalled < 1) {
            numCalled++;
            (bool success,) = msg.sender.call{value: 1}("");
            require(success);
        }
    }
}
