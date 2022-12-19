// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ImmutableSplit} from "../src/ImmutableSplit.sol";
import {ImmutableSplitFactory} from "../src/ImmutableSplitFactory.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";
import {Recipient} from "../src/lib/Structs.sol";
import {createRecipient} from "../src/lib/Recipient.sol";

contract GasTest is Test {
    ImmutableSplitFactory factory;
    ImmutableSplit impl = new ImmutableSplit();
    ImmutableSplit twoRecipients;
    ImmutableSplit threeRecipients;

    function setUp() public {
        factory = new ImmutableSplitFactory(address(impl));
        Recipient[] memory recipients = new Recipient[](2);
        recipients[0] = createRecipient(payable(address(1000)), 5000);
        recipients[1] = createRecipient(payable(address(2000)), 5000);
        twoRecipients = ImmutableSplit(factory.createImmutableSplit(recipients));
        recipients = new Recipient[](3);
        recipients[0] = createRecipient(payable(address(1000)), 3333);
        recipients[1] = createRecipient(payable(address(2000)), 3333);
        recipients[2] = createRecipient(payable(address(3000)), 3334);
        threeRecipients = ImmutableSplit(factory.createImmutableSplit(recipients));
        (bool success,) = address(1000).call{value: 1}("");
        (success,) = address(2000).call{value: 1}("");
        (success,) = address(3000).call{value: 1}("");
    }

    function test_snapshotCreate2CloneWithImmutableArgsThreeRecipients() public {
        Recipient[] memory recipients = new Recipient[](3);
        recipients[0] = createRecipient(payable(address(1000)), 3331);
        recipients[1] = createRecipient(payable(address(2000)), 3334);
        recipients[2] = createRecipient(payable(address(3000)), 3335);
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);
        uint256 gas = gasleft();
        Create2ClonesWithImmutableArgs.clone(address(impl), data, bytes32(0));
        emit log_named_uint("gas used: ", gas - gasleft());
    }

    function test_snapshotFactoryThreeRecipients() public {
        Recipient[] memory recipients = new Recipient[](3);
        recipients[0] = createRecipient(payable(address(1000)), 3332);
        recipients[1] = createRecipient(payable(address(2000)), 3334);
        recipients[2] = createRecipient(payable(address(3000)), 3334);
        ImmutableSplitFactory _factory = factory;

        uint256 gas = gasleft();
        _factory.createImmutableSplit(recipients);
        emit log_named_uint("gas used: ", gas - gasleft());
    }

    function test_snapshotSplitTwoRecipients() public {
        address _twoRecipients = address(twoRecipients);
        uint256 gas = gasleft();
        (bool success,) = _twoRecipients.call{value: 10000}("");
        assertTrue(success);
        emit log_named_uint("gas used: ", gas - gasleft());
    }

    function test_snapshotSplitThreeRecipients() public {
        address _threeRecipients = address(threeRecipients);
        uint256 gas = gasleft();
        (bool success,) = _threeRecipients.call{value: 10000}("");
        assertTrue(success);
        emit log_named_uint("gas used: ", gas - gasleft());
    }
}
