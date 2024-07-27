// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

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

    /// Data structure for saving the admin data
    struct Admin {
        address addr;
        uint256 balance;
        uint256 collected;
    }

}