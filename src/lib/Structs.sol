// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {RecipientType} from "./Recipient.sol";

/**
 * @notice "Transparent" struct that allows us to access the array of Recipient structs in calldata,
 *         since Solidity/Yul does not allow you to set the offset of a calldata array.
 */
struct CalldataPointer {
    RecipientType[] recipients;
}

struct Recipient {
    address payable recipient;
    uint16 bps;
}
