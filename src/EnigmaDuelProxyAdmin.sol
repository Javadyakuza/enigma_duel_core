// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";

contract EnigmaDuelProxyAdmin is ProxyAdmin {
    constructor() ProxyAdmin(_msgSender()) {}
}
