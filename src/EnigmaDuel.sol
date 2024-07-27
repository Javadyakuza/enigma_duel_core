// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract EnigmaDuel is ERC20 {
    // fee and token of the platform

    address public EDT;
    uint256 public FEE;

    constructor(address _edt, uint256 _fee) ERC20("Enigma Dule Token", "EDT") {
        EDT = _edt;
        Fee = FEE;
    }
    
}
