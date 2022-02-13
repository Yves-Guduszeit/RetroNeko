// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IRewardsCalculator.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Stake {
        address holder;
        uint256 amount;
        uint256 since;
        uint256 claimableAmount;
    }
    
    struct Stakeholder {
        address holder;
        Stake[9] stakes;
    }
    
    struct StakingSummary {
        uint256 totalStakedAmount;
        Stake[9] stakes;
    }

    enum StakeLevel {
        SILVER,
        GOLD,
        DIAMOND
    }
    
    ERC20 private _token;
    IRewardsCalculator private _rewardsCalculator;

    uint256 private _packAmount;
    uint256 private _totalStakedAmount;
    uint256 private _totalClaimedAmount;

    uint256 private _silverLockPeriod;
    uint256 private _goldLockPeriod;
    uint256 private _diamondLockPeriod;
     
    Stakeholder[] private _stakeholders;
    mapping(address => uint256) private _stakeholderIndexes;
    
    event Staked(address indexed holder, uint256 stakeholderIndex, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed holder, uint256 stakeholderIndex, uint256 amount, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address token_, address rewardsCalculator_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        _token = ERC20(token_);
        _rewardsCalculator = IRewardsCalculator(rewardsCalculator_);

        _packAmount = 10_000_000 * 10 ** _token.decimals();

        _silverLockPeriod = 90 days;
        _goldLockPeriod = 180 days;
        _diamondLockPeriod = 270 days;

        _stakeholders.push();
    }

    function token() external view returns (address) {
        return address(_token);
    }

    function rewardsCalculator() external view returns (address) {
        return address(_rewardsCalculator);
    }

    function packAmount() external view returns (uint256) {
        return _packAmount / (10 ** _token.decimals());
    }

    function totalStakedAmount() external view returns (uint256) {
        return _totalStakedAmount / (10 ** _token.decimals());
    }

    function totalClaimableAmount() external view returns (uint256) {
        uint256 claimableAmount = 0;
        for (uint8 stakeholderIndex = 1; stakeholderIndex < _stakeholders.length; stakeholderIndex++) {
            Stake[9] memory stakes = _stakeholders[stakeholderIndex].stakes;
            for (uint8 stakeIndex = 0; stakeIndex < stakes.length; stakeIndex++) {
                uint256 availableRewards = _computeRewards(stakeIndex, stakes[stakeIndex]);
                claimableAmount = availableRewards;
            }
        }

        return claimableAmount / (10 ** _token.decimals());
    }

    function totalClaimedAmount() external view returns (uint256) {
        return _totalClaimedAmount / (10 ** _token.decimals());
    }

    function silverLockPeriod() external view returns (uint256) {
        return _silverLockPeriod;
    }

    function goldLockPeriod() external view returns (uint256) {
        return _goldLockPeriod;
    }

    function diamondLockPeriod() external view returns (uint256) {
        return _diamondLockPeriod;
    }
    
    function stakeSummary(address stakeholder) external view returns (StakingSummary memory) {
        return _stakeSummary(stakeholder);
    }

    function stakeholderAtIndex(uint256 stakeholderIndex) external view returns (address) {
        return _stakeholders[stakeholderIndex].holder;
    }

    function updateSilverLockPeriod(uint256 lockPeriod) external onlyOwner {
        _silverLockPeriod = lockPeriod;
    }

    function updateGoldLockPeriod(uint256 lockPeriod) external onlyOwner {
        _goldLockPeriod = lockPeriod;
    }

    function updateDiamondLockPeriod(uint256 lockPeriod) external onlyOwner {
        _diamondLockPeriod = lockPeriod;
    }

    function updatePackAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Staking: Should not stake for free");

        _packAmount = amount * 10 ** _token.decimals();
    }

    function updateRewardsCalculator(address rewardsCalculator_) external onlyOwner {
        _rewardsCalculator = IRewardsCalculator(rewardsCalculator_);
    }
    
    function stakeSilver(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Silver has only 3 slots");

        _stakePack(stakeIndex);
    }
    
    function stakeGold(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Gold has only 3 slots");

        _stakePack(3 + stakeIndex);
    }
    
    function stakeDiamond(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Diamond has only 3 slots");

        _stakePack(6 + stakeIndex);
    }
    
    function withdrawSilver(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Silver has only 3 slots");

        _withdrawPack(stakeIndex, _silverLockPeriod);
    }
    
    function withdrawGold(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Gold has only 3 slots");

        _withdrawPack(3 + stakeIndex, _goldLockPeriod);
    }
    
    function withdrawDiamond(uint8 stakeIndex) external {
        require(stakeIndex < 3, "Staking: Diamond has only 3 slots");

        _withdrawPack(6 + stakeIndex, _diamondLockPeriod);
    }
    
    function _stakePack(uint8 stakeIndex) private {
        require(stakeIndex < 9, "Staking: There is only 9 slots (3 of each)");
        Stake memory stake = _stakeholders[_stakeholderIndexes[msg.sender]].stakes[stakeIndex];
        require(stake.amount == 0, "Staking: Slot is already used");
        require(_packAmount <= _token.balanceOf(msg.sender), "Staking: Cannot stake more than you own");

        _stake(stakeIndex, _packAmount);
        _token.transferFrom(msg.sender, address(this), _packAmount);
        _totalStakedAmount += _packAmount;
    }
    
    function _stake(uint8 stakeIndex, uint256 amount) private {
        uint256 stakeholderIndex = _stakeholderIndexes[msg.sender];
        
        if (stakeholderIndex == 0) {
            stakeholderIndex = _addStakeholder(msg.sender);
        }
        
        uint256 timestamp = block.timestamp;
        _stakeholders[stakeholderIndex].stakes[stakeIndex] = Stake(msg.sender, amount, timestamp, 0);
        
        emit Staked(msg.sender, stakeholderIndex, amount, timestamp);
    }
    
    function _withdrawPack(uint8 stakeIndex, uint256 lockPeriod) private {
        require(stakeIndex < 9, "Staking: There is only 9 slots (3 of each)");
        Stake memory stake = _stakeholders[_stakeholderIndexes[msg.sender]].stakes[stakeIndex];
        require(stake.amount > 0, "Staking: Slot is empty");

        uint256 amountWithRewards = _withdraw(stakeIndex, stake.amount, lockPeriod);
        require(amountWithRewards <= _token.balanceOf(address(this)), "Staking: Staking contract does not own enough token");

        _token.transfer(msg.sender, amountWithRewards);

        _totalStakedAmount -= stake.amount;
    }
    
    function _withdraw(uint8 stakeIndex, uint256 amount, uint256 lockPeriod) private returns (uint256) {
        uint256 stakeholderIndex = _stakeholderIndexes[msg.sender];
        Stake memory currentStake = _stakeholders[stakeholderIndex].stakes[stakeIndex];
        require(currentStake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

        uint256 rewards = block.timestamp >= currentStake.since + lockPeriod
            ? _computeRewards(stakeIndex, currentStake)
            : 0;
        currentStake.amount -= amount;
        
        if (currentStake.amount > 0) {
            _stakeholders[stakeholderIndex].stakes[stakeIndex].amount = currentStake.amount;
            _stakeholders[stakeholderIndex].stakes[stakeIndex].since = block.timestamp;
        } else {
            _totalClaimedAmount = _stakeholders[stakeholderIndex].stakes[stakeIndex].claimableAmount;
            _stakeholders[stakeholderIndex].stakes[stakeIndex].amount = 0;
            _stakeholders[stakeholderIndex].stakes[stakeIndex].since = 0;
            _stakeholders[stakeholderIndex].stakes[stakeIndex].claimableAmount = 0;
        }

        emit Withdrawn(msg.sender, stakeholderIndex, amount, block.timestamp);

        return amount + rewards;
    }
    
    function _addStakeholder(address stakeholder) private returns (uint256) {
        _stakeholders.push();
        
        uint256 holderIndex = _stakeholders.length - 1;
        _stakeholders[holderIndex].holder = stakeholder;
        _stakeholderIndexes[stakeholder] = holderIndex;

        return holderIndex;
    }

    function _stakeSummary(address stakeholder) private view returns (StakingSummary memory) {
        uint256 stakedAmount = 0;
        uint256 stakeholderIndex = _stakeholderIndexes[stakeholder];
        Stake[9] memory stakes = _stakeholders[stakeholderIndex].stakes;
        
        for (uint8 stakeIndex = 0; stakeIndex < stakes.length; stakeIndex++) {
            uint256 availableRewards = _computeRewards(stakeIndex, stakes[stakeIndex]);
            stakes[stakeIndex].claimableAmount = availableRewards;
            stakedAmount += stakes[stakeIndex].amount;
        }
        
        return StakingSummary(stakedAmount, stakes);
    }

    function _computeRewards(uint8 stakeIndex, Stake memory stake_) private view returns (uint256) {
        StakeLevel stakeLevel = _getStakeLevel(stakeIndex);
        uint256 rewards;

        if (stakeLevel == StakeLevel.DIAMOND) {
            rewards = _rewardsCalculator.computeDiamondRewards(stake_.holder, stake_.amount, stake_.since);
        } else if (stakeLevel == StakeLevel.GOLD) {
            rewards = _rewardsCalculator.computeGoldRewards(stake_.holder, stake_.amount, stake_.since);
        } else {
            rewards = _rewardsCalculator.computeSilverRewards(stake_.holder, stake_.amount, stake_.since);
        }

        return rewards;
    }

    function _getStakeLevel(uint8 stakeIndex) private pure returns (StakeLevel) {
        StakeLevel stakeLevel;

        if (stakeIndex >= 6 && stakeIndex <= 8) {
            stakeLevel = StakeLevel.DIAMOND;
        } else if (stakeIndex >= 3 && stakeIndex <= 5) {
            stakeLevel = StakeLevel.GOLD;
        } else {
            stakeLevel = StakeLevel.SILVER;
        }
        
        return stakeLevel;
    }
    
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }
}
