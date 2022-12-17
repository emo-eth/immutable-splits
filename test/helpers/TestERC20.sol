// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Test", "TST", 18) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
