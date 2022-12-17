// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, Vm} from "forge-std/Test.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";
import {Recipient} from "../src/Structs.sol";
import {ImmutableSplit} from "../src/ImmutableSplit.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {NotASmartContract, CannotApproveErc20} from "../src/Errors.sol";
import {TestERC20} from "./helpers/TestERC20.sol";
import {SelfDestructooooor} from "./helpers/SelfDestructooooor.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Revertooooor} from "./helpers/Revertooooor.sol";
import {Reenterooooor} from "./helpers/Reenterooooor.sol";

contract ImmutableSplitsTest is Test {
    ImmutableSplit impl;
    TestERC20 erc20;

    function setUp() public {
        impl = new ImmutableSplit();
        erc20 = new TestERC20();
        erc20.mint(address(this), 1 ether);
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

    function testSplitSkipsZeroAmount() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), 1);
        recipients[1] = Recipient(payable(address(0x2)), 9999);
        ImmutableSplit clone = _deployClone(recipients);

        SafeTransferLib.safeTransferETH(payable(address(clone)), 500);
        assertEq(address(0x1).balance, 0);
        assertEq(address(0x2).balance, 499);
    }

    function testSplitSkipsZeroBalance() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), 5000);
        recipients[1] = Recipient(payable(address(0x2)), 5000);
        ImmutableSplit clone = _deployClone(recipients);

        SafeTransferLib.safeTransferETH(payable(address(clone)), 0);
        assertEq(address(0x1).balance, 0);
        assertEq(address(0x2).balance, 0);
    }

    function testSplitNonzeroBalance() public {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), 5000);
        recipients[1] = Recipient(payable(address(0x2)), 5000);
        ImmutableSplit clone = _deployClone(recipients);

        (new SelfDestructooooor{value: 1 ether}()).selfDestruct(address(clone));

        SafeTransferLib.safeTransferETH(payable(address(clone)), 0);
        assertEq(address(0x1).balance, 0.5 ether);
        assertEq(address(0x2).balance, 0.5 ether);
    }

    function testSplitErc20() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        SafeTransferLib.safeTransfer(erc20, address(clone), 1 ether);
        clone.splitErc20(erc20);
        assertEq(erc20.balanceOf(address(0x1)), 0.5 ether);
        assertEq(erc20.balanceOf(address(0x2)), 0.5 ether);
    }

    function testSplitErc20_zeroBalance() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        vm.recordLogs();
        clone.splitErc20(erc20);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }

    function testSplitErc20_skipZero() public {
        ImmutableSplit clone = _deployClone(1, 9999);
        SafeTransferLib.safeTransfer(erc20, address(clone), 500);
        clone.splitErc20(erc20);
        assertEq(erc20.balanceOf(address(0x1)), 0);
        assertEq(erc20.balanceOf(address(0x2)), 499);
    }

    function testSplitErc20_NotAContract() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        SafeTransferLib.safeTransfer(erc20, address(clone), 1 ether);
        vm.expectRevert(NotASmartContract.selector);
        clone.splitErc20(ERC20(address(0x1)));
    }

    function testProxyCall() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        vm.prank(address(0x1));
        clone.proxyCall(address(erc20), abi.encodeWithSelector(erc20.transfer.selector, address(0x1), 0));
    }

    function testProxyCall_preemptiveSplit() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        erc20.mint(address(clone), 1 ether);
        vm.prank(address(0x1));
        clone.proxyCall(address(erc20), abi.encodeWithSelector(erc20.transfer.selector, address(0x1), 0));
        assertEq(erc20.balanceOf(address(0x1)), 0.5 ether);
        assertEq(erc20.balanceOf(address(0x2)), 0.5 ether);
    }

    function testProxyCall_NotASmartContract() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        vm.startPrank(address(0x1));
        vm.expectRevert(NotASmartContract.selector);
        clone.proxyCall(address(0x1000), abi.encodeWithSelector(erc20.transfer.selector, address(0x1), 0));
    }

    function testProxyCallRevert() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        Revertooooor revertooooor = new Revertooooor();
        vm.startPrank(address(0x1));
        vm.expectRevert("Reverted");
        clone.proxyCall(address(revertooooor), abi.encodeWithSelector(Revertooooor.callMe.selector));
    }

    function testProxyCall_CannotApproveERC20() public {
        ImmutableSplit clone = _deployClone(5000, 5000);
        vm.startPrank(address(0x1));
        vm.expectRevert(CannotApproveErc20.selector);
        clone.proxyCall(address(erc20), abi.encodeWithSelector(erc20.approve.selector, address(0x1), 0));
    }

    function testReenterReceive() public {
        Reenterooooor reenterooooor = new Reenterooooor();
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(reenterooooor), 5000);
        recipients[1] = Recipient(payable(address(type(uint160).max)), 5000);

        ImmutableSplit clone = _deployClone(recipients);
        vm.expectRevert("ETH_TRANSFER_FAILED");
        SafeTransferLib.safeTransferETH(address(clone), 1 ether);
    }

    function _deployClone(uint256 bps1, uint256 bps2) internal returns (ImmutableSplit) {
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = Recipient(payable(address(0x1)), bps1);
        recipients[1] = Recipient(payable(address(0x2)), bps2);
        return _deployClone(recipients);
    }

    function _deployClone(Recipient[] memory recipients) internal returns (ImmutableSplit) {
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);
        return ImmutableSplit(payable(Create2ClonesWithImmutableArgs.clone(address(impl), data, bytes32(0))));
    }
}
