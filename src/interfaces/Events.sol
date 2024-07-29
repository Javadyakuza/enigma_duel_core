// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Structures} from "../libs/Structures.sol";

interface Events {
    event FeesCollected(uint256 _amount, address _dest);

    event GameStarted(address duelist1, address duelist2, uint256 prizePool);

    event GameFinished(
        Structures.GameRoomResultStatus status,
        uint256 fee,
        address winner,
        uint256 winnnerReceived
    );
    
}
