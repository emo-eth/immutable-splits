// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Recipient, CalldataPointer} from "./Structs.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {NotASmartContract, NotRecipient, CannotApproveErc20, Erc20TransferFailed} from "./Errors.sol";
import {IImmutableSplit} from "./IImmutableSplit.sol";

contract ImmutableSplit is IImmutableSplit, Clone {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 private constant IERC20_APPROVE_SELECTOR =
        0x095ea7b300000000000000000000000000000000000000000000000000000000;
    uint256 private constant SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;
    uint256 private constant CANNOT_APPROVE_ERC20_SELECTOR =
        0xfc87612e00000000000000000000000000000000000000000000000000000000;

    modifier onlyRecipient() {
        Recipient[] calldata recipients = _getArgRecipients();
        uint256 recipientsLength = recipients.length;
        for (uint256 i = 0; i < recipientsLength;) {
            if (recipients[i].recipient() == msg.sender) {
                _;
                return;
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

    function splitErc20(address token) public {
        if (address(token).code.length == 0) {
            revert NotASmartContract();
        }
        bool success = _splitErc20(token);
        if (!success) {
            revert Erc20TransferFailed();
        }
    }

    function proxyCall(address target, bytes calldata callData) public onlyRecipient returns (bytes memory) {
        if (address(target).code.length == 0) {
            revert NotASmartContract();
        }
        bool isErc20ApproveCall;
        ///@solidity memory-safe-assembly
        assembly {
            isErc20ApproveCall := eq(and(calldataload(callData.offset), SELECTOR_MASK), IERC20_APPROVE_SELECTOR)
            if isErc20ApproveCall {
                mstore(0, CANNOT_APPROVE_ERC20_SELECTOR)
                revert(0, 4)
            }
        }

        _splitErc20(target);
        (bool success, bytes memory returndata) = target.call(callData);

        ///@solidity memory-safe-assembly
        assembly {
            if iszero(success) { revert(add(returndata, 0x20), mload(returndata)) }
        }

        return returndata;
    }

    function receiveHook() public payable {
        Recipient[] calldata recipients = _getArgRecipients();
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            for (uint256 i = 0; i < recipients.length; ++i) {
                (address recipient, uint256 bps) = recipients[i].unpack();
                uint256 amount = (balance * bps) / 10000;
                if (amount == 0) {
                    continue;
                }
                recipient.safeTransferETH(amount);
            }
        }
    }

    receive() external payable {
        // clone will forward a DELEGATECALL to the implementation using the receiveHook() selector
    }

    function _splitErc20(address token) internal returns (bool) {
        Recipient[] calldata recipients = _getArgRecipients();
        unchecked {
            uint256 balance;
            try ERC20(token).balanceOf(address(this)) returns (uint256) {
                balance = ERC20(token).balanceOf(address(this));
            } catch {
                return false;
            }
            if (balance == 0) {
                return true;
            }
            for (uint256 i = 0; i < recipients.length; ++i) {
                (address recipient, uint256 bps) = recipients[i].unpack();
                uint256 amount = (balance * bps) / 10000;
                if (amount == 0) {
                    continue;
                }
                bool success = _safeTransferErc20(token, recipient, amount);
                if (!success) {
                    return false;
                }
            }
        }
        return true;
    }

    ///@dev This function is a modified version of SafeTransferLib.safeTransfer that returns success instead of reverting
    function _safeTransferErc20(address token, address to, uint256 amount) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the or() call in the
                    // surrounding and() call or else returndatasize() will be zero during the computation.
                    call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
                )
        }
    }

    ///@dev Read immutable Recipients from extra calldata.
    function _getArgRecipients() internal pure returns (Recipient[] calldata recipient) {
        uint256 offset = _getImmutableArgsOffset();
        CalldataPointer calldata calldataPointer;
        ///@solidity memory-safe-assembly
        assembly {
            // Extra calldata includes the receiveHook() selector by default, so add 4 bytes
            calldataPointer := add(4, offset)
        }
        return calldataPointer.recipients;
    }
}
