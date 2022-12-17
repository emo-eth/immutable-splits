// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error InvalidBps(uint256 bps);
error InvalidTotalBps(uint256 totalBps);
error RecipientsMustBeSortedByAscendingBpsAndAddress();
error NotASmartContract();
error NotRecipient();
error CannotProxyApproveErc20();
