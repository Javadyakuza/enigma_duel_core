// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

library Structures {
    enum GameRoomStatus {
        InActive,
        Finished,
        Active
    }

    enum GameRoomResultStatus {
        Draw,
        Victory
    }

    /// Data structure for saving each game room
    struct GameRoom {
        address duelist1;
        address duelist2;
        uint256 prizePool;
        GameRoomStatus status;
    }

    struct GameRoomResult {
        GameRoomResultStatus status;
        uint256 fee;
        address duelist1; // zero if draw
        address duelist2; // zero if draw
        uint256 winnnerReceived;
        uint256 loserReceived;
    }

    struct Balance {
        uint256 total;
        uint256 locked;
        uint256 available;
    }
}
