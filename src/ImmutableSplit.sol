// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Recipient, CalldataPointer} from "./Structs.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {NotASmartContract, NotRecipient, CannotProxyApproveErc20} from "./Errors.sol";

contract ImmutableSplit is Clone {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 constant IERC20_APPROVE_SELECTOR = 0x095ea7b300000000000000000000000000000000000000000000000000000000;
    uint256 constant SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    modifier onlyRecipient() {
        Recipient[] calldata recipients = _getArgRecipients();
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            if (recipients[i].recipient == msg.sender) {
                _;
            }
            unchecked {
                ++i;
            }
        }
        revert NotRecipient();
    }

    function getRecipients() public pure returns (Recipient[] memory recipients) {
        return _getArgRecipients();
    }

    function receiveHook() public payable {
        Recipient[] calldata recipients = _getArgRecipients();
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            for (uint256 i = 0; i < recipients.length; ++i) {
                uint256 amount = (balance * recipients[i].bps) / 10000;
                if (amount == 0) {
                    continue;
                }
                recipients[i].recipient.safeTransferETH(amount);
            }
        }
    }

    function splitErc20(ERC20 token) public {
        if (address(token).code.length == 0) {
            revert NotASmartContract();
        }
        _splitErc20(token);
    }

    function _splitErc20(ERC20 token) internal {
        Recipient[] calldata recipients = _getArgRecipients();
        unchecked {
            uint256 balance = token.balanceOf(address(this));
            if (balance == 0) {
                return;
            }
            for (uint256 i = 0; i < recipients.length; ++i) {
                uint256 amount = (balance * recipients[i].bps) / 10000;
                if (amount == 0) {
                    continue;
                }
                token.safeTransfer(recipients[i].recipient, amount);
            }
        }
    }

    function proxyCall(address target, bytes calldata callData) public onlyRecipient returns (bytes memory) {
        if (target.code.length == 0) {
            revert NotASmartContract();
        }
        bool isErc20ApproveCall;
        ///@solidity memory-safe-assembly
        assembly {
            isErc20ApproveCall := eq(and(calldataload(0), SELECTOR_MASK), IERC20_APPROVE_SELECTOR)
        }
        if (isErc20ApproveCall) {
            revert CannotProxyApproveErc20();
        }

        _splitErc20(ERC20(target));
        (bool success, bytes memory returndata) = target.call(callData);

        ///@solidity memory-safe-assembly
        assembly {
            if iszero(success) { revert(add(returndata, 0x20), mload(returndata)) }
        }

        return returndata;
    }

    function _getArgRecipients() internal pure returns (Recipient[] calldata recipient) {
        uint256 offset = _getImmutableArgsOffset();
        CalldataPointer calldata calldataPointer;
        assembly {
            calldataPointer := add(4, offset)
        }
        return calldataPointer.recipients;
    }

    receive() external payable {}
}
