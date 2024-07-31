// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EDTToken is ERC20, Ownable{
    constructor(uint256 initialSupply) ERC20("Enigma Duel Token", "EDT") Ownable(_msgSender()) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address user, uint256 amount) public {
        require(msg.sender == owner(), "Only owner is allowed to mint");
        _mint(user, amount);
    }
}
