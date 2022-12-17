// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {Recipient} from "./Structs.sol";
import {ImmutableSplit} from "./ImmutableSplit.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";
import {InvalidBps, InvalidTotalBps, RecipientsMustBeSortedByAscendingBpsAndAddress} from "./Errors.sol";

contract ImmutableSplitFactory {
    address public immutable impl;

    constructor(address _impl) {
        impl = _impl;
    }

    function createImmutableSplit(Recipient[] calldata recipients) external returns (address payable) {
        _validateBps(recipients);
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);
        return Create2ClonesWithImmutableArgs.clone(impl, data, bytes32(0));
    }

    function _validateBps(Recipient[] calldata recipients) internal pure {
        uint256 totalBps;
        uint256 lastBps;
        address lastRecipient;
        unchecked {
            for (uint256 i; i < recipients.length; ++i) {
                uint256 bps = recipients[i].bps;
                address recipient = recipients[i].recipient;
                if (bps < lastBps) {
                    revert RecipientsMustBeSortedByAscendingBpsAndAddress();
                } else if (bps == lastBps && recipient < lastRecipient) {
                    revert RecipientsMustBeSortedByAscendingBpsAndAddress();
                }

                if (bps > 10000 || bps == 0) revert InvalidBps(bps);
                totalBps += bps;
                lastBps = bps;
                lastRecipient = recipient;
            }
        }
        if (totalBps != 10000) {
            revert InvalidTotalBps(totalBps);
        }
    }
}
