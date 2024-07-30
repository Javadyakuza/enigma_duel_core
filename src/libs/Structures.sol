// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/**
 * @title Structures
 * @dev A library that defines the data structures used in the Enigma Duel smart contracts.
 */
library Structures {

    /**
     * @dev Enum representing the status of a game room.
     */
    enum GameRoomStatus {
        InActive,  // The game room is not active.
        Finished,  // The game room has finished.
        Active     // The game room is currently active.
    }

    /**
     * @dev Enum representing the result status of a game room.
     */
    enum GameRoomResultStatus {
        Draw,      // The game ended in a draw.
        Victory    // The game ended in a victory for one of the duelists.
    }

    /**
     * @dev Struct representing the details of a game room.
     * @param duelist1 The address of the first duelist.
     * @param duelist2 The address of the second duelist.
     * @param prizePool The total prize pool for the game.
     * @param status The current status of the game room.
     */
    struct GameRoom {
        address duelist1;
        address duelist2;
        uint256 prizePool;
        GameRoomStatus status;
    }

    /**
     * @dev Struct representing the result of a game room.
     * @param status The result status of the game room (draw or victory).
     * @param fee The fee associated with the game.
     * @param duelist1 The address of the first duelist (zero if draw).
     * @param duelist2 The address of the second duelist (zero if draw).
     * @param winnnerReceived The amount received by the winner.
     * @param loserReceived The amount received by the loser.
     */
    struct GameRoomResult {
        GameRoomResultStatus status;
        uint256 fee;
        address duelist1; // Zero if draw
        address duelist2; // Zero if draw
        uint256 winnnerReceived;
        uint256 loserReceived;
    }

    /**
     * @dev Struct representing a user's balance.
     * @param total The total balance of the user.
     * @param locked The amount of balance that is locked.
     * @param available The amount of balance that is available for use.
     */
    struct Balance {
        uint256 total;
        uint256 locked;
        uint256 available;
    }
}
