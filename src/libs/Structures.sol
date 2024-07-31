// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IEnigmaDuelState} from "../interfaces/IEnigmaDuelState.sol";
/**
 * @title Structures
 * @dev A library that defines the data structures used in the Enigma Duel smart contracts.
 */
library Structures {

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
        IEnigmaDuelState.GameRoomResultStatus status;
        uint256 fee;
        address duelist1; // Zero if draw
        address duelist2; // Zero if draw
        uint256 winnnerReceived;
        uint256 loserReceived;
    }


}
