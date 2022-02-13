const { ethers, run, upgrades } = require("hardhat");

const {
    RetroNekoProxyDeployedAddress,
    RewardsCalculatorProxyDeployedAddress
} = require('../../src/config.json');

async function main() {
    const retroNekoProxy = await loadRetroNekoProxy(RetroNekoProxyDeployedAddress);

    const rewardsCalculatorProxy = await loadRewardsCalculatorProxy(RewardsCalculatorProxyDeployedAddress);
    // const { rewardsCalculatorProxy, rewardsCalculatorAddress } = await deployRewardsCalculatorViaProxy();
    // try { await verifyRewardsCalculator(rewardsCalculatorAddress); } catch (error) { console.log(`Error: ${error}`); }

    const { stakingProxy, stakingAddress } = await deployStakingViaProxy(retroNekoProxy.address, rewardsCalculatorProxy.address);
    try { await verifyStaking(stakingAddress); } catch (error) { console.log(`Error: ${error}`); }
    
    await excludeStakingProxyFromFees(retroNekoProxy, stakingProxy.address);

    await excludeStakingProxyFromSwap(retroNekoProxy, stakingProxy.address);
    
    await updatePackAmount(stakingProxy, 11192500);

    //TODO: Send staking tokens to Staking contract
}

async function loadRetroNekoProxy(retroNekoProxyAddress) {
    console.log("Loading RetroNekoProxy ...");
    const RetroNeko = await ethers.getContractFactory("RetroNekoV13");
    const retroNekoProxy = await RetroNeko.attach(retroNekoProxyAddress);
    console.log(`RetroNekoProxy loaded from: ${retroNekoProxy.address}`);
    return retroNekoProxy;
}

async function loadRewardsCalculatorProxy(rewardsCalculatorProxyAddress) {
    console.log("Loading RewardsCalculatorProxy ...");
    const RewardsCalculator = await ethers.getContractFactory("RewardsCalculator");
    const rewardsCalculatorProxy = await RewardsCalculator.attach(rewardsCalculatorProxyAddress);
    console.log(`RewardsCalculatorProxy loaded from: ${rewardsCalculatorProxy.address}`);
    return rewardsCalculatorProxy;
}

async function deployRewardsCalculatorViaProxy() {
    console.log("Deploying RewardsCalculator via Proxy ...");
    const RewardsCalculator = await ethers.getContractFactory('RewardsCalculator');
    const rewardsCalculatorProxy = await upgrades.deployProxy(RewardsCalculator, { kind: 'uups' });
    await rewardsCalculatorProxy.deployed();
    console.log(`RewardsCalculatorProxy deployed to: ${rewardsCalculatorProxy.address}`);
    const rewardsCalculatorAddress = await upgrades.erc1967.getImplementationAddress(rewardsCalculatorProxy.address);
    console.log(`RewardsCalculator deployed to: ${rewardsCalculatorAddress}`);
    return { rewardsCalculatorProxy, rewardsCalculatorAddress };
}

async function verifyRewardsCalculator(rewardsCalculatorAddress) {
    console.log("Verifying RewardsCalculator ...");
    await run("verify:verify", {
        address: rewardsCalculatorAddress
    });
    console.log("RewardsCalculator verified");
}

async function deployStakingViaProxy(retroNekoProxyAddress, rewardsCalculatorProxyAddress) {
    console.log("Deploying Staking via Proxy ...");
    const Staking = await ethers.getContractFactory('Staking');
    const stakingProxy = await upgrades.deployProxy(
        Staking,
        [ retroNekoProxyAddress, rewardsCalculatorProxyAddress ],
        { kind: 'uups' });
    await stakingProxy.deployed();
    console.log(`StakingProxy deployed to: ${stakingProxy.address}`);
    const stakingAddress = await upgrades.erc1967.getImplementationAddress(stakingProxy.address);
    console.log(`Staking deployed to: ${stakingAddress}`);
    return { stakingProxy, stakingAddress };
}

async function verifyStaking(stakingAddress) {
    console.log("Verifying Staking ...");
    await run("verify:verify", {
        address: stakingAddress
    });
    console.log("Staking verified");
}

async function excludeStakingProxyFromFees(retroNekoProxy, stakingProxyAddress) {
    console.log("Excluding StakingProxy from fees ...");
    await retroNekoProxy.excludeFromFees(stakingProxyAddress, true);
    console.log("StakingProxy excluded from fees");
}

async function excludeStakingProxyFromSwap(retroNekoProxy, stakingProxyAddress) {
    console.log("Excluding StakingProxy from swap ...");
    await retroNekoProxy.excludeFromSwap(stakingProxyAddress, true);
    console.log("StakingProxy excluded from swap");
}

async function updatePackAmount(stakingProxy, amount) {
    console.log("Updating Pack amount ...");
    await stakingProxy.updatePackAmount(amount);
    console.log("Pack amount updated");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
