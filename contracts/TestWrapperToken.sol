import "./Flame.sol";

contract TestWrappedAvailableToken {
    FlameToken public immutable flameToken;
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    constructor(FlameToken _flame,string memory _name,string memory _symbol) {
        flameToken = _flame;
        name = _name;
        symbol = _symbol;
        decimals = _flame.decimals();
    }
    function balanceOf(address account) public view returns (uint256) {
        return flameToken.availableOf(account);
    }
}