pragma solidity ^0.8.9;

import "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
    constructor() ERC20("TestToken", "TT", 18) {
        _mint(msg.sender, 10000000000000000000000000000);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
