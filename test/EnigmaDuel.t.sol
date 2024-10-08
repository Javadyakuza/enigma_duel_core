// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/EnigmaDuel.sol";
import "../src/libs/Structures.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/EnigmaDuelToken.sol";
import {EnigmaDuelState} from "../src/EnigmaDuelState.sol";
import "../src/interfaces/IEnigmaDuelState.sol";
import "forge-std/console.sol";
import "../src/EnigmaDuelProxy.sol";
import "../src/EnigmaDuelProxyAdmin.sol";
import "forge-std/console.sol";
import "../src/utils/Utils.sol";
contract EnigmaDuelTest is Test {
    EnigmaDuel enigmaDuel;
    EnigmaDuelState enigmaState;
    EDT _EDT;
    EnigmaDuelProxyAdmin proxyAdmin;
    EnigmaDuelProxy proxy;
    address admin;
    address user1;
    address user2;
    address winner;
    address loser;

    uint256 initialSupply = 1000 * 10 ** 18;
    uint256 fee = 1000000000000000000;
    uint256 drawFee = 0;

    function setUp() public {
        admin = address(1);
        user1 = address(2);
        user2 = address(3);
        winner = address(4);
        loser = address(5);

        vm.startPrank(admin);

        // Deploy ERC20 token and mint initial supply to admin
        _EDT = new EDT(0);
        _EDT.mint(admin, initialSupply);

        enigmaState = new EnigmaDuelState();

        // Deploy EnigmaDuel contract
        enigmaDuel = new EnigmaDuel();
        // enigmaState.initialize(admin);
        
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,uint256,uint256)",
            address(enigmaState),
            address(_EDT),
            fee,
            drawFee
        );  

        emit log_bytes(data);
        

        proxyAdmin = new EnigmaDuelProxyAdmin();
        emit log_address(address(enigmaDuel));
        emit log_address(address(enigmaState));
        emit log_address(address(_EDT));
        emit log_address(address(proxyAdmin));
        bytes32 game_hash = EnigmaUtils.gen_game_room_key(0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC); 
        emit log_bytes32(game_hash);
        emit log_bytes(abi.encode(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));

        proxy = new EnigmaDuelProxy(address(enigmaDuel), address(proxyAdmin), data);
        enigmaDuel = EnigmaDuel(address(proxy));
        enigmaState.initialize(address(proxy));
        // Distribute tokens to users
        _EDT.transfer(user1, 100 * 10 ** 18);
        _EDT.transfer(user2, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testDepositEDT() public {
        uint256 depositAmount = 50 * 10 ** 18;

        // Approve and deposit EDT tokens
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        uint256 newBalance = enigmaDuel.depositEDT(depositAmount);

        assertEq(newBalance, depositAmount);
        assertEq(_EDT.balanceOf(user1), 50 * 10 ** 18);
        vm.stopPrank();
    }

    function testWithdrawEDT() public {
        uint256 depositAmount = 50 * 10 ** 18;
        uint256 withdrawAmount = 20 * 10 ** 18;

        // Approve and deposit EDT tokens
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);

        // Withdraw EDT tokens
        uint256 newBalance = enigmaDuel.withdrawEDT(withdrawAmount);

        assertEq(newBalance, 30 * 10 ** 18);
        assertEq(_EDT.balanceOf(user1), 70 * 10 ** 18);
        vm.stopPrank();
    }

    function testStartGameRoom() public {
        uint256 depositAmount = 20 * 10 ** 18;
        uint256 prizePool = 40 * 10 ** 18;

        // Approve and deposit EDT tokens for both users
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        // Start game room
        IEnigmaDuelState.GameRoom memory gameRoomParams = IEnigmaDuelState
            .GameRoom({
                duelist1: user1,
                duelist2: user2,
                prizePool: prizePool,
                status: IEnigmaDuelState.GameRoomStatus.Active
            });

        vm.prank(admin);
        bytes32 gameRoomKey = enigmaDuel.startGameRoom(gameRoomParams);

        IEnigmaDuelState.GameRoom memory gameRoom = enigmaDuel.getGameRoom(
            gameRoomKey
        );
        assertEq(gameRoom.duelist1, user1);
        assertEq(gameRoom.duelist2, user2);
        assertEq(gameRoom.prizePool, prizePool);
        assertEq(
            uint8(gameRoom.status),
            uint8(IEnigmaDuelState.GameRoomStatus.Active)
        );
    }

    function testFinishGameRoomVictory() public {
        uint256 depositAmount = 20 * 10 ** 18;
        uint256 prizePool = 40 * 10 ** 18;

        // Approve and deposit EDT tokens for both users
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        // Start game room
        IEnigmaDuelState.GameRoom memory gameRoomParams = IEnigmaDuelState
            .GameRoom({
                duelist1: user1,
                duelist2: user2,
                prizePool: prizePool,
                status: IEnigmaDuelState.GameRoomStatus.Active
            });

        vm.prank(admin);
        bytes32 gameRoomKey = enigmaDuel.startGameRoom(gameRoomParams);

        // Finish game room with a victory
        vm.prank(admin);
        Structures.GameRoomResult memory gameRoomResult = enigmaDuel
            .finishGameRoom(gameRoomKey, user1);

        assertEq(
            uint8(gameRoomResult.status),
            uint8(IEnigmaDuelState.GameRoomResultStatus.Victory)
        );
        assertEq(gameRoomResult.duelist1, user1);
        assertEq(gameRoomResult.duelist2, user2);
        assertEq(gameRoomResult.fee, fee);
    }

    function testFinishGameRoomDraw() public {
        uint256 depositAmount = 20 * 10 ** 18;
        uint256 prizePool = 40 * 10 ** 18;

        // Approve and deposit EDT tokens for both users
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        // Start game room
        IEnigmaDuelState.GameRoom memory gameRoomParams = IEnigmaDuelState
            .GameRoom({
                duelist1: user1,
                duelist2: user2,
                prizePool: prizePool,
                status: IEnigmaDuelState.GameRoomStatus.Active
            });

        vm.prank(admin);
        bytes32 gameRoomKey = enigmaDuel.startGameRoom(gameRoomParams);

        // Finish game room with a draw
        vm.prank(admin);
        Structures.GameRoomResult memory gameRoomResult = enigmaDuel
            .finishGameRoom(gameRoomKey, address(0));

        assertEq(
            uint8(gameRoomResult.status),
            uint8(IEnigmaDuelState.GameRoomResultStatus.Draw)
        );
        assertEq(gameRoomResult.duelist1, user1);
        assertEq(gameRoomResult.duelist2, user2);
        assertEq(gameRoomResult.fee, drawFee);
    }

    function testWithdrawCollectedFees() public {
        uint256 depositAmount = 20 * 10 ** 18;
        uint256 prizePool = 40 * 10 ** 18;

        // Approve and deposit EDT tokens for both users
        vm.startPrank(user1);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        _EDT.approve(address(enigmaDuel), depositAmount);
        enigmaDuel.depositEDT(depositAmount);
        vm.stopPrank();

        // Start game room
        IEnigmaDuelState.GameRoom memory gameRoomParams = IEnigmaDuelState
            .GameRoom({
                duelist1: user1,
                duelist2: user2,
                prizePool: prizePool,
                status: IEnigmaDuelState.GameRoomStatus.Active
            });

        vm.startPrank(admin);
        bytes32 gameRoomKey = enigmaDuel.startGameRoom(gameRoomParams);

        // Finish game room with a victory
        enigmaDuel.finishGameRoom(gameRoomKey, user1);

        // Withdraw collected fees
        enigmaDuel.withdrawCollectedFees(fee, admin); // actually one games fee is collected

        assertEq(
            _EDT.balanceOf(admin),
            initialSupply - ((100 * 10 ** 18) * 2) + fee
        );
        vm.stopPrank();
    }
}
