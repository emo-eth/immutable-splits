// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SelfDestructooooor {
    constructor() payable {}

    function selfDestruct(address target) public {
        selfdestruct(payable(target));
    }
}
