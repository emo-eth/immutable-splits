// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";
import {Recipient} from "../src/Structs.sol";
import {ImmutableSplit} from "../src/ImmutableSplit.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract ImmutableSplitsTest is Test {
    ImmutableSplit impl;

    function setUp() public {
        impl = new ImmutableSplit();
    }

    function testGetRecipients() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), 1000);
        recipients[1] = Recipient(payable(address(0x2)), 2000);
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);
        ImmutableSplit clone =
            ImmutableSplit(payable(Create2ClonesWithImmutableArgs.clone(address(impl), data, bytes32(0))));
        Recipient[] memory cloneRecipients = clone.getRecipients();
        assertEq(keccak256(abi.encode(cloneRecipients)), keccak256(abi.encode(recipients)));
    }

    function testSplit() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), 1000);
        recipients[1] = Recipient(payable(address(0x2)), 9000);
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);

        ImmutableSplit clone =
            ImmutableSplit(payable(Create2ClonesWithImmutableArgs.clone(address(impl), data, bytes32(0))));
        SafeTransferLib.safeTransferETH(payable(address(clone)), 1 ether);
        assertEq(address(0x1).balance, 0.1 ether);
        assertEq(address(0x2).balance, 0.9 ether);
    }
}
