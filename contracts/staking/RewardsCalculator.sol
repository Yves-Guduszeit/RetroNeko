// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRewardsCalculator.sol";

contract RewardsCalculator is Initializable, OwnableUpgradeable, UUPSUpgradeable, IRewardsCalculator {
    uint256 private _silverDailyRewardsRatePerTenThousand;
    uint256 private _goldDailyRewardsRatePerTenThousand;
    uint256 private _diamondDailyRewardsRatePerTenThousand;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        _silverDailyRewardsRatePerTenThousand = 30;
        _goldDailyRewardsRatePerTenThousand = 40;
        _diamondDailyRewardsRatePerTenThousand = 50;
    }

    function updateRewardsRates(
        uint256 silverDailyRewardsRatePerTenThousand_,
        uint256 goldDailyRewardsRatePerTenThousand_,
        uint256 diamondDailyRewardsRatePerTenThousand_) external onlyOwner {
        require(silverDailyRewardsRatePerTenThousand_ > 0, "RewardsCalculator: Silver rewards rate should be > 0");
        require(goldDailyRewardsRatePerTenThousand_ > 0, "RewardsCalculator: Gold rewards rate should be > 0");
        require(diamondDailyRewardsRatePerTenThousand_ > 0, "RewardsCalculator: Diamond rewards rate should be > 0");

        _silverDailyRewardsRatePerTenThousand = silverDailyRewardsRatePerTenThousand_;
        _goldDailyRewardsRatePerTenThousand = goldDailyRewardsRatePerTenThousand_;
        _diamondDailyRewardsRatePerTenThousand = diamondDailyRewardsRatePerTenThousand_;
    }

    function updateSilverRewardsRate(uint256 dailyRatePerTenThousand) external onlyOwner {
        require(dailyRatePerTenThousand > 0, "RewardsCalculator: Silver rewards rate should be > 0");

        _silverDailyRewardsRatePerTenThousand = dailyRatePerTenThousand;
    }

    function updateGoldRewardsRate(uint256 dailyRatePerTenThousand) external onlyOwner {
        require(dailyRatePerTenThousand > 0, "RewardsCalculator: Gold rewards rate should be > 0");

        _goldDailyRewardsRatePerTenThousand = dailyRatePerTenThousand;
    }

    function updateDiamondRewardsRate(uint256 dailyRatePerTenThousand) external onlyOwner {
        require(dailyRatePerTenThousand > 0, "RewardsCalculator: Diamond rewards rate should be > 0");

        _diamondDailyRewardsRatePerTenThousand = dailyRatePerTenThousand;
    }

    function computeSilverRewards(address stakeholder, uint256 amount, uint256 since) external view override returns (uint256) {
        return _computeRewards(amount, since, _silverDailyRewardsRatePerTenThousand);
    }

    function computeGoldRewards(address stakeholder, uint256 amount, uint256 since) external view override returns (uint256) {
        return _computeRewards(amount, since, _goldDailyRewardsRatePerTenThousand);
    }

    function computeDiamondRewards(address stakeholder, uint256 amount, uint256 since) external view override returns (uint256) {
        return _computeRewards(amount, since, _diamondDailyRewardsRatePerTenThousand);
    }

    function silverDailyRewardsRatePerTenThousand() external view returns (uint256) {
        return _silverDailyRewardsRatePerTenThousand;
    }

    function goldDailyRewardsRatePerTenThousand() external view returns (uint256) {
        return _goldDailyRewardsRatePerTenThousand;
    }

    function diamondDailyRewardsRatePerTenThousand() external view returns (uint256) {
        return _diamondDailyRewardsRatePerTenThousand;
    }

    function _computeRewards(uint256 amount, uint256 since, uint256 dailyRatePerTenThousand) private view returns (uint256) {
        return (amount * (block.timestamp - since) / 1 days) * dailyRatePerTenThousand / 10_000;
    }
    
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }
}
