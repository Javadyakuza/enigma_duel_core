import { ethers, BigNumberish, BytesLike, toBigInt } from "ethers";
import { Balance, GameRoom } from "./types";
import {IEnigmaDuelClient} from "./interface";
import EDABI  from "./build/EnigmaDuelABI.json"
import EDTABI  from "./build/EDTABI.json"
import {addresses} from "./constants.ts";
export type Signer = ethers.Signer;

export const enigmaDuelClient = (provider: ethers.Provider, signer: ethers.Signer): IEnigmaDuelClient => {
  // creating the contracts instances
  const enigma_duel = new ethers.Contract(addresses.EnigmaDuelProxy, EDABI, signer);
  const edt = new ethers.Contract(addresses.EnigmaDuelToken, EDTABI, signer);

  const depositEDT = async (depositAmount: BigNumberish): Promise<BigNumberish> => {
    // approving the enigma dule contract to transfer tokens from users account
    const approve_tx = await edt.approve(addresses.EnigmaDuelProxy, depositAmount);
    const approve_receipt = await approve_tx.wait();
    console.log(`approved ennigma duel for ${depositAmount}`);

    const deposit_tx = await enigma_duel.depositEDT(depositAmount);
    const deposite_receipt = await deposit_tx.wait();
    
    return (await getUserbalance(await signer.getAddress())).available;
  };

  const withdrawEDT = async (withdrawAmount: BigNumberish): Promise<BigNumberish> => {
    const tx = await enigma_duel.withdrawEDT(withdrawAmount);
    const receipt = await tx.wait();
    return receipt.events[0].args._new_balance;
  };

  const getUserbalance = async (user: string): Promise<Balance> => {
    return enigma_duel.getUserbalance(user);
  };

  const getGameRoom = async (gameRoomKey: BytesLike): Promise<GameRoom> => {
    return enigma_duel.getGameRoom(gameRoomKey);
  };

  const getFEE = async (): Promise<BigNumberish> => {
    return enigma_duel.getFEE();
  };

  const getDRAW_FEE = async (): Promise<BigNumberish> => {
    return enigma_duel.getDRAW_FEE();
  };

  const getEDT = async (): Promise<string> => {
    return enigma_duel.getEDT();
  };

  return {
    depositEDT,
    withdrawEDT,
    getUserbalance,
    getGameRoom,
    getFEE,
    getDRAW_FEE,
    getEDT,
  };
};

