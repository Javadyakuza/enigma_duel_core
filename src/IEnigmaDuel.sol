// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Structures} from "./Structures.sol";

interface IEnigmaDuel {

    event FeesCollected(uint256 _amount, address _dest);
    
    function createGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external returns (string memory _game_room_key);
}
