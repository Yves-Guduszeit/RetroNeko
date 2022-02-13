// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRewardsCalculator {
    function computeSilverRewards(address stakeholder, uint256 amount, uint256 since) external view returns (uint256);
    function computeGoldRewards(address stakeholder, uint256 amount, uint256 since) external view returns (uint256);
    function computeDiamondRewards(address stakeholder, uint256 amount, uint256 since) external view returns (uint256);
}
