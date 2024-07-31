// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EnigmaDuelState is Initializable {
    address private authorizedCaller;
    address private owner;

    struct Balance {
        uint256 total;
        uint256 locked;
        uint256 available;
    }

    struct GameRoom {
        address duelist1;
        address duelist2;
        uint256 prizePool;
        GameRoomStatus status;
    }

    enum GameRoomStatus {
        InActive,
        Finished,
        Active
    }

    enum GameRoomResultStatus {
        Draw,
        Victory
    }

    mapping(address => Balance) private balances;
    mapping(bytes32 => GameRoom) private gameRooms;

    // Initializer function instead of constructor
    function initialize(address _authorizedCaller) public initializer {
        authorizedCaller = _authorizedCaller;
        owner = msg.sender;
    }

    function chagngeAuthorizedCaller(address _authorizedCaller) public {
        require(msg.sender == owner, "not owner");
        authorizedCaller = _authorizedCaller;
    }

    modifier onlyAuthorizedCaller() {
        require(msg.sender == authorizedCaller, "Caller is not authorized");
        _;
    }

    function setBalance(
        address user,
        Balance memory balance
    ) external onlyAuthorizedCaller {
        // checking for unchanged owner balance
        if (balances[user].available == balance.available) {
            return;
        }
        balances[user] = balance;
    }

    function decreaseBalance(
        address user,
        uint256 amount
    ) external onlyAuthorizedCaller {
        balances[user].total -= amount;
        balances[user].available -= amount;
    }

    function increaseBalance(
        address user,
        uint256 amount
    ) external onlyAuthorizedCaller {
        balances[user].total += amount;
        balances[user].available += amount;
    }

    function setGameRoom(
        bytes32 gameRoomKey,
        GameRoom memory gameRoom
    ) external onlyAuthorizedCaller {
        gameRooms[gameRoomKey] = gameRoom;
    }

    function closeGameRoomState(
        bytes32 gameRoomKey
    ) external onlyAuthorizedCaller {
        gameRooms[gameRoomKey].status = GameRoomStatus.Finished;
        gameRooms[gameRoomKey].prizePool = 0;
    }

    function getBalance(address user) external view returns (Balance memory) {
        return balances[user];
    }

    function getGameRoom(
        bytes32 gameRoomKey
    ) external view returns (GameRoom memory) {
        return gameRooms[gameRoomKey];
    }

}
