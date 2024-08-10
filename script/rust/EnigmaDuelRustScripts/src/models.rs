use ethers::{contract::EthEvent, types::{Address, U256}};
use std::fs;
use std::path::Path;
use serde::{Deserialize, Serialize};


pub struct Balance {
    pub total: U256,
    pub locked: U256,
    pub available: U256
}


#[derive(Debug, Deserialize, Serialize)]
pub struct Addresses {
    pub enigma_duel: String,
    pub enigma_duel_state: String,
    pub enigma_duel_token: String,
    pub enigma_duel_proxy_admin: String,
    pub enigma_duel_proxy: String,
}

impl Addresses {
    pub fn load_addresses() -> Result<Self, Box<dyn std::error::Error>> {
        let path = Path::new("./data/constants/addresses.json");
        let data = fs::read_to_string(path)?;
        let addresses: Self = serde_json::from_str(&data)?;
        Ok(addresses)
    }
}
pub enum GameRoomStatus {
    InActive, // The game room is not active.
    Finished, // The game room has finished.
    Active // The game room is currently active.
}
pub struct GameRoom {
    pub duelist1: Address,
    pub duelist2: Address,
    pub prize_pool: U256,
    pub status: GameRoomStatus,
}


#[derive(Clone, Debug, Serialize, Deserialize, EthEvent)]
pub struct GameFinished {
    pub status: u8,
    pub fee: U256,
    pub duelist1:Address , // Zero if draw
    pub duelist2: Address, // Zero if draw
    pub duelist1_received: U256 ,
    pub duelist2_received: U256,
}