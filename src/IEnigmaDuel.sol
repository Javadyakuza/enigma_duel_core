// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Structures} from "./Structures.sol";
import {Events} from "./Events.sol";

interface IEnigmaDuel is Events {
    function startGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external returns (bytes32 _game_room_key);

    function finishGameRoom(
        bytes32 _game_room_key
    ) external returns (Structures.GameRoomResult memory _game_room_result);

}
