// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {EnigmaDuelErrors} from "./libs/Errors.sol";
import {IEnigmaDuel} from "./interfaces/IEnigmaDuel.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {Structures} from "./libs/Structures.sol";
import {EnigmaUtils} from "./utils/Utils.sol";

/**
 * @title EnigmaDuel
 * @dev A contract for managing duels, handling fees, and tracking balances in the Enigma Duel game.
 */
contract EnigmaDuel is IEnigmaDuel, Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public EDT;
    uint256 public FEE;
    uint256 public DRAW_FEE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER");

    mapping(address => Structures.Balance) public balances;
    mapping(bytes32 => Structures.GameRoom) private gameRooms;


    constructor(
        address _edt,
        uint256 _fee,
        uint256 _draw_fee
    ) Ownable(_msgSender()) {
        EDT = _edt;
        FEE = _fee;
        DRAW_FEE = _draw_fee;

        _grantRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    }


    function withdrawCollectedFees(
        uint256 _amount,
        address _dest
    ) external onlyOwner {
        require(
            _dest != address(0),
            EnigmaDuelErrors.AddressZeroNotSupported()
        );
        require(
            balances[_msgSender()].available >= _amount,
            EnigmaDuelErrors.InsufficientBalance()
        );

        balances[_msgSender()].total -= _amount;

        IERC20(EDT).safeTransfer(_dest, _amount);

        emit FeesCollected(_amount, _dest);
    }


    function startGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external onlyRole(ADMIN_ROLE) returns (bytes32 _game_room_key) {
        uint256 min_required = EnigmaUtils.calc_min_required(
            _game_room_init_params.prizePool,
            DRAW_FEE
        );

        require(
            min_required <=
                balances[_game_room_init_params.duelist1].available &&
                min_required <=
                balances[_game_room_init_params.duelist2].available,
            EnigmaDuelErrors.InsufficientBalance()
        );

        _game_room_key = EnigmaUtils.gen_game_room_key(
            _game_room_init_params.duelist1,
            _game_room_init_params.duelist2
        );

        require(
            gameRooms[_game_room_key].status !=
                Structures.GameRoomStatus.Active,
            EnigmaDuelErrors.InvalidGameRoomStatus()
        );

        gameRooms[_game_room_key] = _game_room_init_params;
        gameRooms[_game_room_key].status = Structures.GameRoomStatus.Active;

        balances[_game_room_init_params.duelist1] = EnigmaUtils.balance_locker(
            balances[_game_room_init_params.duelist1],
            min_required
        );
        balances[_game_room_init_params.duelist2] = EnigmaUtils.balance_locker(
            balances[_game_room_init_params.duelist2],
            min_required
        );

        emit GameStarted(
            _game_room_init_params.duelist1,
            _game_room_init_params.duelist2,
            _game_room_init_params.prizePool
        );
    }


    function finishGameRoom(
        bytes32 _game_room_key,
        address _winner
    )
        external
        onlyRole(ADMIN_ROLE)
        returns (Structures.GameRoomResult memory _game_room_result)
    {
        Structures.GameRoom storage gameRoom = gameRooms[_game_room_key];
        require(
            gameRoom.status == Structures.GameRoomStatus.Active,
            EnigmaDuelErrors.InvalidGameRoomStatus()
        );

        uint256 fee = _winner == address(0) ? DRAW_FEE : FEE;
        uint256 prizeShare = EnigmaUtils.calc_min_required(
            gameRoom.prizePool,
            fee
        );

        _game_room_result = Structures.GameRoomResult(
            _winner == address(0)
                ? Structures.GameRoomResultStatus.Draw
                : Structures.GameRoomResultStatus.Victory,
            fee,
            gameRoom.duelist1,
            gameRoom.duelist2,
            prizeShare,
            prizeShare
        );

        gameRoom.status = Structures.GameRoomStatus.Finished;
        gameRoom.prizePool = 0;

        bool isWinner1 = _winner == gameRoom.duelist1;
        bool isWinner2 = _winner == gameRoom.duelist2;

        (balances[owner()], balances[gameRoom.duelist1]) = EnigmaUtils
            .balance_unlocker(
                balances[gameRoom.duelist1],
                balances[owner()],
                prizeShare,
                isWinner1
            );

        (balances[owner()], balances[gameRoom.duelist2]) = EnigmaUtils
            .balance_unlocker(
                balances[gameRoom.duelist2],
                balances[owner()],
                prizeShare,
                isWinner2
            );

        emit GameFinished(
            _winner == address(0)
                ? Structures.GameRoomResultStatus.Draw
                : Structures.GameRoomResultStatus.Victory,
            fee,
            _winner,
            prizeShare
        );
    }

    function depositEDT(
        uint256 deposit_amount
    ) external returns (uint256 _new_balance) {
        IERC20(EDT).safeTransferFrom(
            _msgSender(),
            address(this),
            deposit_amount
        );

        balances[_msgSender()].total += deposit_amount;
        balances[_msgSender()].available += deposit_amount;

        _new_balance = balances[_msgSender()].available;
    }


    function withdrawEDT(
        uint256 withdraw_amount
    ) external returns (uint256 _new_balance) {
        require(
            balances[_msgSender()].available >= withdraw_amount,
            EnigmaDuelErrors.InsufficientBalance()
        );

        balances[_msgSender()].available -= withdraw_amount;
        balances[_msgSender()].total -= withdraw_amount;

        IERC20(EDT).safeTransfer(_msgSender(), withdraw_amount);

        _new_balance = balances[_msgSender()].available;
    }

    function getUserbalance(
        address user
    ) external view returns (Structures.Balance memory) {
        return balances[user];
    }

    function getGameRoom(
        bytes32 gameRoomKey
    ) external view returns (Structures.GameRoom memory) {
        return gameRooms[gameRoomKey];
    }

    function getFEE() external view returns (uint256) {
        return FEE;
    }

    function getDRAW_FEE() external view returns (uint256) {
        return DRAW_FEE;
    }

    function getEDT() external view returns (address) {
        return EDT;
    }
}
