// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Recipient} from "./Structs.sol";

interface IImmutableSplit {
    function getRecipients() external view returns (Recipient[] memory);
    function splitErc20(address token) external;
    function proxyCall(address target, bytes calldata callData) external returns (bytes memory);
    function receiveHook() external payable;
    receive() external payable;
}
