// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Structures} from "./Structures.sol";
import {Events} from "./Events.sol";

interface IEnigmaDuel is Events {
    function createGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external returns (bytes32 _game_room_key);

    function userBalance() external view returns(Structures.Balance memory _balance);
}
