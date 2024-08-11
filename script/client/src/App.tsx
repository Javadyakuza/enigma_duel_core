import React, { useState } from "react";
import { ethers } from "ethers";
import { enigmaDuelClient, Signer } from "./helpers"; // Import the module
const { ethereum } = window as any;
import {Balance} from "./types"
import "./App.css"
function App() {
  const [depositAmount, setDepositAmount] = useState<number>(0);
  const [withdrawAmount, setWithdrawAmount] = useState<number>(0);
  const [userAddress, setUserAddress] = useState<string>("");
  const [gameRoomKey, setGameRoomKey] = useState<string>("");
  const [result, setResult] = useState<string>("");

  // Initialize the provider and signer (using ethers.js)

  const handleDeposit = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const response = await enigmaDuel.depositEDT(depositAmount);
      setResult(`New Balance after Deposit: ${response.toString()}`);
    } catch (error) {
      console.error(error);
      setResult("Error during deposit.");
    }
  };

  const handleWithdraw = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const response = await enigmaDuel.withdrawEDT(withdrawAmount);
      setResult(`New Balance after Withdrawal: ${response.toString()}`);
    } catch (error) {
      console.error(error);
      setResult("Error during withdrawal.");
    }
  };

  const handleGetUserBalance = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      let balance = await enigmaDuel.getUserbalance(userAddress);
      balance = {
        total: Number(balance.total), 
        locked: Number(balance.locked),
        available: Number(balance.available)
      }
      setResult(`User Balance: ${JSON.stringify(balance, null, 2)}`);
    } catch (error) {
      console.error(error);
      setResult("Error fetching user balance.");
    }
  };

  const handleGetGameRoom = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const gameRoom = await enigmaDuel.getGameRoom(gameRoomKey);
      setResult(`Game Room: ${JSON.stringify(gameRoom, null, 2)}`);
    } catch (error) {
      console.error(error);
      setResult("Error fetching game room.");
    }
  };

  const handleGetFEE = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const fee = await enigmaDuel.getFEE();
      setResult(`Victory Fee: ${fee.toString()}`);
    } catch (error) {
      console.error(error);
      setResult("Error fetching fee.");
    }
  };

  const handleGetDrawFEE = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const drawFee = await enigmaDuel.getDRAW_FEE();
      setResult(`Draw Fee: ${drawFee.toString()}`);
    } catch (error) {
      console.error(error);
      setResult("Error fetching draw fee.");
    }
  };

  const handleGetEDT = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const enigmaDuel = enigmaDuelClient(provider, signer);
    try {
      const edtAddress = await enigmaDuel.getEDT();
      setResult(`EDT Token Address: ${edtAddress}`);
    } catch (error) {
      console.error(error);
      setResult("Error fetching EDT token address.");
    }
  };

  return (
    <div className="container">
      <h1>Enigma Duel Client</h1>

      <div>
        <h2>Deposit EDT Tokens</h2>
        <input
          type="number"
          value={depositAmount}
          onChange={(e) => setDepositAmount(Number(e.target.value))}
          placeholder="Deposit Amount"
        />
        <button onClick={handleDeposit}>Deposit</button>
      </div>

      <div>
        <h2>Withdraw EDT Tokens</h2>
        <input
          type="number"
          value={withdrawAmount}
          onChange={(e) => setWithdrawAmount(Number(e.target.value))}
          placeholder="Withdraw Amount"
        />
        <button onClick={handleWithdraw}>Withdraw</button>
      </div>

      <div>
        <h2>Get User Balance</h2>
        <input
          type="text"
          value={userAddress}
          onChange={(e) => setUserAddress(e.target.value)}
          placeholder="User Address"
        />
        <button onClick={handleGetUserBalance}>Get Balance</button>
      </div>

      <div>
        <h2>Get Game Room, (can't start a game room from client, must be started already from the server)</h2>
        <input
          type="text"
          value={gameRoomKey}
          onChange={(e) => setGameRoomKey(e.target.value)}
          placeholder="Game Room Key"
        />
        <button onClick={handleGetGameRoom}>Get Game Room</button>
      </div>

      <div>
        <h2>Get Fees</h2>
        <button onClick={handleGetFEE}>Get Victory Fee</button>
        <button onClick={handleGetDrawFEE}>Get Draw Fee</button>
      </div>

      <div>
        <h2>Get EDT Token Address</h2>
        <button onClick={handleGetEDT}>Get EDT Address</button>
      </div>

      <div>
        <h3>Result</h3>
        <pre>{result}</pre>
      </div>
    </div>
  );
}

export default App;
