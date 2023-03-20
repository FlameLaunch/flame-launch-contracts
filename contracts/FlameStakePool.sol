// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FlameStake is Ownable, Pausable, ReentrancyGuard {
    uint256 public immutable STAKE_LOCK_TIME;
    // uint256 public constant MAX_AMOUNT = 5000;
    uint256 public immutable STAKE_AMOUNT_PER_SHARE;
    mapping(address => StakeInfo) private stakeMap;

    struct StakeInfo {
        uint256 stakeAt;
        uint256 stakeAmount;
    }

    constructor() { 
        STAKE_LOCK_TIME = 15 days;
        STAKE_AMOUNT_PER_SHARE = 30 * (10 ** 18);
    }

    function stake() public payable whenNotPaused nonReentrant {
        address operator = _msgSender();
        uint256 filAmount = msg.value;
        require(stakeMap[operator].stakeAt == 0, "you have mint already");
        require(filAmount==STAKE_AMOUNT_PER_SHARE,"invalid fil value");

        stakeMap[operator].stakeAmount += STAKE_AMOUNT_PER_SHARE;
        stakeMap[operator].stakeAt = block.timestamp;
        emit Staking(operator, STAKE_AMOUNT_PER_SHARE);
    }

    function unstake() public whenNotPaused nonReentrant  {
        address operator = _msgSender();
        uint256 filAmount = stakeMap[operator].stakeAmount;
        require(filAmount > 0, "no stake value");
        require(
            stakeMap[operator].stakeAt + STAKE_LOCK_TIME < block.timestamp,
            "still in lock"
        );
        stakeMap[operator].stakeAmount = 0;
        if (filAmount > 0) {
            (bool success, ) = operator.call{value: filAmount}("");
            require(success, "Transfer: transfer fil failed");
        }
        emit Unstaking(operator, filAmount);
    }

    function setPause(bool p) public onlyOwner {
        if (p) _pause();
        else _unpause();
    }

    function stakeInfoOf(
        address account
    ) public view returns (StakeInfo memory) {
        return stakeMap[account];
    }

    event Staking(address operator, uint256 stakeAmount);
    event Unstaking(address operator, uint256 amount);
}
