// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

interface IEnigmaDuelState {
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
     * @dev Enum representing the status of a game room.
     */
    enum GameRoomStatus {
        InActive, // The game room is not active.
        Finished, // The game room has finished.
        Active // The game room is currently active.
    }

    /**
     * @dev Enum representing the result status of a game room.
     */
    enum GameRoomResultStatus {
        Draw, // The game ended in a draw.
        Victory // The game ended in a victory for one of the duelists.
    }

    /**
     * @dev Sets the balance for a given user.
     * @param user The address of the user.
     * @param balance The balance struct containing total, locked, and available amounts.
     */
    function setBalance(address user, Balance memory balance) external;

    /**
     * @dev Decreases the available balance for a given user by a specified amount.
     * @param user The address of the user.
     * @param amount The amount to decrease from the user's available balance.
     */
    function decreaseBalance(address user, uint256 amount) external;

    /**
     * @dev Increases the available balance for a given user by a specified amount.
     * @param user The address of the user.
     * @param amount The amount to increase to the user's available balance.
     */
    function increaseBalance(address user, uint256 amount) external;

    /**
     * @dev Sets the game room details for a given game room key.
     * @param gameRoomKey The unique key of the game room.
     * @param gameRoom The game room struct containing duelist addresses, prize pool, and status.
     */
    function setGameRoom(
        bytes32 gameRoomKey,
        GameRoom memory gameRoom
    ) external;

    /**
     * @dev Closes the game room by setting its status to Finished and resetting the prize pool to 0.
     * Can only be called by the authorized caller.
     * @param gameRoomKey The unique key of the game room to be closed.
     */
    function closeGameRoomState(bytes32 gameRoomKey) external;

    /**
     * @dev Retrieves the balance for a given user.
     * @param user The address of the user.
     * @return The balance struct containing total, locked, and available amounts.
     */
    function getBalance(address user) external view returns (Balance memory);

    /**
     * @dev Retrieves the game room details for a given game room key.
     * @param gameRoomKey The unique key of the game room.
     * @return The game room struct containing duelist addresses, prize pool, and status.
     */
    function getGameRoom(
        bytes32 gameRoomKey
    ) external view returns (GameRoom memory);
}
