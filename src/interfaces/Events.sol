// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IEnigmaDuelState} from "../interfaces/IEnigmaDuelState.sol";

/**
 * @title Events
 * @dev Interface that defines the events emitted by the Enigma Duel smart contracts.
 */
interface Events {
    /**
     * @dev Emitted when fees are collected.
     * @param _amount The amount of fees collected.
     * @param _dest The address where the collected fees are sent.
     */
    event FeesCollected(uint256 _amount, address _dest);

    /**
     * @dev Emitted when a new game room is started.
     * @param duelist1 The address of the first duelist.
     * @param duelist2 The address of the second duelist.
     * @param prizePool The prize pool of the game.
     */
    event GameStarted(address duelist1, address duelist2, uint256 prizePool);

    /**
     * @dev Emitted when a game room is finished.
     * @param status The result status of the game room (draw or victory).
     * @param fee The fee associated with the game.
     * @param winner The address of the winner (or address(0) if it's a draw).
     * @param winnnerReceived The amount received by the winner.
     */
    event GameFinished(
        IEnigmaDuelState.GameRoomResultStatus status,
        uint256 fee,
        address winner,
        uint256 winnnerReceived
    );
}
