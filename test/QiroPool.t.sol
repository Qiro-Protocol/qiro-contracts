// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/QiroPool.sol";
import "../src/TestToken.sol";

contract QiroPoolTest is Test {
    QiroPool public qiroPool;
    TestToken public testToken;

    function setUp() public {
        qiroPool = new QiroPool(testToken);
    }
}
