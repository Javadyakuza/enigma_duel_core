// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {EnigmaDuelErrors} from "./Errors.sol";
import {Structures} from "./Structures.sol";

library EnigmaUtils {
    using Math for uint256;

    function calc_min_required(
        uint256 _prize_pool,
        uint256 _fee
    ) internal pure returns (uint256 _min_required) {
        assert(_prize_pool >= _fee);
        (, uint256 subbed) = _prize_pool.trySub(_fee);
        (, _min_required) = subbed.tryDiv(2);
    }

    
    function gen_game_key(
        address _duelist1,
        address _duelist2
    ) internal pure returns (bytes32 _game_key) {
        _game_key = keccak256(abi.encode(_duelist1, _duelist2));
    }

    function balance_locker(
        Structures.Balance memory _balance,
        uint256 _lock_amount
    ) internal pure returns (Structures.Balance memory _new_balance) {
        _new_balance = _balance;
        (, _new_balance.available) = _balance.available.trySub(_lock_amount);
    }

    function balance_unlocker(
        Structures.Balance memory _balance,
        uint256 _lock_amount
    ) internal pure returns (Structures.Balance memory _new_balance) {
        _new_balance = _balance;
        (, _new_balance.available) = _balance.available.tryAdd(_lock_amount);
    }
}
