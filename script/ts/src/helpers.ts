import { ethers, BigNumberish, BytesLike, toBigInt } from "ethers";
import { Balance, GameRoom } from "./types";
import {IEnigmaDuelClient} from "./interface";

// Assume the ABI and contract address are provided
const ABI = [ /* Contract ABI goes here */ ];
const CONTRACT_ADDRESS = "0xYourContractAddressHere";

const enigmaDuelClient = (provider: ethers.Provider, signer: ethers.Signer): IEnigmaDuelClient => {
  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

  const depositEDT = async (depositAmount: BigNumberish): Promise<BigNumberish> => {
    const tx = await contract.depositEDT(depositAmount);
    const receipt = await tx.wait();
    return receipt.events[0].args._new_balance;
  };

  const withdrawEDT = async (withdrawAmount: BigNumberish): Promise<BigNumberish> => {
    const tx = await contract.withdrawEDT(withdrawAmount);
    const receipt = await tx.wait();
    return receipt.events[0].args._new_balance;
  };

  const getUserbalance = async (user: string): Promise<Balance> => {
    return contract.getUserbalance(user);
  };

  const getGameRoom = async (gameRoomKey: BytesLike): Promise<GameRoom> => {
    return contract.getGameRoom(gameRoomKey);
  };

  const getFEE = async (): Promise<BigNumberish> => {
    return contract.getFEE();
  };

  const getDRAW_FEE = async (): Promise<BigNumberish> => {
    return contract.getDRAW_FEE();
  };

  const getEDT = async (): Promise<string> => {
    return contract.getEDT();
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

