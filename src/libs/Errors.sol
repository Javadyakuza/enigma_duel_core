// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/**
 * @title EnigmaDuelErrors
 * @dev A library that defines custom error types used in the Enigma Duel smart contracts.
 */
library EnigmaDuelErrors {

    /**
     * @dev Error indicating that the game room status is invalid.
     */
    error InvalidGameRoomStatus();

    /**
     * @dev Error indicating that the balance is insufficient for the requested operation.
     */
    error InsufficientBalance();

    /**
     * @dev Error indicating that a zero address is not supported in the operation.
     */
    error AddressZeroNotSupported();

    /**
     * @dev Error indicating that the deposit operation has failed.
     */
    error DepositeFailed();

    /**
     * @dev Error indicating that the caller is not authorized to perform the operation.
     */
    error Unauthorized();

    /**
     * @dev Error indicating that the fee collection operation has failed.
     */
    error CollectingFeesFailed();

    /**
     * @dev Error indicating an arithmetic overflow.
     */
    error Overflow();

    /**
     * @dev Error indicating an arithmetic underflow.
     */
    error Underflow();

}
