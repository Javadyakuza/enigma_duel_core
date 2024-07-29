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
        (, _fee) = _fee.tryMul(2);
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
        bool res;
        (res, _new_balance.available) = _balance.available.trySub(_lock_amount);
        assert(res); // impossible assert
        (res, _new_balance.locked) = _balance.locked.tryAdd(_lock_amount);
        assert(res);
    }

    function balance_unlocker(
        Structures.Balance memory _balance,
        Structures.Balance memory _admin_balance,
        uint256 _unlock_amount,
        bool is_winner
    )
        internal
        pure
        returns (
            Structures.Balance memory _new_admin_balance,
            Structures.Balance memory _new_balance
        )
    {
        _new_balance = _balance;
        _new_admin_balance = _admin_balance;
        bool res;

        if (is_winner) {
            uint256 winner_share;
            (res, winner_share) = _unlock_amount.tryMul(2);
            assert(res);
            (res, _new_balance.available) = _balance.available.tryAdd(
                winner_share
            );
            assert(res);
            (res, _new_balance.total) = _balance.total.tryAdd(_unlock_amount);
            assert(res);
        } else {
            (res, _new_balance.available) = _balance.available.tryAdd(
                _unlock_amount
            );
        }

        (res, _new_balance.locked) = _balance.locked.trySub(_unlock_amount);
        assert(res);
        if (_new_balance.locked != 0) {
            // it was not draw
            (res, _new_admin_balance.total) = _new_admin_balance.total.tryAdd(
                _new_balance.locked
            );
            assert(res);
            _new_balance.locked = 0;
        }
    }
}
