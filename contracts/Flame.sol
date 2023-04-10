// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlameToken is ERC20, Ownable {
    using Math for uint256;
    uint8 public constant ReleaseLinearIn1YearAfter1Year = 0;
    uint8 public constant ReleaseLinearIn1YearAfter2Year = 1;
    uint8 public constant Release334For2Month = 2; // [0.3,0.3,0.4]
    uint8 public constant Release1For10Month = 3; // [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1]
    uint8 public constant ReleaseAllAfter1Year = 4;
    uint256 public UPLINE_AT;
    uint256 private _totalLock = 0;
    struct Locker {
        uint256 lock;
        uint256 claimed;
    }
    struct FlameLocker {
        bool lockTransferable;
        Locker[5] locks;
    }
    mapping(address => FlameLocker) private lockMap;

    constructor() ERC20("Flame Launch Token", "FLT") {
        UPLINE_AT = block.timestamp + 15 days;
        address tech = 0x5E75662eCcC9c3E3B18A0F357Fd381ef92ad5a02;
        address ecology = 0xBEFe05a040d2De72B7e05a9D16F19f13D2618169;
        address airdrop1 = 0xac2a152F5b48fB7A6810dD1DB711202d1774d2Be;
        address airdrop2 = 0x0c86FDDdf379d52c3a51E9043c9403e418F51CEE;
        address ido5 = 0x7174C2f0406568C8a80Bc73138519B632f00E52f;
        address ido2 = 0xa8c94AAA594834BE2Dab9716004a0D18775FdD20;
        address pe = 0xdC5f0a39ADbb8f5003BE2FF36697cB14eFb9d9F0;
        address fluidity = 0x47cdA56d5Cf829320e9FE849e84eC533bA93B929;
        address treasury = 0x2BDe6965ddC07eAFddb6cce0db9039aCE2848ac8;
        _lock(tech, ReleaseLinearIn1YearAfter2Year, 12e7 * 1e18);
        _lock(ecology, ReleaseLinearIn1YearAfter1Year, 30e7 * 1e18);
        _mint(airdrop1, 10e7 * 1e18);
        _mint(airdrop2, 10e7 * 1e18);
        _lock(ido2, Release334For2Month, 2e7 * 1e18);
        _lock(ido5, Release334For2Month, 5e7 * 1e18);
        _lock(pe, Release1For10Month, 3e7 * 1e18);
        _mint(fluidity, 8e7 * 1e18);
        _lock(treasury, ReleaseAllAfter1Year, 20e7 * 1e18);
    }

    function claim() public {
        _claimAll();
    }

    function transferLock(
        address from,
        address to,
        uint256[5] memory transform
    ) public {
        require(
            lockMap[from].lockTransferable,
            "from address can't tranfer lock"
        );
        address operator = _msgSender();
        if (from != operator) {
            uint256 spend = 0;
            for (uint256 i = 0; i < transform.length; i++) {
                spend += transform[i];
            }
            require(spend > 0, "spend zero allowance");
            _spendAllowance(from, operator, spend);
        }
        _safeTransferLock(from, to, transform);
    }

    function setLockTransferable(address account, bool a) public onlyOwner {
        _setLockTransferable(account, a);
    }

    function setUplineTime(uint256 at) public onlyOwner {
        _setUplineTime(at);
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        balance += lockOf(account);
        return balance;
    }

    function availableOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function lockOf(address account) public view returns (uint256 balance) {
        FlameLocker memory flamelock = lockMap[account];
        Locker memory locker = flamelock.locks[ReleaseLinearIn1YearAfter1Year];
        balance += locker.lock - locker.claimed;
        locker = flamelock.locks[ReleaseLinearIn1YearAfter2Year];
        balance += locker.lock - locker.claimed;
        locker = flamelock.locks[Release334For2Month];
        balance += locker.lock - locker.claimed;
        locker = flamelock.locks[Release1For10Month];
        balance += locker.lock - locker.claimed;
        locker = flamelock.locks[ReleaseAllAfter1Year];
        balance += locker.lock - locker.claimed;
    }

    function balanceDetailOf(
        address account,
        uint8 ltype
    ) public view returns (uint total, uint claimed, uint256 claimable) {
        FlameLocker memory flamelock = lockMap[account];
        Locker memory locker = flamelock.locks[ltype];
        total = locker.lock;
        claimed = locker.claimed;
        claimable = _claimableOf(ltype, locker);
    }

    function totalLock() public view returns (uint256) {
        return _totalLock;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() + _totalLock;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (super.balanceOf(from) < amount && !lockMap[from].lockTransferable)
            _claimAll();
        super._transfer(from, to, amount);
    }

    function _lock(address to, uint8 ltype, uint256 amount) internal {
        FlameLocker storage flamelock = lockMap[to];
        flamelock.locks[ltype].lock += amount;
        _totalLock += amount;
        _setLockTransferable(to, true);
        emit TransferLock(address(this), address(0), to, ltype, amount);
    }

    function _claimAll() internal {
        uint256 amount = 0;
        FlameLocker storage flamelock = lockMap[_msgSender()];
        amount += _claimingOf(ReleaseLinearIn1YearAfter1Year, flamelock);
        amount += _claimingOf(ReleaseLinearIn1YearAfter2Year, flamelock);
        amount += _claimingOf(Release334For2Month, flamelock);
        amount += _claimingOf(Release1For10Month, flamelock);
        amount += _claimingOf(ReleaseAllAfter1Year, flamelock);
        require(amount > 0, "no token can claim");
        _totalLock -= amount;
        _mint(_msgSender(), amount);
        //console.log('%f',amount);
    }

    function _claimingOf(
        uint8 ltype,
        FlameLocker storage flamelock
    ) internal returns (uint256) {
        Locker storage locker = flamelock.locks[ltype];
        (uint256 claimable, uint256 released) = _unclaimedOf(ltype, locker);
        if (claimable > 0) {
            locker.claimed = released;
        }
        return claimable;
    }

    function _unclaimedOf(
        uint8 ltype,
        Locker memory locker
    ) internal view returns (uint256 claimable, uint256 released) {
        if (locker.lock > locker.claimed) {
            if (ltype == ReleaseLinearIn1YearAfter1Year) {
                if (block.timestamp - UPLINE_AT >= 365 days) {
                    uint256 era = (block.timestamp - UPLINE_AT - 365 days) /
                        30 days;
                    uint256 rate = (era + 1).min(12);
                    released = (locker.lock * rate) / 12;
                    claimable = released - locker.claimed;
                    return (claimable, released);
                }
            } else if (ltype == ReleaseLinearIn1YearAfter2Year) {
                if (block.timestamp - UPLINE_AT >= 365 days * 2) {
                    uint256 era = (block.timestamp - UPLINE_AT - 365 days * 2) /
                        30 days;
                    uint256 rate = (era + 1).min(12);
                    released = (locker.lock * rate) / 12;
                    claimable = released - locker.claimed;
                    return (claimable, released);
                }
            } else if (ltype == Release334For2Month) {
                if (block.timestamp >= UPLINE_AT) {
                    uint256 era = (block.timestamp - UPLINE_AT) / (30 days);
                    uint8[3] memory map = [3, 6, 10];
                    uint256 rate = map[era.min(map.length - 1)];
                    released = (locker.lock * rate) / 10;
                    claimable = released - locker.claimed;
                    return (claimable, released);
                }
            } else if (ltype == Release1For10Month) {
                if (block.timestamp >= UPLINE_AT) {
                    uint256 era = (block.timestamp - UPLINE_AT) / (30 days);
                    uint256 rate = (era + 1).min(10);
                    released = (locker.lock * rate) / 10;
                    claimable = released - locker.claimed;
                    return (claimable, released);
                }
            } else if (ltype == ReleaseAllAfter1Year) {
                if (block.timestamp >= UPLINE_AT) {
                    released = locker.lock;
                    claimable = released - locker.claimed;
                    return (claimable, released);
                }
            }
        }
        return (0, 0);
    }

    function _claimableOf(
        uint8 ltype,
        Locker memory locker
    ) internal view returns (uint256 claimable) {
        (claimable, ) = _unclaimedOf(ltype, locker);
    }

    function _safeTransferLock(
        address from,
        address to,
        uint256[5] memory transform
    ) internal virtual {
        require(to != address(0), "transfer to the zero address");
        address operator = _msgSender();
        FlameLocker storage fromlock = lockMap[from];
        FlameLocker storage tolock = lockMap[to];
        for (uint8 i = 0; i < transform.length; i++) {
            if (transform[i] == 0) continue;
            require(
                transform[i] <= fromlock.locks[i].lock,
                "lock balance not enough"
            );
            if (transform[i] == fromlock.locks[i].lock) {
                require(
                    tolock.locks[i].claimed == 0 && tolock.locks[i].lock == 0,
                    "to address can't accept lock ownership"
                );
                tolock.locks[i].lock = fromlock.locks[i].lock;
                tolock.locks[i].claimed = fromlock.locks[i].claimed;
                fromlock.locks[i].lock = 0;
                fromlock.locks[i].claimed = 0;
            } else {
                require(
                    fromlock.locks[i].claimed == 0,
                    "from address can't transfer lock"
                );
                require(
                    tolock.locks[i].claimed == 0,
                    "to address can't transfer lock"
                );
                fromlock.locks[i].lock -= transform[i];
                tolock.locks[i].lock += transform[i];
            }
            emit TransferLock(operator, from, to, i, transform[i]);
        }
    }

    function _setLockTransferable(address account, bool a) internal {
        lockMap[account].lockTransferable = a;
        emit LockTransferableChanged(account, a);
    }

    function _setUplineTime(uint256 at) internal {
        require(
            at > block.timestamp && block.timestamp < UPLINE_AT,
            "invalid time"
        );
        UPLINE_AT = at;
        emit UplineTimeChanged(at);
    }

    event TransferLock(
        address operator,
        address from,
        address to,
        uint8 ltype,
        uint256 amount
    );

    event LockTransferableChanged(address account, bool can);

    event UplineTimeChanged(uint256 timestamp);
}
