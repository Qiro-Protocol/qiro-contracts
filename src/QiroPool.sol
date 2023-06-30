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

    uint256 public totalDeposit;

    uint256 public totalInterestCollected;

    uint256 public lpPool;

    uint256 public feePool;

    uint256 public interest;

    struct BorrowDetails {
        address user;
        uint256 borrowId;
        uint256 borrowAmount;
        uint256 repaidAmount;
        uint256 interestPaid;
        uint256 borrowTime;
        uint256 timePeriod;
        string ipfsHash;
    }

    mapping(uint256 => BorrowDetails) public borrowDetails;

    mapping(address => uint[]) public borrowIds;

    mapping(address => BorrowDetails[]) public userBorrowDetails;

    event Borrowed(
        address user,
        uint amount,
        string ipfsHash,
        uint borrowingId
    );

    event Repaid(
        address user,
        uint borrowingId,
        uint repayAmount,
        uint interest,
        uint remainingAmount
    );

    constructor(
        ERC20 _asset,
        uint _interest
    ) ERC4626(_asset, "Qiro Pool", "QP") {
        interest = _interest;
    }

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
            _borrowingId.current(),
            amount,
            0,
            0,
            block.timestamp,
            timePeriod,
            ipfsHash
        );
        borrowDetails[_borrowingId.current()] = _borrowDetails;
        lpPool -= amount;
        borrowIds[msg.sender].push(_borrowingId.current());
        userBorrowDetails[msg.sender].push(_borrowDetails);

        asset.safeTransfer(msg.sender, amount);

        emit Borrowed(msg.sender, amount, ipfsHash, _borrowingId.current());
    }

    function repay(uint256 borrowingId, uint256 _time) external {
        require(_time <= 12);
        BorrowDetails memory _borrowDetails = borrowDetails[borrowingId];

        require(_borrowDetails.repaidAmount <= _borrowDetails.borrowAmount);
        uint _amount = FixedPointMathLib.mulDivUp(
            _borrowDetails.borrowAmount,
            _time,
            12
        );
        uint256 _interest = ((interest / 12) *
            _time *
            _borrowDetails.borrowAmount) / _FLOAT_HANDLER_TEN_4;
        lpPool += _amount;
        feePool += _interest;
        totalInterestCollected += _interest;
        borrowDetails[borrowingId].repaidAmount += _amount;
        borrowDetails[borrowingId].interestPaid += _interest;

        for (uint i; i < userBorrowDetails[msg.sender].length; ) {
            if (userBorrowDetails[msg.sender][i].borrowId == borrowingId) {
                if (userBorrowDetails[msg.sender].length > 1) {
                    for (
                        uint j = i;
                        j < userBorrowDetails[msg.sender].length - 1;

                    ) {
                        userBorrowDetails[msg.sender][j] = userBorrowDetails[
                            msg.sender
                        ][j + 1];

                        unchecked {
                            ++j;
                        }
                    }
                    userBorrowDetails[msg.sender][i].repaidAmount += _amount;
                    userBorrowDetails[msg.sender][i].interestPaid += _interest;
                } else {
                    userBorrowDetails[msg.sender][i].repaidAmount += _amount;
                    userBorrowDetails[msg.sender][i].interestPaid += _interest;
                }
            }
            unchecked {
                ++i;
            }
        }

        if (
            borrowDetails[borrowingId].repaidAmount >=
            _borrowDetails.borrowAmount
        ) {
            delete borrowDetails[borrowingId];
            for (uint i; i < borrowIds[msg.sender].length; ) {
                if (borrowIds[msg.sender][i] == borrowingId) {
                    if (borrowIds[msg.sender].length > 1) {
                        for (
                            uint j = i;
                            j < borrowIds[msg.sender].length - 1;

                        ) {
                            borrowIds[msg.sender][j] = borrowIds[msg.sender][
                                j + 1
                            ];
                            userBorrowDetails[msg.sender][
                                j
                            ] = userBorrowDetails[msg.sender][j + 1];
                            unchecked {
                                ++j;
                            }
                        }
                        borrowIds[msg.sender].pop();
                        userBorrowDetails[msg.sender].pop();
                    } else {
                        borrowIds[msg.sender].pop();
                        userBorrowDetails[msg.sender].pop();
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }

        asset.safeTransferFrom(msg.sender, address(this), _amount + _interest);

        emit Repaid(
            msg.sender,
            borrowingId,
            _amount,
            _interest,
            _borrowDetails.borrowAmount - _borrowDetails.repaidAmount
        );
    }

    function setInterest(uint256 _interest) external onlyOwner {
        interest = _interest;
    }

    function afterDeposit(uint256 assets, uint256) internal virtual override {
        lpPool += assets;
        totalDeposit += assets;
    }

    function userBorrowIds(address user) external view returns (uint[] memory) {
        return borrowIds[user];
    }

    function getUserBorrowDetails(
        address _user
    ) external view returns (BorrowDetails[] memory) {
        return userBorrowDetails[_user];
    }

    function beforeWithdraw(uint256 assets, uint256) internal virtual override {
        uint256 _interest = (((_FLOAT_HANDLER_TEN_4 * assets) / lpPool) *
            feePool) / _FLOAT_HANDLER_TEN_4;
        asset.safeTransfer(msg.sender, _interest);
        lpPool -= assets;
        feePool -= _interest;
    }

    /// @notice function responsible to rescue funds if any
    /// @param  tokenAddr address of token
    function rescueFunds(ERC20 tokenAddr) external onlyOwner {
        uint256 balance = tokenAddr.balanceOf(address(this));
        tokenAddr.safeTransfer(msg.sender, balance);
    }
}
