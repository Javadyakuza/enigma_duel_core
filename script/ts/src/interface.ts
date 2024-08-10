import { BigNumberish, BytesLike } from "ethers";
import { Balance, GameRoom } from "./types";
export interface IEnigmaDuelClient {
  /**
   * Deposits EDT tokens into the contract.
   * @param depositAmount The amount of EDT tokens to deposit.
   * @returns The new balance of the user.
   */
  depositEDT(depositAmount: BigNumberish): Promise<BigNumberish>;

  /**
   * Withdraws EDT tokens from the contract.
   * @param withdrawAmount The amount of EDT tokens to withdraw.
   * @returns The new balance of the user.
   */
  withdrawEDT(withdrawAmount: BigNumberish): Promise<BigNumberish>;

  /**
   * Returns the balance structure of a user.
   * @param user The address of the user.
   * @returns The balance structure of the user.
   */
  getUserbalance(user: string): Promise<Balance>;

  /**
   * Returns the game room structure of a game room.
   * @param gameRoomKey The key of the game room.
   * @returns The game room structure.
   */
  getGameRoom(gameRoomKey: BytesLike): Promise<GameRoom>;

  /**
   * Returns the fee for a victory.
   * @returns The fee for a victory.
   */
  getFEE(): Promise<BigNumberish>;

  /**
   * Returns the fee for a draw.
   * @returns The fee for a draw.
   */
  getDRAW_FEE(): Promise<BigNumberish>;

  /**
   * Returns the address of the EDT token.
   * @returns The address of the EDT token.
   */
  getEDT(): Promise<string>;
}
