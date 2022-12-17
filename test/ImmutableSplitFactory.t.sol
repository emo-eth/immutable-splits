// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ImmutableSplit} from "../src/ImmutableSplit.sol";
import {Recipient} from "../src/Structs.sol";
import {ImmutableSplitFactory} from "../src/ImmutableSplitFactory.sol";
import {
    InvalidBps,
    InvalidTotalBps,
    RecipientsMustBeSortedByAscendingBpsAndAddress,
    AlreadyDeployed
} from "../src/Errors.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";

contract ImmutableSplitFactoryTest is Test {
    ImmutableSplitFactory test;
    ImmutableSplit impl = new ImmutableSplit();

    function setUp() public {
        test = new ImmutableSplitFactory(address(impl));
    }

    function testFactory() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient(payable(address(1)), 10000);
        address payable split = test.createImmutableSplit(recipients);
        assertEq(ImmutableSplit(split).getRecipients()[0].recipient, address(1));
        assertEq(ImmutableSplit(split).getRecipients()[0].bps, 10000);

        recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(1)), 5000);
        recipients[1] = Recipient(payable(address(2)), 5000);
        split = test.createImmutableSplit(recipients);
        assertEq(ImmutableSplit(split).getRecipients()[0].recipient, address(1));
        assertEq(ImmutableSplit(split).getRecipients()[0].bps, 5000);
        assertEq(ImmutableSplit(split).getRecipients()[1].recipient, address(2));
        assertEq(ImmutableSplit(split).getRecipients()[1].bps, 5000);
    }

    function testFactoryInvalidTotal() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(1)), 5000);
        recipients[1] = Recipient(payable(address(2)), 5001);
        vm.expectRevert(abi.encodeWithSelector(InvalidTotalBps.selector, 10001));
        test.createImmutableSplit(recipients);

        recipients[0].bps = 4999;
        recipients[1].bps = 5000;
        vm.expectRevert(abi.encodeWithSelector(InvalidTotalBps.selector, 9999));
        test.createImmutableSplit(recipients);
    }

    function testFactoryInvalidBps() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient(payable(address(1)), 0);
        vm.expectRevert(abi.encodeWithSelector(InvalidBps.selector, 0));
        test.createImmutableSplit(recipients);

        recipients[0].bps = 10001;
        vm.expectRevert(abi.encodeWithSelector(InvalidBps.selector, 10001));
        test.createImmutableSplit(recipients);
    }

    function testFactoryRedeploySplit() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient(payable(address(1)), 10000);
        address payable split = test.createImmutableSplit(recipients);

        vm.expectRevert(abi.encodeWithSelector(AlreadyDeployed.selector, split));
        split = test.createImmutableSplit(recipients);
    }

    function testFactory_AscendingBps() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(1)), 6000);
        recipients[1] = Recipient(payable(address(2)), 4000);
        vm.expectRevert(abi.encodeWithSelector(RecipientsMustBeSortedByAscendingBpsAndAddress.selector));
        test.createImmutableSplit(recipients);
    }

    function testFactory_AscendingAddress() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(2)), 5000);
        recipients[1] = Recipient(payable(address(1)), 5000);
        vm.expectRevert(abi.encodeWithSelector(RecipientsMustBeSortedByAscendingBpsAndAddress.selector));
        test.createImmutableSplit(recipients);
    }

    function testGetImmutableSplitAddress() public {
        Recipient[] memory recipients = new Recipient[](1);
        recipients[0] = Recipient(payable(address(1)), 10000);
        address payable split = test.createImmutableSplit(recipients);
        assertEq(test.getImmutableSplitAddress(recipients), split);
    }
}
