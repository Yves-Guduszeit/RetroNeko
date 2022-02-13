/*
Retro Neko

Total Supply:
    100,000,000,000 $RNK

Taxes:
    Buy Tax:  8.0%
        1.0% Auto Liquidity
        2.0% Team
        3.0% Marketing
        0.0% Staking
        2.0% War

    Sell Tax: 10.0%
        1.0% Auto Liquidity
        2.0% Team
        3.0% Marketing
        0.0% Staking
        4.0% War

Features:
    Manual Blacklist Function
    
 *
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract RetroNekoV13 is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    struct Fees {
        uint256 liquidityFeesPerTenThousand;
        uint256 teamFeesPerTenThousand;
        uint256 providerFeesPerTenThousand;
        uint256 marketingFeesPerTenThousand;
        uint256 stakingFeesPerTenThousand;
        uint256 warFeesPerTenThousand;
    }
    
    address private _router;

    mapping (address => bool) private _isAutomatedMarketMakerPairs;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isBlacklisted;
    
    bool private _isBuying;
    Fees private _buyFees;
    Fees private _sellFees;

    uint256 private _swapThreshold;
    uint256 private _gasForProcessing;

    address private _teamWallet;
    address private _marketingWallet;
    address private _stakingWallet;
    address private _warWallet;

    bool private _inSwap;
    modifier swapping()
    {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    bool private _tradingEnabled;
    bool private _takeFeesEnabled;
    bool private _swapEnabled;

    uint256 private _deadBlocks;
    uint256 private _launchedAt;
    
    mapping (address => bool) private _isExcludedFromSwap;

    event TradingEnabled(bool isEnabled);
    event TakeFeesEnabled(bool isEnabled);
    event SwapEnabled(bool isEnabled);
    event UniswapV2RouterUpdated(address indexed previousAddress, address indexed newAddress);
    event TeamWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event MarketingWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event StakingWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event WarWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event LiquidityBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event TeamBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event MarketingBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event StakingBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event WarBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event BuyFeesUpdated(
        uint256 previousLiquidityFeesPerTenThousand, uint256 newLiquidityFeesPerTenThousand,
        uint256 previousTeamFeesPerTenThousand, uint256 newTeamFeesPerTenThousand,
        uint256 previousMarketingFeesPerTenThousand, uint256 newMarketingFeesPerTenThousand,
        uint256 previousStakingFeesPerTenThousand, uint256 newStakingFeesPerTenThousand,
        uint256 previousWarFeesPerTenThousand, uint256 newWarFeesPerTenThousand);
    event LiquiditySellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event TeamSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event MarketingSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event StakingSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event WarSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event SellFeesUpdated(
        uint256 previousLiquidityFeesPerTenThousand, uint256 newLiquidityFeesPerTenThousand,
        uint256 previousTeamFeesPerTenThousand, uint256 newTeamFeesPerTenThousand,
        uint256 previousMarketingFeesPerTenThousand, uint256 newMarketingFeesPerTenThousand,
        uint256 previousStakingFeesPerTenThousand, uint256 newStakingFeesPerTenThousand,
        uint256 previousWarFeesPerTenThousand, uint256 newWarFeesPerTenThousand);
    event FeesSentToWallet(address indexed wallet, uint256 amount);
    event ExcludedFromFees(address indexed account, bool isExcluded);
    event ExcludedFromSwap(address indexed account, bool isExcluded);
    event AutomatedMarketMakerPairSet(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event SwappedAndLiquified(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address newRouter,
        address newTeamWallet,
        address newMarketingWallet,
        address newStakingWallet,
        address newWarWallet) public initializer {
        __ERC20_init("RetroNeko", "RNK");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _tradingEnabled = false;
        _takeFeesEnabled = true;
        _swapEnabled = true;
        
        _router = newRouter;
    	_teamWallet = newTeamWallet;
    	_marketingWallet = newMarketingWallet;
    	_stakingWallet = newStakingWallet;
    	_warWallet = newWarWallet;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 routerObject = IUniswapV2Router02(_router);
        address pair = IUniswapV2Factory(routerObject.factory()).createPair(address(this), routerObject.WETH());
        _setAutomatedMarketMakerPair(pair, true);
        
        _swapThreshold = 50_000_000 * 10 ** decimals(); // 50M $RNK ( 0.05% )
        _gasForProcessing = 300_000; // 300K

        // Buy fees
        _buyFees.liquidityFeesPerTenThousand = 100; // 1.00%
        _buyFees.teamFeesPerTenThousand = 200; // 2.00%
        _buyFees.marketingFeesPerTenThousand = 300; // 3.00%
        _buyFees.stakingFeesPerTenThousand = 0; // 0.00%
        _buyFees.warFeesPerTenThousand = 200; // 2.00%

        // Sell fees
        _sellFees.liquidityFeesPerTenThousand = 100; // 1.00%
        _sellFees.teamFeesPerTenThousand = 200; // 2.00%
        _sellFees.marketingFeesPerTenThousand = 300; // 3.00%
        _sellFees.stakingFeesPerTenThousand = 0; // 0.00%
        _sellFees.warFeesPerTenThousand = 400; // 4.00%
        
        _mint(owner(), 100_000_000_000 * 10 ** decimals()); // 100B $RNK
    }

    receive() external payable {
  	}

    function isTradingEnabled() external view returns (bool) {
        return _tradingEnabled;
    }

    function isTakeFeesEnabled() external view returns (bool) {
        return _takeFeesEnabled;
    }

    function isSwapEnabled() external view returns (bool) {
        return _swapEnabled;
    }

    function router() external view returns (address) {
        return _router;
    }

    function isAutomatedMarketMakerPair(address account) external view returns (bool) {
        return _isAutomatedMarketMakerPairs[account];
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromSwap(address account) external view returns (bool) {
        return _isExcludedFromSwap[account];
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function buyFees() public view returns (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 stakingFeesPerTenThousand,
        uint256 warFeesPerTenThousand,
        uint256 totalFeesPerTenThousand) {
        return (
            _buyFees.liquidityFeesPerTenThousand,
            _buyFees.teamFeesPerTenThousand,
            _buyFees.marketingFeesPerTenThousand,
            _buyFees.stakingFeesPerTenThousand,
            _buyFees.warFeesPerTenThousand,
            _totalBuyFees());
    }

    function sellFees() public view returns (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 stakingFeesPerTenThousand,
        uint256 warFeesPerTenThousand,
        uint256 totalFeesPerTenThousand) {
        return (
            _sellFees.liquidityFeesPerTenThousand,
            _sellFees.teamFeesPerTenThousand,
            _sellFees.marketingFeesPerTenThousand,
            _sellFees.stakingFeesPerTenThousand,
            _sellFees.warFeesPerTenThousand,
            _totalSellFees());
    }
    
    function swapThreshold() external view returns (uint256) {
        return _swapThreshold;
    }

    function gasForProcessing() external view returns (uint256) {
        return _gasForProcessing;
    }
    
    function teamWallet() external view returns (address) {
        return _teamWallet;
    }

    function marketingWallet() external view returns (address) {
        return _marketingWallet;
    }

    function stakingWallet() external view returns (address) {
        return _stakingWallet;
    }

    function warWallet() external view returns (address) {
        return _warWallet;
    }

    function enableTrading(bool isEnabled) external onlyOwner {
        require(_tradingEnabled != isEnabled, "RetroNeko: Trading enabled is already the value of 'isEnabled'");

        _tradingEnabled = isEnabled;
        if (isEnabled) {
            _launchedAt = block.number;
        }

        emit TradingEnabled(isEnabled);
    }

    function enableTakeFees(bool isEnabled) external onlyOwner {
        require(_takeFeesEnabled != isEnabled, "RetroNeko: Take fees enabled is already the value of 'isEnabled'");

        _takeFeesEnabled = isEnabled;

        emit TakeFeesEnabled(isEnabled);
    }

    function enableSwap(bool isEnabled) external onlyOwner {
        require(_swapEnabled != isEnabled, "RetroNeko: Swap enabled is already the value of 'isEnabled'");

        _swapEnabled = isEnabled;

        emit SwapEnabled(isEnabled);
    }

    function updateUniswapV2Router(address newRouter) external onlyOwner {
        require(newRouter != _router, "RetroNeko: The router already has that address");

        address previousRouter = _router;
        IUniswapV2Router02 routerObject = IUniswapV2Router02(newRouter);
        address newPair = IUniswapV2Factory(routerObject.factory()).createPair(address(this), routerObject.WETH());
        _setAutomatedMarketMakerPair(newPair, true);
        _router = newRouter;
        
        emit UniswapV2RouterUpdated(previousRouter, newRouter);
    }

    function updateTeamWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _teamWallet, "RetroNeko: The team wallet already has that address");

        address previousWallet = _teamWallet;
        _teamWallet = newWallet;

        emit TeamWalletUpdated(previousWallet, newWallet);
    }

    function updateMarketingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _marketingWallet, "RetroNeko: The marketing wallet already has that address");

        address previousWallet = _marketingWallet;
        _marketingWallet = newWallet;

        emit MarketingWalletUpdated(previousWallet, newWallet);
    }

    function updateStakingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _stakingWallet, "RetroNeko: The staking wallet already has that address");

        address previousWallet = _stakingWallet;
        _stakingWallet = newWallet;

        emit StakingWalletUpdated(previousWallet, newWallet);
    }

    function updateWarWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _warWallet, "RetroNeko: The war wallet already has that address");

        address previousWallet = _warWallet;
        _warWallet = newWallet;

        emit WarWalletUpdated(previousWallet, newWallet);
    }

    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "RetroNeko: Account is already the value of 'excluded'");

        _isExcludedFromFees[account] = excluded;

        emit ExcludedFromFees(account, excluded);
    }

    function excludeFromSwap(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromSwap[account] != excluded, "RetroNeko: Account is already the value of 'excluded'");

        _isExcludedFromSwap[account] = excluded;

        emit ExcludedFromSwap(account, excluded);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200_000 && newValue <= 500_000, "RetroNeko: gas must be between 200,000 and 500,000");
        require(newValue != _gasForProcessing, "RetroNeko: Cannot update gas to same value");

        emit GasForProcessingUpdated(_gasForProcessing, newValue);
        _gasForProcessing = newValue;
    }

    function updateSwapThreshold(uint256 threshold) external onlyOwner {
        _swapThreshold = threshold * 10 ** decimals();
    }

    function updateBuyFees (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 stakingFeesPerTenThousand,
        uint256 warFeesPerTenThousand) external onlyOwner {
        require(
            liquidityFeesPerTenThousand != _buyFees.liquidityFeesPerTenThousand ||
            teamFeesPerTenThousand != _buyFees.teamFeesPerTenThousand ||
            marketingFeesPerTenThousand != _buyFees.marketingFeesPerTenThousand ||
            stakingFeesPerTenThousand != _buyFees.stakingFeesPerTenThousand ||
            warFeesPerTenThousand != _buyFees.warFeesPerTenThousand, "RetroNeko: Buy fees has already the same values");
        
        uint256 previousLiquidityFeesPerTenThousand = _buyFees.liquidityFeesPerTenThousand;
        _buyFees.liquidityFeesPerTenThousand = liquidityFeesPerTenThousand;

        uint256 previousTeamFeesPerTenThousand = _buyFees.teamFeesPerTenThousand;
        _buyFees.teamFeesPerTenThousand = teamFeesPerTenThousand;

        uint256 previousMarketingFeesPerTenThousand = _buyFees.marketingFeesPerTenThousand;
        _buyFees.marketingFeesPerTenThousand = marketingFeesPerTenThousand;

        uint256 previousStakingFeesPerTenThousand = _buyFees.stakingFeesPerTenThousand;
        _buyFees.stakingFeesPerTenThousand = stakingFeesPerTenThousand;

        uint256 previousWarFeesPerTenThousand = _buyFees.warFeesPerTenThousand;
        _buyFees.warFeesPerTenThousand = warFeesPerTenThousand;

        emit BuyFeesUpdated(
            previousLiquidityFeesPerTenThousand, liquidityFeesPerTenThousand,
            previousTeamFeesPerTenThousand, teamFeesPerTenThousand,
            previousMarketingFeesPerTenThousand, marketingFeesPerTenThousand,
            previousStakingFeesPerTenThousand, stakingFeesPerTenThousand,
            previousWarFeesPerTenThousand, warFeesPerTenThousand);
    }

    function updateLiquidityBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.liquidityFeesPerTenThousand, "RetroNeko: Liquidity buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.liquidityFeesPerTenThousand;
        _buyFees.liquidityFeesPerTenThousand = feesPerTenThousand;

        emit LiquidityBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateTeamBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.teamFeesPerTenThousand, "RetroNeko: Team buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.teamFeesPerTenThousand;
        _buyFees.teamFeesPerTenThousand = feesPerTenThousand;

        emit TeamBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateMarketingBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.marketingFeesPerTenThousand, "RetroNeko: Marketing buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.marketingFeesPerTenThousand;
        _buyFees.marketingFeesPerTenThousand = feesPerTenThousand;

        emit MarketingBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateStakingBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.stakingFeesPerTenThousand, "RetroNeko: Staking buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.stakingFeesPerTenThousand;
        _buyFees.stakingFeesPerTenThousand = feesPerTenThousand;

        emit StakingBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateWarBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.warFeesPerTenThousand, "RetroNeko: War buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.warFeesPerTenThousand;
        _buyFees.warFeesPerTenThousand = feesPerTenThousand;

        emit WarBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateSellFees (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 stakingFeesPerTenThousand,
        uint256 warFeesPerTenThousand) external onlyOwner {
        require(
            liquidityFeesPerTenThousand != _sellFees.liquidityFeesPerTenThousand ||
            teamFeesPerTenThousand != _sellFees.teamFeesPerTenThousand ||
            marketingFeesPerTenThousand != _sellFees.marketingFeesPerTenThousand ||
            stakingFeesPerTenThousand != _sellFees.stakingFeesPerTenThousand ||
            warFeesPerTenThousand != _sellFees.warFeesPerTenThousand, "RetroNeko: Sell fees has already the same values");
        
        uint256 previousLiquidityFeesPerTenThousand = _sellFees.liquidityFeesPerTenThousand;
        _sellFees.liquidityFeesPerTenThousand = liquidityFeesPerTenThousand;

        uint256 previousTeamFeesPerTenThousand = _sellFees.teamFeesPerTenThousand;
        _sellFees.teamFeesPerTenThousand = teamFeesPerTenThousand;

        uint256 previousMarketingFeesPerTenThousand = _sellFees.marketingFeesPerTenThousand;
        _sellFees.marketingFeesPerTenThousand = marketingFeesPerTenThousand;

        uint256 previousStakingFeesPerTenThousand = _sellFees.stakingFeesPerTenThousand;
        _sellFees.stakingFeesPerTenThousand = stakingFeesPerTenThousand;

        uint256 previousWarFeesPerTenThousand = _sellFees.warFeesPerTenThousand;
        _sellFees.warFeesPerTenThousand = warFeesPerTenThousand;

        emit SellFeesUpdated(
            previousLiquidityFeesPerTenThousand, liquidityFeesPerTenThousand,
            previousTeamFeesPerTenThousand, teamFeesPerTenThousand,
            previousMarketingFeesPerTenThousand, marketingFeesPerTenThousand,
            previousStakingFeesPerTenThousand, stakingFeesPerTenThousand,
            previousWarFeesPerTenThousand, warFeesPerTenThousand);
    }

    function updateLiquiditySellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.liquidityFeesPerTenThousand, "RetroNeko: Liquidity sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.liquidityFeesPerTenThousand;
        _sellFees.liquidityFeesPerTenThousand = feesPerTenThousand;

        emit LiquiditySellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateTeamSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.teamFeesPerTenThousand, "RetroNeko: Team sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.teamFeesPerTenThousand;
        _sellFees.teamFeesPerTenThousand = feesPerTenThousand;

        emit TeamSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateMarketingSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.marketingFeesPerTenThousand, "RetroNeko: Marketing sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.marketingFeesPerTenThousand;
        _sellFees.marketingFeesPerTenThousand = feesPerTenThousand;

        emit MarketingSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateStakingSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.stakingFeesPerTenThousand, "RetroNeko: Staking sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.stakingFeesPerTenThousand;
        _sellFees.stakingFeesPerTenThousand = feesPerTenThousand;

        emit StakingSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateWarSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.warFeesPerTenThousand, "RetroNeko: War sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.warFeesPerTenThousand;
        _sellFees.warFeesPerTenThousand = feesPerTenThousand;

        emit WarSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function manualSwapSendFeesAndLiquify(
        uint256 amount,
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 stakingFeesPerTenThousand,
        uint256 warFeesPerTenThousand) external onlyOwner swapping {
        uint256 totalFeesPerTenThousand =
            liquidityFeesPerTenThousand +
            teamFeesPerTenThousand +
            marketingFeesPerTenThousand +
            stakingFeesPerTenThousand +
            warFeesPerTenThousand;
        uint256 tokenBalance = amount * 10 ** decimals();
        
        uint256 liquidityTokenAmount = tokenBalance * liquidityFeesPerTenThousand / totalFeesPerTenThousand / 2;
        uint256 tokenAmountToSwap = tokenBalance - liquidityTokenAmount;

        _swapTokensForEth(tokenAmountToSwap);
        uint256 ethAmount = address(this).balance;

        uint256 teamEthAmount = ethAmount * teamFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_teamWallet, teamEthAmount);
        
        uint256 marketingEthAmount = ethAmount * marketingFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_marketingWallet, marketingEthAmount);
        
        uint256 stakingEthAmount = ethAmount * stakingFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_stakingWallet, stakingEthAmount);

        uint256 warEthBalance = ethAmount * warFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_warWallet, warEthBalance);

        uint256 liquidityEthAmount = ethAmount - teamEthAmount - marketingEthAmount - stakingEthAmount - warEthBalance;
        _liquify(liquidityTokenAmount, liquidityEthAmount);
    }
    
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }

    function _currentFees() private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return _isBuying ? buyFees() : sellFees();
    }

    function _currentTotalFees() private view returns (uint256) {
        return _isBuying ? _totalBuyFees() : _totalSellFees();
    }

    function _totalBuyFees() private view returns (uint256) {
        return (
            _buyFees.liquidityFeesPerTenThousand +
            _buyFees.teamFeesPerTenThousand +
            _buyFees.marketingFeesPerTenThousand +
            _buyFees.stakingFeesPerTenThousand +
            _buyFees.warFeesPerTenThousand);
    }

    function _totalSellFees() private view returns (uint256) {
        return (
            _sellFees.liquidityFeesPerTenThousand +
            _sellFees.teamFeesPerTenThousand +
            _sellFees.marketingFeesPerTenThousand +
            _sellFees.stakingFeesPerTenThousand +
            _sellFees.warFeesPerTenThousand);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(_isAutomatedMarketMakerPairs[newPair] != value, "RetroNeko: Automated market maker pair is already set to that value");
        _isAutomatedMarketMakerPairs[newPair] = value;

        emit AutomatedMarketMakerPairSet(newPair, value);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        address presaleAddress = 0xAEEA45f0FeDE1f6EB18AB492Be78b55D41E04a61;
        require(_msgSender() == owner() || sender == presaleAddress || _tradingEnabled, "RetroNeko: Trading is not enabled");
        require(sender != address(0), "RetroNeko: Transfer from the zero address");
        require(recipient != address(0), "RetroNeko: Transfer to the zero address");
        require(amount > 0, "RetroNeko: Transfer zero token");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], 'RetroNeko: Blacklisted address');

        if (_shouldPerformBasicTransfer(sender, recipient)) {
            _basicTransfer(sender, recipient, amount);
        } else {
            _customTransfer(sender, recipient, amount);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        super._transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _customTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        address presaleAddress = 0xAEEA45f0FeDE1f6EB18AB492Be78b55D41E04a61;
        _isBuying = _isAutomatedMarketMakerPairs[sender];
        
        if (sender != presaleAddress) {
            if (_shouldTakeFees(sender, recipient)) {
                uint256 totalFeesPerTenThousand = _currentTotalFees();
        	    uint256 feesAmount = amount * totalFeesPerTenThousand / 10_000;
        	    amount -= feesAmount;

                if (feesAmount > 0) {
                    super._transfer(sender, address(this), feesAmount);
                }
            }
        }

        if (_shouldSwap(sender, recipient)) {
            _swapSendFeesAndLiquify();
        }

        if (amount > 0) {
            super._transfer(sender, recipient, amount);
        }
        
        return true;
    }

    function _shouldPerformBasicTransfer(address sender, address recipient) private view returns (bool) {
        return
            _inSwap ||
            sender == owner() || recipient == owner() ||
            sender == _teamWallet || recipient == _teamWallet ||
            sender == _marketingWallet || recipient == _marketingWallet ||
            sender == _stakingWallet || recipient == _stakingWallet ||
            sender == _warWallet || recipient == _warWallet;
    }

    function _shouldTakeFees(address sender, address recipient) private view returns (bool) {
        return
            _takeFeesEnabled &&
            !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient];
    }
    
    function _shouldSwap(address sender, address recipient) private view returns (bool) {
        return
            _swapEnabled &&
            balanceOf(address(this)) >= _swapThreshold &&
            !_isAutomatedMarketMakerPairs[sender] &&
            !_isExcludedFromSwap[sender] && !_isExcludedFromSwap[recipient];
    }

    function _swapSendFeesAndLiquify() private swapping {
        uint256 tokenBalance = _swapThreshold;
        (
            uint256 liquidityFeesPerTenThousand,
            uint256 teamFeesPerTenThousand,
            uint256 marketingFeesPerTenThousand,
            uint256 stakingFeesPerTenThousand,
            uint256 warFeesPerTenThousand,
            uint256 totalFeesPerTenThousand) = _currentFees();
        
        uint256 liquidityTokenAmount = tokenBalance * liquidityFeesPerTenThousand / totalFeesPerTenThousand / 2;
        uint256 tokenAmountToSwap = tokenBalance - liquidityTokenAmount;

        _swapTokensForEth(tokenAmountToSwap);
        uint256 ethAmount = address(this).balance;

        uint256 teamEthAmount = ethAmount * teamFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_teamWallet, teamEthAmount);
        
        uint256 marketingEthAmount = ethAmount * marketingFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_marketingWallet, marketingEthAmount);
        
        uint256 stakingEthAmount = ethAmount * stakingFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_stakingWallet, stakingEthAmount);

        uint256 warEthBalance = ethAmount * warFeesPerTenThousand / totalFeesPerTenThousand;
        _sendFeesToWallet(_warWallet, warEthBalance);

        uint256 liquidityEthAmount = ethAmount - teamEthAmount - marketingEthAmount - stakingEthAmount - warEthBalance;
        _liquify(liquidityTokenAmount, liquidityEthAmount);
    }

    function _sendFeesToWallet(address wallet, uint256 ethAmount) private {
        if (ethAmount > 0) {
            (bool success, /* bytes memory data */) = wallet.call{value: ethAmount}("");
            if (success) {
                emit FeesSentToWallet(wallet, ethAmount);
            }
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        if (tokenAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(_router).WETH();

            _approve(address(this), _router, tokenAmount);
            IUniswapV2Router02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp);
        }
    }

    function _liquify(uint256 tokenAmount, uint256 ethAmount) private {
        if (tokenAmount > 0 && ethAmount > 0) {
            _addLiquidity(tokenAmount, ethAmount);

            emit SwappedAndLiquified(tokenAmount, ethAmount, tokenAmount);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), _router, tokenAmount);
        IUniswapV2Router02(_router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
}
