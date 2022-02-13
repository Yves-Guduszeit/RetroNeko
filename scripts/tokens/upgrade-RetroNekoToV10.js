const { ethers, run, upgrades } = require("hardhat");

const {
    RetroNekoProxyDeployedAddress
} = require('../../src/config.json');

async function main() {
    const { retroNekoProxy, retroNekoAddress } = await upgradeRetroNekoViaProxy(RetroNekoProxyDeployedAddress);
    try { await verifyRetroNeko(retroNekoAddress); } catch (error) { console.log(`Error: ${error}`); }
}

async function upgradeRetroNekoViaProxy(retroNekoProxyAddress) {
    console.log("Upgrading RetroNeko via Proxy ...");
    const RetroNeko = await ethers.getContractFactory("contracts/tokens/RetroNekoV10.sol:RetroNekoV10");
    const retroNekoProxy = await upgrades.upgradeProxy(retroNekoProxyAddress, RetroNeko);
    await retroNekoProxy.deployed();
    console.log(`RetroNekoProxy deployed to: ${retroNekoProxy.address}`);
    const retroNekoAddress = await upgrades.erc1967.getImplementationAddress(retroNekoProxy.address);
    console.log(`RetroNeko upgraded to: ${retroNekoAddress}`);
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
