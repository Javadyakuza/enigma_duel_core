pub mod models;
use ethabi::{Address, Event, EventParam, ParamType, RawLog, Token};
use ethers::{
    core::k256::ecdsa,
    middleware::SignerMiddleware,
    prelude::abigen,
    providers::{Http, Provider},
    signers::{LocalWallet, Signer, Wallet},
    types::Log,
    utils::{hex, keccak256},
};
use models::{Addresses, GameFinished};
use dotenv::dotenv;
use ethers::types::U256;
use eyre::Result;
use std::env;
use std::str::FromStr;
use std::time::Duration;
abigen!(EnigmaDuel, "./data/build/EnigmaDuelABI.json");
abigen!(EDT, "./data/build/EDTABI.json");

/// Starts a new game room with the given `GameRoom` data.
/// 
/// # Arguments
/// 
/// * `game_room_data` - Data related to the game room to be started.
///
/// # Returns
///
/// A tuple containing the updated `GameRoom` data and the game room key as a hexadecimal string.
pub async fn start_game_room(
    game_room_data: GameRoom,
) -> Result<(GameRoom, String), Box<dyn std::error::Error>> {
    dotenv().ok();  // Load environment variables

    // Prepare the Enigma Duel contract instance
    let enigma_duel = prepare_enigma_duel().await;

    // Attempt to start the game room on the blockchain
    match enigma_duel.start_game_room(game_room_data.clone()).send().await {
        Ok(res) => match res.await {
            Ok(_) => {
                // Compute the game room key based on the duelist addresses
                let game_key = compute_game_room_key(game_room_data.duelist_1, game_room_data.duelist_2);
                
                // Retrieve the updated game room data from the blockchain
                let new_game_room_data: GameRoom = enigma_duel.get_game_room(game_key).call().await.unwrap();
                
                println!("data: {:?} \n game key: {:?}", new_game_room_data, hex::encode(game_key));
                
                // Return the updated game room data and the game key as a hexadecimal string
                Ok((new_game_room_data, hex::encode_prefixed(game_key)))
            }
            Err(err) => {
                println!("{:?}", err);
                Err(Box::new(err))
            }
        },
        Err(err) => {
            println!("{:?}", err);
            Err(Box::new(err))
        }
    }
}

/// Finishes the game room identified by `game_room_key` and declares a `winner`.
/// 
/// # Arguments
/// 
/// * `game_room_key` - The key identifying the game room to finish.
/// * `winner` - The address of the winner (if zero, it's a draw).
///
/// # Returns
///
/// A string result indicating success or error.
pub async fn finish_game_room(
    game_room_key: String,
    winner: Address,
) -> Result<String, Box<dyn std::error::Error>> {
    dotenv().ok();  // Load environment variables

    // Prepare the Enigma Duel contract instance
    let enigma_duel = prepare_enigma_duel().await;

    // Decode the game room key from hexadecimal to bytes
    let bytes_vec = hex::decode(game_room_key)?;
    let bytes_array: [u8; 32] = bytes_vec.try_into().expect("slice with incorrect length");

    // Attempt to finish the game room on the blockchain
    match enigma_duel.finish_game_room(bytes_array, winner).send().await {
        Ok(res) => match res.await {
            Ok(res) => {
                // Decode the game finished event from the blockchain logs
                let decoded = decode_game_finished_event(&res.unwrap().logs[0]).unwrap();
                println!("{:?}", decoded);
                Ok("Game finished successfully.".into())
            }
            Err(err) => {
                println!("{:?}", err);
                Err(Box::new(err))
            }
        },
        Err(e) => Err(Box::new(e)),
    }
}

/// Retrieves the balance of a user identified by `user`.
/// 
/// # Arguments
/// 
/// * `user` - The address of the user as a string.
///
/// # Returns
///
/// The balance of the user.
pub async fn get_user_balance(
    user: String,
) -> Result<enigma_duel::Balance, Box<dyn std::error::Error>> {
    let enigma_duel = prepare_enigma_duel().await;

    // Retrieve the user's balance from the blockchain
    let balance: enigma_duel::Balance = enigma_duel
        .get_userbalance(user.parse().unwrap())
        .call()
        .await
        .unwrap();

    println!("user: {user}, balance: {:?}", balance);
    Ok(balance)
}

/// Retrieves the game room data for a given `game_room_key`.
/// 
/// # Arguments
/// 
/// * `game_room_key` - The key identifying the game room.
///
/// # Returns
///
/// The `GameRoom` data associated with the given key.
pub async fn get_game_room(game_room_key: String) -> Result<GameRoom, Box<dyn std::error::Error>> {
    let enigma_duel = prepare_enigma_duel().await;

    // Decode the game room key from hexadecimal to bytes
    let bytes_vec = hex::decode(game_room_key)?;
    let bytes_array: [u8; 32] = bytes_vec.try_into().expect("slice with incorrect length");

    // Retrieve the game room data from the blockchain
    let game_room_data: GameRoom = enigma_duel.get_game_room(bytes_array).call().await.unwrap();
    Ok(game_room_data)
}

/// Retrieves the platform fee for creating a game room.
/// 
/// # Returns
///
/// The platform fee as a `U256` value.
pub async fn get_fee() -> Result<U256, Box<dyn std::error::Error>> {
    Ok(prepare_enigma_duel().await.fee().call().await?)
}

/// Retrieves the platform fee for a draw in a game.
/// 
/// # Returns
///
/// The draw fee as a `U256` value.
pub async fn get_draw_fee() -> Result<U256, Box<dyn std::error::Error>> {
    Ok(prepare_enigma_duel().await.draw_fee().call().await?)
}

/// Loads the contract addresses and wallet from environment variables.
/// 
/// # Returns
///
/// A tuple containing the contract addresses and the local wallet.
fn get_constants() -> (Addresses, LocalWallet) {
    dotenv().ok();  // Load environment variables
    let addresses = Addresses::load_addresses().unwrap();
    let priv_key = &env::var("PRIV_KEY").unwrap();
    let wallet = priv_key.parse().unwrap();
    (addresses, wallet)
}

/// Computes the game room key based on the addresses of two duelists.
/// 
/// # Arguments
/// 
/// * `duelist1` - The address of the first duelist.
/// * `duelist2` - The address of the second duelist.
///
/// # Returns
///
/// The computed game room key as a fixed-size byte array.
fn compute_game_room_key(duelist1: Address, duelist2: Address) -> [u8; 32] {
    // Encode the duelist addresses as ABI
    let encoded = ethers::abi::encode(&[Token::Address(duelist1), Token::Address(duelist2)]);

    // Compute the keccak256 hash of the encoded data
    let hash = keccak256(encoded);

    hash
}

/// Prepares the Enigma Duel contract instance for interaction.
/// 
/// # Returns
///
/// An instance of the `EnigmaDuel` contract.
async fn prepare_enigma_duel(
) -> enigma_duel::EnigmaDuel<SignerMiddleware<Provider<Http>, Wallet<ecdsa::SigningKey>>> {
    let (addrs, signer) = get_constants();

    let provider = Provider::<Http>::try_from("http://localhost:8545")
        .unwrap()
        .interval(Duration::from_millis(10u64));

    // Connect the wallet to the provider and create the client
    let client = SignerMiddleware::new_with_provider_chain(
        provider,
        signer.clone().with_chain_id(31337_u64),
    )
    .await
    .unwrap();

    // Create and return a contract instance
    EnigmaDuel::new(
        Address::from_str(&addrs.EnigmaDuelProxy).unwrap(),
        client.clone().into(),
    )
}

/// Decodes the `GameFinished` event from a blockchain log.
///
/// # Arguments
/// 
/// * `log` - The log containing the `GameFinished` event data.
///
/// # Returns
///
/// An optional `GameFinished` struct containing the decoded event data.
fn decode_game_finished_event(log: &Log) -> Option<GameFinished> {
    // Define the event ABI
    let event_abi = Event {
        name: "GameFinished".to_string(),
        inputs: vec![
            EventParam {
                name: "status".to_string(),
                kind: ParamType::Uint(8),
                indexed: false,
            },
            EventParam {
                name: "fee".to_string(),
                kind: ParamType::Uint(256),
                indexed: false,
            },
            EventParam {
                name: "duelist1".to_string(),
                kind: ParamType::Address,
                indexed: false,
            },
            EventParam {
                name: "duelist1_received".to_string(),
                kind: ParamType::Uint(256),
                indexed: false,
            },
            EventParam {
                name: "duelist2".to_string(),
                kind: ParamType::Address,
                indexed: false,
            },
            EventParam {
                name: "duelist2_received".to_string(),
                kind: ParamType::Uint(256),
                indexed: false,
            },
        ],
        anonymous: false,
    };

    // Create a RawLog from the provided log
    let raw_log = RawLog {
        topics: log.topics.clone(),
        data: log.data.clone().0.to_vec(),
    };

    // Decode the log
    match event_abi.parse_log(raw_log) {
        Ok(decoded_log) => {
            let status = decoded_log.params[0]
                .value
                .clone()
                .into_uint()
                .unwrap()
                .as_u64() as u8;
            let fee = decoded_log.params[1].value.clone().into_uint().unwrap();
            let duelist1 = decoded_log.params[2].value.clone().into_address().unwrap();
            let duelist1_received = decoded_log.params[3].value.clone().into_uint().unwrap();
            let duelist2 = decoded_log.params[4].value.clone().into_address().unwrap();
            let duelist2_received = decoded_log.params[5].value.clone().into_uint().unwrap();

            Some(GameFinished {
                status,
                fee,
                duelist1,
                duelist1_received,
                duelist2,
                duelist2_received,
            })
        }
        Err(_) => None,
    }
}
