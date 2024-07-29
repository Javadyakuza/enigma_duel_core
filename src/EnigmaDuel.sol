// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {EnigmaDuelErrors} from "./libs/Errors.sol";
import {IEnigmaDuel} from "./interfaces/IEnigmaDuel.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {Structures} from "./libs/Structures.sol";
import {EnigmaUtils} from "./utils/Utils.sol";

contract EnigmaDuel is IEnigmaDuel, Ownable, AccessControl {
    using Math for uint256;

    address public EDT;
    uint256 public FEE;
    uint256 public DRAW_FEE;
    bytes32 constant ADMIN_ROLE = bytes32("ADMIN");
    bytes32 constant OWNER_ROLE = bytes32("OWNER");

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

    function WithdrawCollectedFees(
        uint256 _amount,
        address _dest
    ) external onlyOwner {
        // checking the destination address
        require(
            _dest != address(0),
            EnigmaDuelErrors.AddressZeroNotSupported()
        );

        // checking the requested withdraw amount
        require(
            balances[_msgSender()].available <= _amount,
            EnigmaDuelErrors.InsufficientBalance()
        );
        bool res;
        // decreasing the balance
        (res, balances[_msgSender()].total) = balances[_msgSender()].total.trySub(
            _amount
        );
        require(res, EnigmaDuelErrors.Underflow());

        // trasferring
        require(
            IERC20(EDT).transfer(_dest, _amount),
            EnigmaDuelErrors.CollectingFeesFailed()
        );

        // emitting the event
        emit FeesCollected(_amount, _dest);
    }

    function startGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external onlyRole(ADMIN_ROLE) returns (bytes32 _game_room_key) {
        // fetching the minimum tokens required for the game
        uint256 min_required = EnigmaUtils.calc_min_required(
            _game_room_init_params.prizePool,
            DRAW_FEE
        );

        // chceking the minimum requried amount of dueslists for the game
        require(
            min_required <=
                balances[_game_room_init_params.duelist1].available &&
                min_required <=
                balances[_game_room_init_params.duelist2].available,
            EnigmaDuelErrors.InsufficientBalance()
        );

        // generating the game room key
        _game_room_key = EnigmaUtils.gen_game_room_key(
            _game_room_init_params.duelist1,
            _game_room_init_params.duelist1
        );

        // checking the status of the game room
        Structures.GameRoom memory old_data = gameRooms[_game_room_key];

        if (old_data.status != Structures.GameRoomStatus.InActive) {
            // game room not inited
            gameRooms[_game_room_key] = _game_room_init_params;
        } else if (old_data.status != Structures.GameRoomStatus.InActive) {
            // game room inited
            gameRooms[_game_room_key].status = Structures.GameRoomStatus.Active;
            gameRooms[_game_room_key].prizePool = _game_room_init_params
                .prizePool;
        } else {
            revert EnigmaDuelErrors.GameRoomAlreadyStarted();
        }

        // locking the balances
        balances[_game_room_init_params.duelist1] = EnigmaUtils.balance_locker(
            balances[_game_room_init_params.duelist1],
            min_required
        );
        balances[_game_room_init_params.duelist2] = EnigmaUtils.balance_locker(
            balances[_game_room_init_params.duelist2],
            min_required
        );

        // emitting the event
        emit GameStarted(
            _game_room_init_params.duelist1,
            _game_room_init_params.duelist2,
            _game_room_init_params.prizePool
        );
    }

    function finishGameRoom(
        bytes32 _game_room_key,
        address winner
    )
        external
        onlyRole(ADMIN_ROLE)
        returns (Structures.GameRoomResult memory _game_room_result)
    {
        // fetching the game room data
        // Structures.GameRoom memory old_gr = gameRooms[_game_room_key];

        // checking status of the game room
        if (winner == address(0)) {
            // its draw

            // calculating each user share from the prize pool
            uint256 dueslists_share = EnigmaUtils.calc_min_required(
                gameRooms[_game_room_key].prizePool,
                DRAW_FEE
            );

            _game_room_result = Structures.GameRoomResult(
                Structures.GameRoomResultStatus.Draw,
                DRAW_FEE,
                gameRooms[_game_room_key].duelist1,
                gameRooms[_game_room_key].duelist2,
                dueslists_share,
                dueslists_share
            );

            // changing the status of the room
            gameRooms[_game_room_key].status = Structures
                .GameRoomStatus
                .Finished;
            gameRooms[_game_room_key].prizePool = 0;

            // unlocking the balances
            (
                balances[owner()],
                balances[_game_room_result.duelist1]
            ) = EnigmaUtils.balance_unlocker(
                balances[_game_room_result.duelist1],
                balances[owner()],
                dueslists_share,
                false
            );
            (
                balances[owner()],
                balances[_game_room_result.duelist2]
            ) = EnigmaUtils.balance_unlocker(
                balances[_game_room_result.duelist2],
                balances[owner()],
                dueslists_share,
                false
            );
        } else {
            // it was a victory

            // calculating each user share from the prize pool
            uint256 dueslists_share = EnigmaUtils.calc_min_required(
                gameRooms[_game_room_key].prizePool,
                FEE
            );

            _game_room_result = Structures.GameRoomResult(
                Structures.GameRoomResultStatus.Draw,
                DRAW_FEE,
                gameRooms[_game_room_key].duelist1,
                gameRooms[_game_room_key].duelist2,
                dueslists_share,
                dueslists_share
            );

            // changing the status of the room
            gameRooms[_game_room_key].status = Structures
                .GameRoomStatus
                .Finished;
            gameRooms[_game_room_key].prizePool = 0;

            // unlocking the balances
            bool is_winner_1 = false;
            bool is_winner_2 = false;
            if (winner == _game_room_result.duelist1) {
                is_winner_1 = true;
            } else {
                is_winner_2 = true;
            }
            (
                balances[owner()],
                balances[_game_room_result.duelist1]
            ) = EnigmaUtils.balance_unlocker(
                balances[_game_room_result.duelist1],
                balances[owner()],
                dueslists_share,
                is_winner_1
            );
            (
                balances[owner()],
                balances[_game_room_result.duelist2]
            ) = EnigmaUtils.balance_unlocker(
                balances[_game_room_result.duelist2],
                balances[owner()],
                dueslists_share,
                is_winner_2
            );
            emit GameFinished(
                Structures.GameRoomResultStatus.Victory,
                FEE,
                winner,
                dueslists_share
            );
        }
    }

    function depositEDT(
        uint256 deposite_amount
    ) external returns (uint256 _new_balance) {
        // transferring the tokens
        require(
            IERC20(EDT).transferFrom(
                _msgSender(),
                address(this),
                deposite_amount
            ),
            EnigmaDuelErrors.DepositeFailed()
        );

        // changing the user state
        bool res;
        (res, balances[_msgSender()].total) = balances[_msgSender()]
            .total
            .tryAdd(deposite_amount);
        require(res, EnigmaDuelErrors.Overflow());
        (res, balances[_msgSender()].available) = balances[_msgSender()]
            .available
            .tryAdd(deposite_amount);
        require(res, EnigmaDuelErrors.Overflow());

        _new_balance = balances[_msgSender()].available;
    }

    function withdrawEDT(
        uint256 withdraw_amount
    ) external returns (uint256 _new_balance) {
        // cheking the balance of the user
        require(
            balances[_msgSender()].available >= withdraw_amount,
            EnigmaDuelErrors.InsufficientBalance()
        );

        bool res;
        (res, balances[_msgSender()].available) = balances[_msgSender()]
            .available
            .trySub(withdraw_amount);
        require(res, EnigmaDuelErrors.Underflow());
        (res, balances[_msgSender()].total) = balances[_msgSender()]
            .total
            .trySub(withdraw_amount);
        require(res, EnigmaDuelErrors.Underflow());

        // transferring the tokens
        require(
            IERC20(EDT).transfer(_msgSender(), withdraw_amount),
            EnigmaDuelErrors.DepositeFailed()
        );

        _new_balance = balances[_msgSender()].available;
    }
}
