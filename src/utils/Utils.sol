// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";
import {EnigmaDuelErrors} from "../libs/Errors.sol";
import {Structures} from "../libs/Structures.sol";

library EnigmaUtils {
    using Math for uint256;

    /**
     * @dev Calculates the minimum required balance based on prize pool and fee.
     * @param _prize_pool The total prize pool for the game.
     * @param _fee The fee to be deducted from the prize pool.
     * @return _min_required The minimum required balance for each duelist.
     */
    function calc_min_required(
        uint256 _prize_pool,
        uint256 _fee
    ) internal pure returns (uint256 _min_required) {
        assert(_prize_pool >= _fee);
        uint256 total_fee = _fee * 2;
        require(total_fee <= _prize_pool, EnigmaDuelErrors.Underflow());
        _min_required = (_prize_pool - total_fee) / 2;
    }

    /**
     * @dev Generates a unique key for a game room based on the addresses of the duelists.
     * @param _duelist1 The address of the first duelist.
     * @param _duelist2 The address of the second duelist.
     * @return _game_room_key The generated key for the game room.
     */
    function gen_game_room_key(
        address _duelist1,
        address _duelist2
    ) internal pure returns (bytes32 _game_room_key) {
        _game_room_key = keccak256(abi.encode(_duelist1, _duelist2));
    }

    /**
     * @dev Locks a specified amount from the available balance.
     * @param _balance The current balance of the user.
     * @param _lock_amount The amount to lock.
     * @return _new_balance The updated balance after locking the amount.
     */
    function balance_locker(
        Structures.Balance memory _balance,
        uint256 _lock_amount
    ) internal pure returns (Structures.Balance memory _new_balance) {
        _new_balance = _balance;
        require(_balance.available >= _lock_amount, EnigmaDuelErrors.Underflow());
        _new_balance.available -= _lock_amount;
        _new_balance.locked += _lock_amount;
    }

    /**
     * @dev Unlocks a specified amount and updates the balances accordingly.
     * @param _balance The current balance of the user.
     * @param _admin_balance The current balance of the admin.
     * @param _unlock_amount The amount to unlock.
     * @param is_winner A flag indicating if the user is the winner.
     * @return _new_admin_balance The updated admin balance.
     * @return _new_balance The updated user balance.
     */
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

        if (is_winner) {
            uint256 winner_share = _unlock_amount * 2;
            _new_balance.available += winner_share;
            _new_balance.total += _unlock_amount;
        } else {
            _new_balance.available += _unlock_amount;
        }

        require(_new_balance.locked >= _unlock_amount, EnigmaDuelErrors.Underflow());
        _new_balance.locked -= _unlock_amount;

        if (_new_balance.locked != 0) {
            _new_admin_balance.total += _new_balance.locked;
            _new_balance.locked = 0;
        }
    }
}
