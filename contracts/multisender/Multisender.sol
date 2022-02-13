// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Multisender is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function multisendToken(address token, address[] memory contributors, uint256[] memory balances) external {
        require(contributors.length >= 2, "Multisender: At least 2 contributors is required");
        require(contributors.length <= 65535, "Multisender: At most 65535 contributors is required");
        require(contributors.length == balances.length, "Multisender: Discrepancies between contributor and balance lengths");

        IERC20 erc20Token = IERC20(token);
        for (uint16 i = 0; i < contributors.length; i++) {
            erc20Token.transferFrom(msg.sender, contributors[i], balances[i]);
        }
    }

    function multisendTokenSameAmount(address token, address[] memory contributors, uint256 balance) external {
        require(contributors.length >= 2, "Multisender: At least 2 contributors is required");
        require(contributors.length <= 65535, "Multisender: At most 65535 contributors is required");

        IERC20 erc20Token = IERC20(token);
        for (uint16 i = 0; i < contributors.length; i++) {
            erc20Token.transferFrom(msg.sender, contributors[i], balance);
        }
    }
    
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }
}
