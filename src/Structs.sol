// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Recipient} from "./Recipient.sol";

// /**
//  * @notice Struct that encodes the recipient address and the bps (basis points) of the split.
//  */
// struct Recipient {
//     address payable recipient;
//     uint256 bps;
// }

/**
 * @notice "Transparent" struct that allows us to access the array of Recipient structs in calldata,
 *         since Solidity/Yul does not allow you to set the offset of a calldata array.
 */
struct CalldataPointer {
    Recipient[] recipients;
}
