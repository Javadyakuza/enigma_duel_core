// deposit_tokens_test(U256::from(50_u128 * 10_u128.pow(18))).await?;

pub async fn deposit_tokens_test(
    amount: U256,
) -> Result<TransactionReceipt, Box<dyn std::error::Error>> {
    dotenv().ok();

    // Set up signer and the contract addresses

    let (addrs, signer) = get_constants();
    let priv_key = &env::var("ANVIL_ACC_TEST_1").unwrap();
    let signer_1: LocalWallet = priv_key.parse().unwrap();

    let priv_key = &env::var("ANVIL_ACC_TEST_2").unwrap();
    let signer_2: LocalWallet = priv_key.parse().unwrap();

    let provider: Provider<Http> =
        Provider::<Http>::try_from("http://localhost:8545")?.interval(Duration::from_millis(10u64));

    // Connect the wallet to the provider
    let admin = SignerMiddleware::new_with_provider_chain(
        provider.clone(),
        signer.clone().with_chain_id(31337u64),
    )
    .await?;

    let client1 = SignerMiddleware::new_with_provider_chain(
        provider.clone(),
        signer_1.clone().with_chain_id(31337u64),
    )
    .await?;
    let client2 = SignerMiddleware::new_with_provider_chain(
        provider,
        signer_2.clone().with_chain_id(31337u64),
    )
    .await?;

    // Create a contract instance
    let enigma_duel1 = EnigmaDuel::new(
        Address::from_str(&addrs.EnigmaDuelProxy).unwrap(),
        Arc::new(client1.clone()),
    );
    let enigma_duel2 = EnigmaDuel::new(
        Address::from_str(&addrs.EnigmaDuelProxy).unwrap(),
        Arc::new(client2.clone()),
    );

    // Approve the tokens
    let token1 = EDT::new(
        Address::from_str(&addrs.EnigmaDuelToken).unwrap(),
        Arc::new(client1.clone()),
    );
    let token2 = EDT::new(
        Address::from_str(&addrs.EnigmaDuelToken).unwrap(),
        Arc::new(client2.clone()),
    );

    let tokenAdmin = EDT::new(
        Address::from_str(&addrs.EnigmaDuelToken).unwrap(),
        Arc::new(admin.clone()),
    );

    tokenAdmin
        .transfer(signer_1.clone().address(), amount)
        .send()
        .await?
        .await?;
    tokenAdmin
        .transfer(signer_2.clone().address(), amount)
        .send()
        .await?
        .await?;
    let approve_tx = token1
        .approve(Address::from_str(&addrs.EnigmaDuelProxy).unwrap(), amount)
        .send()
        .await?
        .await?;

    let approve_tx = token2
        .approve(Address::from_str(&addrs.EnigmaDuelProxy).unwrap(), amount)
        .send()
        .await?
        .await?;

    // Deposit the tokens
    let receipt = enigma_duel1.deposit_edt(amount).send().await?.await?;
    let receipt = enigma_duel2.deposit_edt(amount).send().await?.await?;

    println!(
        "{:?}{:?}",
        enigma_duel1
            .get_userbalance(signer_1.address())
            .call()
            .await?,
        enigma_duel2
            .get_userbalance(signer_2.address())
            .call()
            .await?
    );

    Ok(receipt.unwrap())
}
