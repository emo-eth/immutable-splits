// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Receivooooor {
    event Received();

    receive() external payable {
        emit Received();
    }
}
