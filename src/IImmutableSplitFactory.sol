// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {RecipientType} from "./lib/Recipient.sol";

interface IImmutableSplitFactory {
    function createImmutableSplit(RecipientType[] calldata recipients) external returns (address payable);
    function getDeployedImmutableSplitAddress(RecipientType[] calldata recipients) external returns (address);
}
