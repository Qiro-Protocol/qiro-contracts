// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/QiroPool.sol";
import "../src/TestToken.sol";

contract QiroPoolTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address test1 = makeAddr("test1");
    address test2 = makeAddr("test2");

    QiroPool public qiroPool;
    TestToken public testToken;

    function setUp() public {
        testToken = new TestToken();
        qiroPool = new QiroPool(testToken, 1200);
        testToken.mint(test1, 1e18);
        testToken.mint(test2, 9e18);
    }

    function testDeposit() public {
        testToken.mint(alice, 10e18);
        vm.startPrank(alice);
        testToken.approve(address(qiroPool), 10e18);
        qiroPool.deposit(10e18, alice);
        assertEq(qiroPool.balanceOf(alice), 10e18);
        assertEq(qiroPool.lpPool(), 10e18);
        vm.stopPrank();
    }

    function testBorrow() public {
        testToken.mint(alice, 10e18);
        vm.startPrank(alice);
        testToken.approve(address(qiroPool), 10e18);
        qiroPool.deposit(10e18, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        assertEq(testToken.balanceOf(bob), 0);
        qiroPool.borrow(1e18, 12, "hash");
        assertEq(testToken.balanceOf(bob), 1e18);
        assertEq(qiroPool.lpPool(), (10e18 - 1e18));
        vm.stopPrank();
    }

    function testRepay() public {
        testToken.mint(alice, 10e18);
        vm.startPrank(alice);
        testToken.approve(address(qiroPool), 1000);
        qiroPool.deposit(1000, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        qiroPool.borrow(120, 12, "hash");
        testToken.approve(address(qiroPool), 120);
        qiroPool.repay(1, 1);
        assertEq(testToken.balanceOf(bob), 109);
        vm.stopPrank();
    }

    function testWithdraw() public {
        testToken.mint(alice, 1000);
        vm.startPrank(alice);
        testToken.approve(address(qiroPool), 1000);
        qiroPool.deposit(1000, alice);
        vm.stopPrank();
        vm.startPrank(test1);
        testToken.approve(address(qiroPool), 100);
        qiroPool.deposit(100, test1);
        vm.stopPrank();
        vm.startPrank(test2);
        testToken.approve(address(qiroPool), 900);
        qiroPool.deposit(900, test2);
        vm.stopPrank();
        vm.startPrank(bob);
        qiroPool.borrow(1200, 12, "hash");
        testToken.approve(address(qiroPool), 1200);
        qiroPool.repay(1, 1);
        assertEq(testToken.balanceOf(bob), 1088);
        vm.stopPrank();
        vm.startPrank(alice);
        qiroPool.withdraw(200, alice, alice);
        assertEq(testToken.balanceOf(alice), 202);
        vm.stopPrank();
    }
}
