// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

library Structures {
    enum GameRoomStatus {
        InActive,
        Finished,
        Active
    }

    /// Data structure for saving each game room
    struct GameRoom {
        address duelist1;
        address duelist2;
        uint256 prizePool;
        GameRoomStatus status;
    }

    struct Balance {
        uint256 total;
        uint256 available;
    }
}
