// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Flame.sol";

contract FlameIdo is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 public constant MAX_AMOUNT = 5000;
    uint256 public MINT_THRESHOLD = 5000 * 1e18;
    Counters.Counter private _tokenIdCounter;
    string private uri;

    FlameToken public immutable flameToken;
    address public immutable treasury;
    address public immutable idoTreasury;
    uint256 public pricePerShare;
    mapping(address => uint) private buyMap;

    constructor(
        FlameToken _token,
        address _trea,
        address _idotrea,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        flameToken = _token;
        treasury = _trea;
        idoTreasury = _idotrea;
        _setPrice(uint256(1e18) / 150, 5000 * 1e18);
        uri = _uri;
    }

    receive() external payable {
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "Transfer: transfer fil failed");
    }

    fallback() external payable {
        revert("Direct transfers not allowed.");
    }

    function buy(address to) public payable whenNotPaused nonReentrant {
        uint256 filAmount = msg.value;
        uint256 share = (filAmount * 1e18) / pricePerShare;
        flameToken.transferLock(idoTreasury, to, [0, 0, share, 0, 0]);
        buyMap[to] += share;
        emit IdoSale(to, pricePerShare, share);
    }

    function mint() public whenNotPaused nonReentrant {
        address operator = _msgSender();
        require(balanceOf(operator) == 0, "you have mint already");
        require(hadBought(operator) > MINT_THRESHOLD, "you can't mint");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_AMOUNT, "sbt mint over limit");
        _tokenIdCounter.increment();
        _safeMint(operator, tokenId);
    }

    function setPrice(uint256 price, uint256 threshold) public onlyOwner {
        _setPrice(price, threshold);
    }

    function setPause(bool p) public onlyOwner {
        if (p) _pause();
        else _unpause();
    }

    function hadBought(address account) public view returns (uint256) {
        return buyMap[account];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return uri;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        revert("SBT can't transfer");
    }

    function _setPrice(uint256 price, uint256 threshold) private {
        pricePerShare = price;
        MINT_THRESHOLD = threshold;
        emit PriceChanged(price, threshold);
    }

    event IdoSale(address to, uint256 price, uint256 share);
    event PriceChanged(uint256 price, uint256 threshold);
}
