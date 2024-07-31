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
import {IEnigmaDuelState} from "./interfaces/IEnigmaDuelState.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
/**
 * @title EnigmaDuel
 * @dev A contract for managing duels, handling fees, and tracking balances in the Enigma Duel game.
 */
contract EnigmaDuel is
    IEnigmaDuel,
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    IERC20 public EDT;
    IEnigmaDuelState public STATE;
    uint256 public FEE;
    uint256 public DRAW_FEE;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER");

    function initialize(
        address _state,
        address _edt,
        uint256 _fee,
        uint256 _draw_fee
    ) public initializer {
        __Ownable_init(_msgSender());
        __AccessControl_init();

        STATE = IEnigmaDuelState(_state);
        EDT = IERC20(_edt);
        FEE = _fee;
        DRAW_FEE = _draw_fee;

        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _msgSender());
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
            STATE.getBalance(_msgSender()).total >= _amount,
            EnigmaDuelErrors.InsufficientBalance()
        );

        STATE.decreaseBalance(_msgSender(), _amount);

        EDT.safeTransfer(_dest, _amount);

        emit FeesCollected(_amount, _dest);
    }

    function startGameRoom(
        IEnigmaDuelState.GameRoom calldata _game_room_init_params
    ) external onlyRole(ADMIN_ROLE) returns (bytes32 _game_room_key) {
        require(
            (_game_room_init_params.prizePool / 2) <=
                STATE.getBalance(_game_room_init_params.duelist1).available &&
                (_game_room_init_params.prizePool / 2) <=
                STATE.getBalance(_game_room_init_params.duelist2).available,
            EnigmaDuelErrors.InsufficientBalance()
        );

        _game_room_key = EnigmaUtils.gen_game_room_key(
            _game_room_init_params.duelist1,
            _game_room_init_params.duelist2
        );

        require(
            STATE.getGameRoom(_game_room_key).status !=
                IEnigmaDuelState.GameRoomStatus.Active &&
                _game_room_init_params.status ==
                IEnigmaDuelState.GameRoomStatus.Active,
            EnigmaDuelErrors.InvalidGameRoomStatus()
        );

        STATE.setGameRoom(_game_room_key, _game_room_init_params);

        STATE.setBalance(
            _game_room_init_params.duelist1,
            EnigmaUtils.balance_locker(
                STATE.getBalance(_game_room_init_params.duelist1),
                (_game_room_init_params.prizePool / 2)
            )
        );
        STATE.setBalance(
            _game_room_init_params.duelist2,
            EnigmaUtils.balance_locker(
                STATE.getBalance(_game_room_init_params.duelist2),
                (_game_room_init_params.prizePool / 2)
            )
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
        IEnigmaDuelState.GameRoom memory gameRoom = STATE.getGameRoom(
            _game_room_key
        );
        require(
            gameRoom.status == IEnigmaDuelState.GameRoomStatus.Active,
            EnigmaDuelErrors.InvalidGameRoomStatus()
        );

        uint256 fee = _winner == address(0) ? DRAW_FEE : FEE;
        uint256 prizeShare = EnigmaUtils.calc_share(gameRoom.prizePool, fee);

        _game_room_result = Structures.GameRoomResult(
            _winner == address(0)
                ? IEnigmaDuelState.GameRoomResultStatus.Draw
                : IEnigmaDuelState.GameRoomResultStatus.Victory,
            fee,
            gameRoom.duelist1,
            gameRoom.duelist2,
            prizeShare,
            prizeShare
        );

        gameRoom.status = IEnigmaDuelState.GameRoomStatus.Finished;
        gameRoom.prizePool = 0;

        bool isWinner1 = _winner == gameRoom.duelist1;
        bool isWinner2 = _winner == gameRoom.duelist2;
        IEnigmaDuelState.Balance memory owner_balance = STATE.getBalance(
            owner()
        );
        IEnigmaDuelState.Balance memory tmp_bal1;
        IEnigmaDuelState.Balance memory tmp_bal2;

        (tmp_bal1, tmp_bal2) = EnigmaUtils.balance_unlocker(
            STATE.getBalance(gameRoom.duelist1),
            owner_balance,
            prizeShare,
            isWinner1
        );
        STATE.setBalance(owner(), tmp_bal1);
        STATE.setBalance(gameRoom.duelist1, tmp_bal2);
        (tmp_bal1, tmp_bal2) = EnigmaUtils.balance_unlocker(
            STATE.getBalance(gameRoom.duelist2),
            owner_balance,
            prizeShare,
            isWinner2
        );
        STATE.setBalance(owner(), tmp_bal1);
        STATE.setBalance(gameRoom.duelist2, tmp_bal2);
        emit GameFinished(
            _winner == address(0)
                ? IEnigmaDuelState.GameRoomResultStatus.Draw
                : IEnigmaDuelState.GameRoomResultStatus.Victory,
            fee,
            _winner,
            prizeShare
        );
    }

    function depositEDT(
        uint256 deposit_amount
    ) external returns (uint256 _new_balance) {
        EDT.safeTransferFrom(_msgSender(), address(this), deposit_amount);

        STATE.increaseBalance(_msgSender(), deposit_amount);

        _new_balance = STATE.getBalance(_msgSender()).available;
    }

    function withdrawEDT(
        uint256 withdraw_amount
    ) external returns (uint256 _new_balance) {
        require(
            STATE.getBalance(_msgSender()).available >= withdraw_amount,
            EnigmaDuelErrors.InsufficientBalance()
        );

        STATE.decreaseBalance(_msgSender(), withdraw_amount);

        EDT.safeTransfer(_msgSender(), withdraw_amount);

        _new_balance = STATE.getBalance(_msgSender()).available;
    }

    function getUserbalance(
        address user
    ) external view returns (IEnigmaDuelState.Balance memory _balance) {
        return STATE.getBalance(user);
    }

    function getGameRoom(
        bytes32 gameRoomKey
    ) external view returns (IEnigmaDuelState.GameRoom memory) {
        return STATE.getGameRoom(gameRoomKey);
    }

    function getFEE() external view returns (uint256) {
        return FEE;
    }

    function getDRAW_FEE() external view returns (uint256) {
        return DRAW_FEE;
    }

    function getEDT() external view returns (address) {
        return address(EDT);
    }

    function getState() external view returns (address) {
        return address(STATE);
    }
}
