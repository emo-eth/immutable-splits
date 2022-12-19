// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Recipient, createRecipient} from "../src/lib/Recipient.sol";

contract RecipientTest is Test {
    function testRecipient() public {
        Recipient recipient = createRecipient({_recipient: payable(address(1)), _bps: 10000});
        assertEq(recipient.recipient(), address(1));
        assertEq(recipient.bps(), 10000);
    }

    function testRecipient(address recipient, uint16 bps) public {
        bps = uint16(bound(bps, 0, 10000));
        Recipient _recipient = createRecipient({_recipient: payable(recipient), _bps: bps});
        assertEq(_recipient.recipient(), recipient);
        assertEq(_recipient.bps(), bps);
    }
}
