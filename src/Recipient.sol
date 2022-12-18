// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

type Recipient is uint256;

uint8 constant BPS_LSHIFT = 160;
uint256 constant ADDRESS_MASK = 2 ** 160 - 1;
uint16 constant BPS_MASK = 2 ** 16 - 1;

function recipient(Recipient _recipient) pure returns (address _recip) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := and(_recipient, ADDRESS_MASK)
    }
}

function bps(Recipient _recipient) pure returns (uint256 _bps) {
    ///@solidity memory-safe-assembly
    assembly {
        _bps := and(shr(BPS_LSHIFT, _recipient), BPS_MASK)
    }
}

function unpack(Recipient _recipient) pure returns (address _recip, uint256 _bps) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := and(_recipient, ADDRESS_MASK)
        _bps := and(shr(BPS_LSHIFT, _recipient), BPS_MASK)
    }
}

function createRecipient(address _recipient, uint16 _bps) pure returns (Recipient _recip) {
    ///@solidity memory-safe-assembly
    assembly {
        _recip := or(shl(BPS_LSHIFT, _bps), _recipient)
    }
}

using {recipient, bps, unpack} for Recipient global;
