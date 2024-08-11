forge create src/EnigmaDuel.sol:EnigmaDuel --private-key=$PRIV_KEY --via-ir >  ./script/deployer/local/ed
ed_addr=$(sed -n '5p' ./script/deployer/local/ed)

forge create src/EnigmaDuelToken.sol:EDT --private-key=$PRIV_KEY --constructor-args 1000000000000000000000 --via-ir > ./script/deployer/local/edt
edt_addr=$(sed -n '5p' ./script/deployer/local/edt)

forge create src/EnigmaDuelState.sol:EnigmaDuelState --private-key=$PRIV_KEY --via-ir > ./script/deployer/local/eds
eds_addr=$(sed -n '5p' ./script/deployer/local/eds)

forge create src/EnigmaDuelProxyAdmin.sol:EnigmaDuelProxyAdmin --private-key=$PRIV_KEY --via-ir > ./script/deployer/local/edpa
edpa_addr=$(sed -n '5p' ./script/deployer/local/edpa)

cast calldata "initialize(address,address,uint256,uint256)" "${eds_addr:13}" "${edt_addr:13}" 1000000000000000000 0 > ./script/deployer/local/data

forge create src/EnigmaDuelProxy.sol:EnigmaDuelProxy --private-key=$PRIV_KEY --constructor-args "${ed_addr:13}" "${edpa_addr:13}" $(cat ./script/deployer/local/data) > ./script/deployer/local/edp
edp_addr=$(sed -n '5p' ./script/deployer/local/edp)

cast send  "${eds_addr:13}" "function initialize(address)" "${edp_addr:13}" --rpc-url "http://localhost:8545" --private-key=$PRIV_KEY  > /dev/null

echo -e '{\n  "EnigmaDuel": "'"${ed_addr:13}"'",\n  "EnigmaDuelState": "'"${eds_addr:13}"'",\n  "EnigmaDuelToken": "'"${edt_addr:13}"'",\n  "EnigmaDuelProxyAdmin": "'"${edpa_addr:13}"'",\n  "EnigmaDuelProxy": "'"${edp_addr:13}"'"\n}' > ./script/deployer/local/addresses.json

rm -rf  ./script/deployer/local/ed  ./script/deployer/local/eds  ./script/deployer/local/edt  ./script/deployer/local/edpa  ./script/deployer/local/edp ./script/deployer/local/data 