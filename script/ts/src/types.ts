import { BigNumberish } from "ethers";

// Equivalent of the Balance struct in Solidity
export interface Balance {
  total: BigNumberish;
  locked: BigNumberish;
  available: BigNumberish;
}

// Equivalent of the GameRoomStatus enum in Solidity
export enum GameRoomStatus {
  InActive, // The game room is not active.
  Finished, // The game room has finished.
  Active // The game room is currently active.
}

// Equivalent of the GameRoom struct in Solidity
export interface GameRoom {
  duelist1: string; // The address of the first duelist.
  duelist2: string; // The address of the second duelist.
  prizePool: BigNumberish; // The total prize pool for the game.
  status: GameRoomStatus; // The current status of the game room.
}

// Equivalent of the GameRoomResultStatus enum in Solidity
export enum GameRoomResultStatus {
  Draw, // The game ended in a draw.
  Victory // The game ended in a victory for one of the duelists.
}
