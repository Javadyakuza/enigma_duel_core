// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Ownable} from "@openzeppelin-contracts/access/AccessControl.sol";

contract EnigmaDuel is ERC20, Ownable, AccessControl {
    // fee and token of the platform

    address public EDT;
    uint256 public FEE;


    mapping (address => uint256 ) public balances;

    constructor(
        address _edt,
        uint256 _fee
    ) ERC20("Enigma Dule Token", "EDT") Ownable(msg.sender) {
        EDT = _edt;
        FEE = _fee;
        _grantRole(bytes("OWNER"), msg.sender);
        _setRoleAdmin(bytes("ADMIN"), bytes("OWNER"));
    }


}
