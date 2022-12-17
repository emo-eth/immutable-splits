// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {Recipient} from "./Structs.sol";
import {ImmutableSplit} from "./ImmutableSplit.sol";
import {Create2ClonesWithImmutableArgs} from "create2-clones-with-immutable-args/Create2ClonesWithImmutableArgs.sol";
import {
    InvalidBps, InvalidTotalBps, RecipientsMustBeSortedByAscendingBpsAndAddress, AlreadyDeployed
} from "./Errors.sol";
import {IImmutableSplitFactory} from "./IImmutableSplitFactory.sol";

contract ImmutableSplitFactory is IImmutableSplitFactory {
    address public immutable IMMUTABLE_SPLIT_IMPLEMENTATION;
    mapping(bytes32 => address payable) deployedSplits;

    constructor(address _impl) {
        IMMUTABLE_SPLIT_IMPLEMENTATION = _impl;
    }

    function createImmutableSplit(Recipient[] calldata recipients) external returns (address payable) {
        bytes32 recipientsHash = _getRecipientsHash(recipients);
        address deployedSplitAddress = deployedSplits[recipientsHash];
        if (deployedSplitAddress != address(0)) {
            revert AlreadyDeployed(deployedSplitAddress);
        }
        bytes memory data = abi.encodeWithSelector(ImmutableSplit.receiveHook.selector, recipients);
        address payable split = Create2ClonesWithImmutableArgs.clone(IMMUTABLE_SPLIT_IMPLEMENTATION, data, bytes32(0));
        deployedSplits[recipientsHash] = split;
        return split;
    }

    function getDeployedImmutableSplitAddress(Recipient[] calldata recipients) public view returns (address) {
        return deployedSplits[_getRecipientsHash(recipients)];
    }

    function _getRecipientsHash(Recipient[] calldata recipients) internal pure returns (bytes32) {
        _validateBps(recipients);
        return keccak256(abi.encode(recipients));
    }

    function _validateBps(Recipient[] calldata recipients) internal pure {
        uint256 totalBps;
        uint256 lastBps;
        Recipient lastRecipient;
        unchecked {
            for (uint256 i; i < recipients.length; ++i) {
                Recipient recipient = recipients[i];
                if (Recipient.unwrap(recipient) <= Recipient.unwrap(lastRecipient)) {
                    revert RecipientsMustBeSortedByAscendingBpsAndAddress();
                }
                uint256 bps = recipient.bps();

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
