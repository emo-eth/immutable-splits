// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Recipient} from "./lib/Recipient.sol";

interface IImmutableSplitFactory {
    function createImmutableSplit(Recipient[] calldata recipients) external returns (address payable);
    function getDeployedImmutableSplitAddress(Recipient[] calldata recipients) external returns (address);
}
