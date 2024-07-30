// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Structures} from "../libs/Structures.sol";
import {Events} from "./Events.sol";

/**
 * @title IEnigmaDuel
 * @dev Interface for the EnigmaDuel contract.
 */
interface IEnigmaDuel is Events {

    /**
     * @dev Withdraws collected fees to a specified address.
     * @param _amount Amount to withdraw.
     * @param _dest Destination address to receive the funds.
     */
    function withdrawCollectedFees(uint256 _amount, address _dest) external;

    /**
     * @dev Starts a new game room with specified parameters.
     * @param _game_room_init_params Parameters to initialize the game room.
     * @return _game_room_key The key for the newly created game room.
     */
    function startGameRoom(Structures.GameRoom calldata _game_room_init_params)
        external
        returns (bytes32 _game_room_key);

    /**
     * @dev Finishes a game room and determines the result.
     * @param _game_room_key The key of the game room to finish.
     * @param _winner The address of the winner, or address(0) if it's a draw.
     * @return _game_room_result The result of the game room.
     */
    function finishGameRoom(bytes32 _game_room_key, address _winner)
        external
        returns (Structures.GameRoomResult memory _game_room_result);

    /**
     * @dev Deposits EDT tokens into the contract.
     * @param deposit_amount The amount of EDT tokens to deposit.
     * @return _new_balance The new balance of the user.
     */
    function depositEDT(uint256 deposit_amount) external returns (uint256 _new_balance);

    /**
     * @dev Withdraws EDT tokens from the contract.
     * @param withdraw_amount The amount of EDT tokens to withdraw.
     * @return _new_balance The new balance of the user.
     */
    function withdrawEDT(uint256 withdraw_amount) external returns (uint256 _new_balance);

    /**
     * @dev Returns the balance structure of a user.
     * @param user The address of the user.
     * @return The balance structure of the user.
     */
    function getUserbalance(address user) external view returns (Structures.Balance memory);

    /**
     * @dev Returns the game room structure of a game room.
     * @param gameRoomKey The key of the game room.
     * @return The game room structure.
     */
    function getGameRoom(bytes32 gameRoomKey) external view returns (Structures.GameRoom memory);

    /**
     * @dev Returns the fee for a victory.
     * @return The fee for a victory.
     */
    function getFEE() external view returns (uint256);

    /**
     * @dev Returns the fee for a draw.
     * @return The fee for a draw.
     */
    function getDRAW_FEE() external view returns (uint256);

    /**
     * @dev Returns the address of the EDT token.
     * @return The address of the EDT token.
     */
    function getEDT() external view returns (address);
}
