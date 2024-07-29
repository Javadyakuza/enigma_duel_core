// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

library EnigmaDuelErrors {

    error GameRoomNotStarted ();
    error GameRoomAlreadyStarted ();
    error GameRoomDoesntExists ();

    error InsufficientBalance ();
    error AddressZeroNotSupported ();
    error DepositeFailed ();

    error Unauthorized ();
    error CollectingFeesFailed();
}
