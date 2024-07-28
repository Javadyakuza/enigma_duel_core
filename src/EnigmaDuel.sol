// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {EnigmaDuelErrors} from "./Errors.sol";
import {IEnigmaDuel} from "./IEnigmaDuel.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {Structures} from "./Structures.sol";


contract EnigmaDuel is IEnigmaDuel, Ownable, AccessControl {
    using Math for uint256;

    // fee and token of the platform

    address public EDT;
    uint256 public FEE;
    bytes32 constant ADMIN_ROLE = bytes32("ADMIN");

    mapping (address => uint256 ) public balances;

    constructor(
        address _edt,
        uint256 _fee
    ) ERC20("Enigma Dule Token", "EDT") Ownable(_msgSender()) {
        EDT = _edt;
        FEE = _fee;
        _grantRole(bytes32("OWNER"), msg.sender);
        _setRoleAdmin(bytes32("ADMIN"), bytes32("OWNER"));
    }

    function WithdrawCollectedFees(uint256 _amount, address _dest) external onlyRole(bytes32("ADMIN")) {
        // checking the destination address
        require(_dest != address(0), EnigmaDuelErrors.AddressZeroNotSupported());

        // checking the requested withdraw amount
        require(balances[_msgSender()] <= _amount, EnigmaDuelErrors.InsufficientBalance());

        // decreasing the balance
        (, balances[_msgSender()]) = balances[_msgSender()].trySub(_amount);
    
        // trasferring 
        require(IERC20(EDT).transfer(_dest, value), EnigmaDuelErrors.CollectingFeesFailed());


        // emitting the event
        emit FeesCollected(_amount, _dest);
    }


    
    function createGameRoom(
        Structures.GameRoom calldata _game_room_init_params
    ) external returns (string memory _game_room_key){
        "";
    }
}
