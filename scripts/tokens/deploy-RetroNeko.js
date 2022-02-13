const { ethers, run, upgrades } = require("hardhat");

const {
    UniswapV2Router02DeployedAddress
} = require('../../src/config.json');

const {
    TeamWallet,
    MarketingWallet,
    StakingWallet,
    WarWallet
} = require('../../secrets.json');

async function main() {
    const { retroNekoProxy, retroNekoAddress } = await deployRetroNekoViaProxy(
        UniswapV2Router02DeployedAddress, TeamWallet, MarketingWallet, StakingWallet, WarWallet);
    try { await verifyRetroNeko(retroNekoAddress); } catch (error) { console.log(`Error: ${error}`); }
}

async function deployRetroNekoViaProxy(routerAddress, teamWallet, marketingWallet, stakingWallet, warWallet) {
    console.log("Deploying RetroNeko via Proxy ...");
    const RetroNeko = await ethers.getContractFactory("contracts/tokens/RetroNeko.sol:RetroNeko");
    const retroNekoProxy = await upgrades.deployProxy(
        RetroNeko,
        [ routerAddress, teamWallet, marketingWallet, stakingWallet, warWallet ],
        { kind: 'uups' });
    await retroNekoProxy.deployed();
    console.log(`RetroNekoProxy deployed to: ${retroNekoProxy.address}`);
    const retroNekoAddress = await upgrades.erc1967.getImplementationAddress(retroNekoProxy.address);
    console.log(`RetroNeko deployed to: ${retroNekoAddress}`);
    return { retroNekoProxy, retroNekoAddress };
}

async function verifyRetroNeko(retroNekoAddress) {
    console.log("Verifying RetroNeko ...");
    await run("verify:verify", {
        address: retroNekoAddress
    });
    console.log("RetroNeko verified");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
