const { ethers, run, upgrades } = require("hardhat");

const {
    LiquidityLockerDeployedAddress
} = require('../../src/config.json');

async function main() {
    // const liquidityLocker = await loadLiquidityLocker(LiquidityLockerDeployedAddress);
    const { liquidityLockerProxy, liquidityLockerAddress } = await deployLiquidityLockerViaProxy();
    try { await verifyLiquidityLocker(liquidityLockerAddress); } catch (error) { console.log(`Error: ${error}`); }
}

async function loadLiquidityLocker(liquidityLockerAddress) {
    console.log("Loading LiquidityLocker ...");
    const LiquidityLocker = await ethers.getContractFactory("LiquidityLocker");
    const liquidityLocker = await LiquidityLocker.attach(liquidityLockerAddress);
    console.log(`LiquidityLocker loaded from: ${liquidityLocker.address}`);
    return liquidityLocker;
}

async function deployLiquidityLockerViaProxy() {
    console.log("Deploying LiquidityLocker via Proxy ...");
    const LiquidityLocker = await ethers.getContractFactory('LiquidityLocker');
    const liquidityLockerProxy = await upgrades.deployProxy(LiquidityLocker, { kind: 'uups' });
    await liquidityLockerProxy.deployed();
    console.log(`LiquidityLockerProxy deployed to: ${liquidityLockerProxy.address}`);
    const liquidityLockerAddress = await upgrades.erc1967.getImplementationAddress(liquidityLockerProxy.address);
    console.log(`LiquidityLocker deployed to: ${liquidityLockerAddress}`);
    return { liquidityLockerProxy, liquidityLockerAddress };
}

async function verifyLiquidityLocker(liquidityLockerAddress) {
    console.log("Verifying LiquidityLocker ...");
    await run("verify:verify", {
        address: liquidityLockerAddress
    });
    console.log("LiquidityLocker verified");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
