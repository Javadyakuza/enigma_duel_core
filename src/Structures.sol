// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library Models {

    enum GameRoomStatus {
        Active,
        InActive
    }
    
    /// Data structure for saving each game room
    struct GameRoom {
        address duelist1;
        address duelist2;
        uint256 prizePool;
        GameRoomStatus status;
    }
}