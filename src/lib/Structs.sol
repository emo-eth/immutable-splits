// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Recipient} from "./Recipient.sol";

/**
 * @notice "Transparent" struct that allows us to access the array of Recipient structs in calldata,
 *         since Solidity/Yul does not allow you to set the offset of a calldata array.
 */
struct CalldataPointer {
    Recipient[] recipients;
}
