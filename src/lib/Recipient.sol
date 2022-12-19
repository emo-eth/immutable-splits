// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice A user-defined-type to store an address and a bps (basis points) value in a single word.
type Recipient is uint256;

///@dev The number of bits the BPS is shifted from the right on the Recipient type.
uint256 constant BPS_SHIFT = 160;
///@dev The mask to use to extract the address from a Recipient type.
uint256 constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
///@dev The mask to use to extract the bps from a Recipient type.
uint256 constant BPS_MASK = 0xffffffffffffffff;

/**
 * @notice Create a Recipient type from an address and a bps, packed into a single word for efficiency
 */
function createRecipient(address _recipient, uint16 _bps) pure returns (Recipient _recip) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := or(shl(BPS_SHIFT, _bps), _recipient)
    }
}

/**
 * @notice Unpack the address recipient from a Recipient type
 */
function recipient(Recipient _recipient) pure returns (address _recip) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := and(_recipient, ADDRESS_MASK)
    }
}

/**
 * @notice Unpack the bps from a Recipient type, limited to 16 bits in practice
 */
function bps(Recipient _recipient) pure returns (uint256 _bps) {
    ///@solidity memory-safe-assembly
    assembly {
        _bps := and(shr(BPS_SHIFT, _recipient), BPS_MASK)
    }
}

/**
 * @notice Unpack both the address recipient and the bps from a Recipient type
 */
function unpack(Recipient _recipient) pure returns (address _recip, uint256 _bps) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := and(_recipient, ADDRESS_MASK)
        _bps := and(shr(BPS_SHIFT, _recipient), BPS_MASK)
    }
}

// declare global usage of these functions for the Recipient type
using {recipient, bps, unpack} for Recipient global;
