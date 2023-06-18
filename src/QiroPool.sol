//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "solmate/mixins/ERC4626.sol";
import "solmate/utils/SafeTransferLib.sol";

contract QiroPool is ERC4626, Ownable {
    using SafeTransferLib for ERC20;
    using Counters for Counters.Counter;

    /// @notice Counter to keep track of supported Communication Layers
    Counters.Counter private _borrowingId;

    /// @notice Float handler to handle percent calculations
    uint256 constant _FLOAT_HANDLER_TEN_4 = 10000;

    uint256 public lpPool;

    uint256 public feePool;

    uint256 public interest;

    struct BorrowDetails {
        address user;
        uint256 amount;
        uint256 borrowTime;
        uint256 timePeriod;
        string ipfsHash;
    }

    mapping(uint256 => BorrowDetails) public borrowDetails;

    constructor(ERC20 _asset) ERC4626(_asset, "Qiro Pool", "QP") {}

    /// @notice This function returns totalAssets available in this pool
    function totalAssets() public view override returns (uint256) {
        return lpPool;
    }

    function borrow(
        uint256 amount,
        uint256 timePeriod,
        string calldata ipfsHash
    ) external {
        require(lpPool >= amount);
        _borrowingId.increment();
        BorrowDetails memory _borrowDetails = BorrowDetails(
            msg.sender,
            amount,
            block.timestamp,
            timePeriod,
            ipfsHash
        );
        borrowDetails[_borrowingId.current()] = _borrowDetails;
        lpPool -= amount;
        asset.safeTransfer(msg.sender, amount);
    }

    function setInterest(uint256 _interest) external onlyOwner {
        interest = _interest;
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        lpPool += assets;
    }

    /// @notice function responsible to rescue funds if any
    /// @param  tokenAddr address of token
    function rescueFunds(ERC20 tokenAddr) external onlyOwner {
        uint256 balance = tokenAddr.balanceOf(address(this));
        tokenAddr.safeTransfer(msg.sender, balance);
    }
}
