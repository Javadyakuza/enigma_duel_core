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

pub async fn start_game_room(
    game_room_data: GameRoom,
) -> Result<(GameRoom, String), Box<dyn std::error::Error>> {
    let _ = game_room_data;
    dotenv().ok();

    // set up signer and the contract addresses

    let enigma_duel = prepare_enigma_duel().await;

    match enigma_duel
        .start_game_room(game_room_data.clone())
        .send()
        .await
    {
        Ok(res) => match res.await {
            Ok(_) => {
                // calculating the game room key
                let game_key =
                    compute_game_room_key(game_room_data.duelist_1, game_room_data.duelist_2);
                let new_game_room_data: GameRoom =
                    enigma_duel.get_game_room(game_key).call().await.unwrap();
                println!(
                    "data : {:?} \n game: key : {:?}",
                    new_game_room_data,
                    hex::encode(game_key)
                );
                Ok((new_game_room_data, hex::encode_prefixed(game_key)))
            }
            Err(err) => Err({
                println!("{:?}", err);
                Box::new(err)
            }),
        },
        Err(err) => Err({
            println!("{:?}", err);

            Box::new(err)
        }),
    }

    // Ok("".into())
}

pub async fn finish_game_room(
    game_room_key: String,
    winner: Address, // if zero draw
) -> Result<String, Box<dyn std::error::Error>> {
    dotenv().ok();

    // set up signer and the contract addresses

    let enigma_duel = prepare_enigma_duel().await;
    let bytes_vec = hex::decode(game_room_key)?;

    // Ensure the length matches the expected array size
    let bytes_array: [u8; 32] = bytes_vec.try_into().expect("slice with incorrect length");

    // Now you can take a reference to the fixed-size array
    match enigma_duel
        .finish_game_room(bytes_array, winner)
        .send()
        .await
    {
        Ok(res) => match res.await {
            Ok(res) => {
                let decoded = decode_game_finished_event(&res.unwrap().logs[0]).unwrap();

                println!("{:?}", decoded);
                Ok("something".into())
            }
            Err(err) => Err({
                println!("{:?}", err);

                Box::new(err)
            }),
        },
        Err(e) => Err(Box::new(e)),
    }
}

pub async fn get_user_balance(
    user: String,
) -> Result<enigma_duel::Balance, Box<dyn std::error::Error>> {
    let enigma_duel = prepare_enigma_duel().await;

    // Ensure the length matches the expected array size

    let balance: enigma_duel::Balance = enigma_duel
        .get_userbalance(user.parse().unwrap())
        .call()
        .await
        .unwrap();

    println!("user: {user}, balance: {:?}", balance);
    Ok(balance)
}

pub async fn get_game_room(game_room_key: String) -> Result<GameRoom, Box<dyn std::error::Error>> {
    let enigma_duel = prepare_enigma_duel().await;

    let bytes_vec = hex::decode(game_room_key)?;

    // Ensure the length matches the expected array size
    let bytes_array: [u8; 32] = bytes_vec.try_into().expect("slice with incorrect length");

    let game_room_data: GameRoom = enigma_duel.get_game_room(bytes_array).call().await.unwrap();
    Ok(game_room_data)
}

pub async fn get_fee() -> Result<U256, Box<dyn std::error::Error>> {
    Ok(prepare_enigma_duel().await.fee().call().await?)
}

pub async fn get_draw_fee() -> Result<U256, Box<dyn std::error::Error>> {
    Ok(prepare_enigma_duel().await.draw_fee().call().await?)
}

fn get_constants() -> (Addresses, LocalWallet) {
    dotenv().ok();
    let addresses = Addresses::load_addresses().unwrap();
    let priv_key = &env::var("PRIV_KEY").unwrap();
    let wallet = priv_key.parse().unwrap();
    (addresses, wallet)
}

fn compute_game_room_key(duelist1: Address, duelist2: Address) -> [u8; 32] {
    // Encode the duelist addresses as ABI
    let encoded = ethers::abi::encode(&[Token::Address(duelist1), Token::Address(duelist2)]);

    let hash = keccak256(encoded);

    hash
}

async fn prepare_enigma_duel(
) -> enigma_duel::EnigmaDuel<SignerMiddleware<Provider<Http>, Wallet<ecdsa::SigningKey>>> {
    let (addrs, signer) = get_constants();

    let provider = Provider::<Http>::try_from("http://localhost:8545")
        .unwrap()
        .interval(Duration::from_millis(10u64));

    // connect the wallet to the provider
    let client = SignerMiddleware::new_with_provider_chain(
        provider,
        signer.clone().with_chain_id(31337_u64),
    )
    .await
    .unwrap();

    // create a contract instance
    EnigmaDuel::new(
        Address::from_str(&addrs.enigma_duel_proxy).unwrap(),
        client.clone().into(),
    )
}

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

    // Create a RawLog
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
