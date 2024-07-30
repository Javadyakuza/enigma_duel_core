// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

library EnigmaDuelErrors {

    error InvalidGameRoomStatus ();

    error InsufficientBalance ();
    error AddressZeroNotSupported ();
    error DepositeFailed ();

    error Unauthorized ();
    error CollectingFeesFailed();

    error Overflow();
    error Underflow();

}
