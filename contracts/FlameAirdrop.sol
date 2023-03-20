// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Flame.sol";

contract FlameAirdrop is Ownable, Pausable {
    FlameToken public immutable flameToken;
    mapping(address => AirdropInfo) private airMap;

    struct AirdropInfo {
        uint256 airdropAmount;
        uint256 claimedAmount;
    }

    constructor(FlameToken _token) {
        flameToken = _token;
    }

    function claim() public whenNotPaused {
        _claim(_msgSender());
    }

    function addAirdrop(address account,uint256 amount) public onlyOwner {
        _setAirdrop(account,airMap[account].airdropAmount+amount);
    }

    function setAirdrop(address account,uint256 amount) public onlyOwner {
        _setAirdrop(account,amount);
    }

    function getAirdropInfo(address account) public view returns (AirdropInfo memory) {
        return airMap[account];
    }

    function _setAirdrop(address account, uint256 amount) internal {
        require(amount>airMap[account].claimedAmount, "invalid amount");
        airMap[account].airdropAmount = amount;
        emit AirdropInfoChanged(account, amount);
    }

    function _claim(address account) internal {
        uint256 amount = airMap[account].airdropAmount - airMap[account].claimedAmount;
        airMap[account].claimedAmount = airMap[account].airdropAmount;
        flameToken.transfer(account, amount);
        emit AirdropClaimed(account,amount);
    }

    event AirdropInfoChanged(address account, uint256 total);
    event AirdropClaimed(address account, uint256 amount);
}
