// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library CodeDuelErrors {

    uint8 constant GameRoomNotStarted = 11;
    uint8 constant GameRoomAlreadyStarted = 12;
    uint8 constant GameRoomLoadError = 13;

    uint8 constant InsufficientBalance = 31;

    uint8 constant Unauthorized = 43;
}
