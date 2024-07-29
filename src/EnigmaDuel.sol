// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {EnigmaDuelErrors} from "./Errors.sol";
import {IEnigmaDuel} from "./IEnigmaDuel.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {Structures} from "./Structures.sol";
import {EnigmaUtils} from "./Utils.sol";

contract EnigmaDuel is IEnigmaDuel, Ownable, AccessControl {
    using Math for uint256;

    // fee and token of the platform

    address public EDT;
    uint256 public FEE;

    bytes32 constant ADMIN_ROLE = bytes32("ADMIN");
    bytes32 constant OWNER_ROLE = bytes32("OWNER");

    mapping(address => Structures.Balance) public balances;
    mapping(bytes32 => Structures.GameRoom) private gameRooms;

    constructor(address _edt, uint256 _fee) Ownable(_msgSender()) {
        EDT = _edt;
        FEE = _fee;
        _grantRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
    }

    function WithdrawCollectedFees(
        uint256 _amount,
        address _dest
    ) external onlyRole(ADMIN_ROLE) {
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

        // decreasing the balance
        (, balances[_msgSender()].total) = balances[_msgSender()].total.trySub(_amount);

        // trasferring
        require(
            IERC20(EDT).transfer(_dest, _amount),
            EnigmaDuelErrors.CollectingFeesFailed()
        );

        // emitting the event
        emit FeesCollected(_amount, _dest);
    }

    function createGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external onlyRole(ADMIN_ROLE) returns (bytes32 _game_room_key) {
        // chceking the minimum requried amount of dueslists for the game
        require(
            EnigmaUtils.calc_min_required(
                _game_room_init_params.prizePool,
                balances[_game_room_init_params.duelist1].available,
                FEE
            ) &&
                EnigmaUtils.calc_min_required(
                    _game_room_init_params.prizePool,
                    balances[_game_room_init_params.duelist2].available,
                    FEE
                ),
            EnigmaDuelErrors.InsufficientBalance()
        );

        // generating the game room key
        _game_room_key = EnigmaUtils.gen_game_key(_game_room_init_params.duelist1, _game_room_init_params.duelist1);

        // checking the status of the game room
        Structures.GameRoom memory old_data = gameRooms[_game_room_key];

        if(old_data.status != Structures.GameRoomStatus.InActive) {
            // game room not inited
            gameRooms[_game_room_key] = _game_room_init_params;

        } else if (old_data.status != Structures.GameRoomStatus.InActive) {
            // game room inited
            gameRooms[_game_room_key].status = Structures.GameRoomStatus.Active;
            gameRooms[_game_room_key].prizePool = _game_room_init_params.prizePool;            
        } else {
            revert EnigmaDuelErrors.GameRoomAlreadyStarted();
        }

        // locking the balances
        // balances[_game_room_init_params.duelist1] = EnigmaUtils.balance_locker(balances[_game_room_init_params.duelist1]);

    }

    function userBalance() public view returns(Structures.Balance memory _balance){
        _balance = balances[_msgSender()];
    }

}
