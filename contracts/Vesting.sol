// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";


/**
 * @dev Time-locks tokens according to an unlock schedule.
 */

contract Vesting is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public token;

    struct VestingParams {
        uint256 unlockBegin;
        uint256 unlockEnd;
        uint256 lockedAmounts;
        uint256 claimedAmounts;
    }

    address public vault;
    mapping(address => VestingParams) public vesting;
    uint256 public constant VESTING_DURATION = 86400 * 21; // 21 days of vesting

    event Setup(
        address indexed recipient,
        uint256 _amount,
        uint256 _unlockBegin,
        uint256 _unlockEnd
    );
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @param _token The token this contract will lock
     */
    function initialize(address _token) public initializer {
        token = IERC20Upgradeable(_token);
        __Ownable_init();
    }

    /**
     * @dev set xCTDL vault
     * @param _vault address of xCTDL vault contract
     */
    function setVault(address _vault) external onlyOwner {
        require(vault != address(0), "xCTDL Vault: Null address");
        vault = _vault;
    }

    /**
     * @dev setup vesting for recipient.
     * @param recipient The account for which vesting will be setup.
     * @param _amount amount that will be vested
     * @param _unlockBegin The time at which unlocking of tokens will begin.
     */
    function setupVesting(
        address recipient,
        uint256 _amount,
        uint256 _unlockBegin
    ) external {
        require(msg.sender == vault, "only xCTDL vault");
        require(_amount > 0);

        vesting[recipient].lockedAmounts = vesting[recipient].lockedAmounts.add(
            _amount
        );
        vesting[recipient].unlockBegin = _unlockBegin;
        vesting[recipient].unlockEnd = _unlockBegin.add(VESTING_DURATION);

        emit Setup(
            recipient,
            vesting[recipient].lockedAmounts,
            _unlockBegin,
            vesting[recipient].unlockEnd
        );
    }

    /**
     * @dev Returns the maximum number of tokens currently claimable by `owner`.
     * @param owner The account to check the claimable balance of.
     * @return The number of tokens currently claimable.
     */
    function claimableBalance(address owner)
        public
        view
        returns (uint256)
    {
        uint256 locked = vesting[owner].lockedAmounts;
        uint256 claimed = vesting[owner].claimedAmounts;
        if (block.timestamp >= vesting[owner].unlockEnd) {
            return locked.sub(claimed);
        }
        return
            (
                (locked.mul(block.timestamp.sub(vesting[owner].unlockBegin)))
                    .div(vesting[owner].unlockEnd - vesting[owner].unlockBegin)
            ).sub(claimed);
    }

    /**
     * @dev Claims the caller's tokens that have been unlocked, sending them to `recipient`.
     * @param recipient The account to transfer unlocked tokens to.
     * @param amount The amount to transfer. If greater than the claimable amount, the maximum is transferred.
     */
    function claim(address recipient, uint256 amount) external {
        uint256 claimable = claimableBalance(msg.sender);
        if (amount > claimable) {
            amount = claimable;
        }
        if (amount != 0) {
            vesting[msg.sender].claimedAmounts = vesting[msg.sender]
                .claimedAmounts
                .add(amount);
            token.safeTransfer(recipient, amount);
            emit Claimed(msg.sender, recipient, amount);
        }
    }
}