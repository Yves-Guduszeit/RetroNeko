const { ethers, run, upgrades } = require("hardhat");

const {
    MultisenderDeployedAddress
} = require('../../src/config.json');

async function main() {
    // const multisender = await loadMultisender(MultisenderDeployedAddress);
    const { multisenderProxy, multisenderAddress } = await deployMultisenderViaProxy();
    try { await verifyMultisender(multisenderAddress); } catch (error) { console.log(`Error: ${error}`); }
}

async function loadMultisender(multisenderAddress) {
    console.log("Loading Multisender ...");
    const Multisender = await ethers.getContractFactory("Multisender");
    const multisender = await Multisender.attach(multisenderAddress);
    console.log(`Multisender loaded from: ${multisender.address}`);
    return multisender;
}

async function deployMultisenderViaProxy() {
    console.log("Deploying Multisender via Proxy ...");
    const Multisender = await ethers.getContractFactory('Multisender');
    const multisenderProxy = await upgrades.deployProxy(Multisender, { kind: 'uups' });
    await multisenderProxy.deployed();
    console.log(`MultisenderProxy deployed to: ${multisenderProxy.address}`);
    const multisenderAddress = await upgrades.erc1967.getImplementationAddress(multisenderProxy.address);
    console.log(`Multisender deployed to: ${multisenderAddress}`);
    return { multisenderProxy, multisenderAddress };
}

async function verifyMultisender(multisenderAddress) {
    console.log("Verifying Multisender ...");
    await run("verify:verify", {
        address: multisenderAddress
    });
    console.log("Multisender verified");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
