/* eslint-disable jest/valid-expect */
/* eslint-disable no-undef */

const { ethers } = require('hardhat');
const chai = require('chai');
const expect = chai.expect;
const { solidity } = require('ethereum-waffle');

chai.use(solidity);
chai.should();

chai.use(require("chai-bignumber")(ethers.BigNumber));

describe('Staking', function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        [this.owner, this.holder1] = await ethers.getSigners();
        
        this.TestToken = await ethers.getContractFactory("TestToken");
        this.RewardsCalculator = await ethers.getContractFactory("RewardsCalculator");
        this.Staking = await ethers.getContractFactory("Staking");
    });

    beforeEach(async function () {
        this.testToken = await this.TestToken.deploy();
        await this.testToken.deployed();
        
        this.rewardsCalculator = await upgrades.deployProxy(this.RewardsCalculator, { kind: 'uups' });
        await this.rewardsCalculator.deployed();
        
        this.staking = await upgrades.deployProxy(
            this.Staking,
            [ this.testToken.address, this.rewardsCalculator.address ],
            { kind: 'uups' });
        await this.staking.deployed();
        
        await this.testToken.transfer(this.staking.address, ethers.utils.parseUnits("1000"));
        await this.staking.updatePackAmount(100);
        await this.rewardsCalculator.updateRewardsRates(10, 10, 10);
    });

    it('Staking 100 x 2', async function () {
        await this.testToken.approve(this.staking.address, ethers.utils.parseUnits("200"));
        
        let tx = await this.staking.stakeSilver(0);
        await expect(tx).to.emit(this.staking, 'Staked');

        tx = await this.staking.stakeSilver(1);
        await expect(tx).to.emit(this.staking, 'Staked');
    });

    it("Can't stake more than owning", async function () {
        await this.testToken.transfer(this.holder1.address, ethers.utils.parseUnits("99"));
        await this.testToken.connect(this.holder1).approve(this.staking.address, ethers.utils.parseUnits("100"));

        await expect(this.staking.connect(this.holder1).stakeSilver(0))
            .to.be.revertedWith("Staking: Cannot stake more than you own");
    });

    it("Could not exceed maximum slots", async function () {
        await this.testToken.approve(this.staking.address, ethers.utils.parseUnits("100"));

        await expect(this.staking.stakeSilver(9))
            .to.be.revertedWith("Staking: Silver has only 3 slots");
    });

    it("Could not stake twice on the same slot", async function () {
        await this.testToken.approve(this.staking.address, ethers.utils.parseUnits("200"));

        await this.staking.stakeSilver(0);
        await expect(this.staking.stakeSilver(0))
            .to.be.revertedWith("Staking: Slot is already used");
    });

    it("Calculate rewards", async function () {
        await this.testToken.approve(this.staking.address, ethers.utils.parseUnits("200"));

        await this.staking.stakeSilver(0);

        await ethers.provider.send("evm_increaseTime", [20 * 86400]); // 20 days
        await ethers.provider.send("evm_mine");
        
        let summary = await this.staking.stakeSummary(this.owner.address);

        summary.stakes[0].claimableAmount.should.be.eq(ethers.utils.parseUnits("2"), "Reward should be 2 after staking for twenty hours with 100");
        
        await this.staking.stakeSilver(1);
        
        await ethers.provider.send("evm_increaseTime", [20 * 86400]); // 20 days
        await ethers.provider.send("evm_mine");
        
        summary = await this.staking.stakeSummary(this.owner.address);
        
        summary.stakes[0].claimableAmount.should.be.eq(ethers.utils.parseUnits("4"), "Reward should be 4 after staking for 40 hours");
        summary.stakes[1].claimableAmount.should.be.eq(ethers.utils.parseUnits("2"), "Reward should be 2 after staking for 20 hours");
    });

    it("Calculate each level rewards", async function () {
        await this.rewardsCalculator.updateRewardsRates(30, 40, 50);

        await this.testToken.approve(this.staking.address, ethers.utils.parseUnits("300"));

        await this.staking.stakeSilver(0);
        await this.staking.stakeGold(0);
        await this.staking.stakeDiamond(0);

        await ethers.provider.send("evm_increaseTime", [20 * 86400]); // 20 days
        await ethers.provider.send("evm_mine");
        
        let summary = await this.staking.stakeSummary(this.owner.address);

        summary.stakes[0].claimableAmount.should.be.eq(ethers.utils.parseUnits("6"), "Silver reward should be 6 after staking for twenty hours with 100");
        summary.stakes[3].claimableAmount.should.be.eq(ethers.utils.parseUnits("8"), "Gold reward should be 8 after staking for twenty hours with 100");
        summary.stakes[6].claimableAmount.should.be.eq(ethers.utils.parseUnits("10"), "Diamond reward should be 10 after staking for twenty hours with 100");
    });

    it("Reward stakes", async function () {
        await this.testToken.transfer(this.holder1.address, ethers.utils.parseUnits("1000"));
        await this.testToken.connect(this.holder1).approve(this.staking.address, ethers.utils.parseUnits("200"));
        
        await this.staking.connect(this.holder1).stakeSilver(0);
        await this.staking.connect(this.holder1).stakeSilver(1);

        await ethers.provider.send("evm_increaseTime", [100 * 86400]); // 100 days
        await ethers.provider.send("evm_mine");
        
        await this.staking.connect(this.holder1).withdrawSilver(0);

        let balance = await this.testToken.balanceOf(this.holder1.address);
        balance.should.be.eq(ethers.utils.parseUnits("910"), "Failed to withdraw the stake correctly");
    });

    it("Could not withdraw before period expires", async function () {
        await this.testToken.transfer(this.holder1.address, ethers.utils.parseUnits("1000"));
        await this.testToken.connect(this.holder1).approve(this.staking.address, ethers.utils.parseUnits("100"));
        
        await this.staking.connect(this.holder1).stakeSilver(0);

        await ethers.provider.send("evm_increaseTime", [89 * 86400]); // 89 days
        await ethers.provider.send("evm_mine");

        await expect(this.staking.connect(this.holder1).withdrawSilver(0))
            .to.be.revertedWith("Staking: Silver slot is locked for 90 days");

        await ethers.provider.send("evm_increaseTime", [1 * 86400]); // 1 day
        await ethers.provider.send("evm_mine");
        
        await this.staking.connect(this.holder1).withdrawSilver(0);
    });
});
