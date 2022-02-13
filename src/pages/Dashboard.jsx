import silver_staking from "../assets/img/silver_staking.png";
import gold_staking from "../assets/img/gold_staking.png";
import diamond_staking from "../assets/img/diamond_staking.png";

import twitter_logo from "../assets/logo/Twitter-logo.svg";
import telegram_logo from "../assets/logo/Telegram-logo.svg";

import { Link } from "react-router-dom";
import { useState } from "react";
import { formatNumber } from "../utils/format";

export default function Dashboard(props) {
  const [myRewards, setMyRewards] = useState("-");
  const [totalRewards, setTotalRewards] = useState(null);
  const [totalStaked, setTotalStaked] = useState(null);

  if (props.connected) {
    getMyRewards();
  }
  getTotalStakedAmount();
  getTotalRewards();

  async function getMyRewards() {
    if (myRewards === "-") {
      const stakeInfo = await props.getStakeInfo();
      let totalClaimableAmount =
        Number(stakeInfo["stakes"][0]["claimableAmount"]) +
        Number(stakeInfo["stakes"][1]["claimableAmount"]) +
        Number(stakeInfo["stakes"][2]["claimableAmount"]) +
        Number(stakeInfo["stakes"][3]["claimableAmount"]) +
        Number(stakeInfo["stakes"][4]["claimableAmount"]) +
        Number(stakeInfo["stakes"][5]["claimableAmount"]) +
        Number(stakeInfo["stakes"][6]["claimableAmount"]) +
        Number(stakeInfo["stakes"][7]["claimableAmount"]) +
        Number(stakeInfo["stakes"][8]["claimableAmount"]);
      setMyRewards(formatNumber(totalClaimableAmount));
    }
  }

  async function getTotalStakedAmount() {
    if (totalStaked === null) {
      let totalStaked = await props.getTotalStakedAmount();
      setTotalStaked(`$RNK ${formatNumber(+totalStaked)}`);
    }
  }

  async function getTotalRewards() {
    if (totalRewards === null) {
      const totalRewards = await props.getTotalRewards();
      setTotalRewards(`$RNK ${formatNumber(totalRewards)}`);
    }
  }

  return (
    <div className="w-full h-full flex flex-col px-4 md:flex-row gap-4 items-start justify-center">
      <div className="w-full md:w-fit flex flex-col gap-4">
        <div className="w-full md:w-fit flex flex-col bg-dark-violet rounded-2xl px-12 py-8">
          <div className="flex flex-row gap-8 justify-evenly md:justify-center">
            <div className="flex flex-col text-white font-bold text-center">
              <p className="font-md silver-text-shadow">Silver Staking</p>
              <img
                alt="Fuckinou"
                src={silver_staking}
                className="mt-4 w-24 mb-6 mx-auto select-none"
              />
              <p>3 months lock</p>
              <p className="text-gray">108% APY</p>
            </div>
            <div className="flex flex-col text-white font-bold text-center">
              <p className="font-md gold-text-shadow">Gold Staking</p>
              <img
                alt="Fuckinou"
                src={gold_staking}
                className="mt-4 w-24 mb-6 mx-auto select-none"
              />
              <p>6 months lock</p>
              <p className="text-yellow">144% APY</p>
            </div>
            <div className="flex flex-col text-white font-bold text-center">
              <p className="font-md diamond-text-shadow">Diamond Staking</p>
              <img
                alt="Fuckinou"
                src={diamond_staking}
                className="mt-4 w-24 mb-6 mx-auto select-none"
              />
              <p>9 months lock</p>
              <p className="text-pink">175.5% APY</p>
            </div>
          </div>
          <Link
            className="mt-6 w-full h-10 rounded bg-pink text-white font-bold text-base flex items-center justify-center"
            to="/staking"
          >
            Stake now !
          </Link>
        </div>
        <div className="flex flex-col md:flex-row gap-4 w-full">
          <div className="flex flex-col w-full bg-dark-violet rounded-2xl px-6 py-8 text-center">
            <p className="text-white">Total Staked</p>
            <p className="text-white font-bold text-xl mt-6 bg-graph">{totalStaked}</p>
          </div>
          <div className="flex flex-col w-full bg-dark-violet rounded-2xl px-6 py-8 text-center">
            <p className="text-white">Total Rewards</p>
            <p className="text-white font-bold text-sm mt-6 bg-graph Total distributed" />
            <p className="text-white font-bold text-xl bg-graph">{totalRewards}</p>
          </div>
        </div>
      </div>
      <div className="w-full md:w-fit flex flex-col gap-12">
        <div className="w-full md:w-fit flex flex-col bg-dark-violet rounded-2xl px-6 py-8 text-center">
          <p className="text-white">My Rewards</p>
          <p className="text-white font-bold text-xl mt-6">${myRewards}</p>
          <Link
            className={`mt-8 w-full flex items-center justify-center h-8 px-6 rounded bg-pink text-white font-bold text-base ${
              props.connected ? "opacity-100" : "opacity-50 cursor-default"
            }`}
            to={`${props.connected ? "/staking" : ""}`}
          >
            Claim rewards !
          </Link>
        </div>
        <div className="flex flex-col sm:flex-row md:flex-col gap-4 sm:gap-0 md:gap-4 justify-evenly">
          <a
            href="https://retro-neko-ent.gitbook.io/retro-neko/"
            target="_blank"
            rel="noreferrer"
            className="bg-dark-violet w-fit p-3 mx-auto sm:m-0 md:mx-auto text-white font-bold rounded-lg flex items-center justify-center gap-2"
          >
            <span className="material-icons-round select-none">description</span>
            <p>MeowPaper</p>
          </a>
          <a
            href="https://retro-neko-ent.gitbook.io/retro-neko/5.-staking-and-rewards"
            target="_blank"
            rel="noreferrer"
            className="cursor-pointer bg-dark-violet w-fit p-3 mx-auto sm:m-0 md:mx-auto text-white font-bold rounded-lg flex items-center justify-center gap-2"
          >
            <span className="material-icons-round select-none">description</span>
            <p>Staking guide</p>
          </a>
          <div className="flex flex-row gap-4 justify-center">
            <a
              href="https://t.me/retronekoofficial"
              target="_blank"
              rel="noreferrer"
              className="bg-dark-violet p-3 rounded-lg flex items-center justify-center select-none"
            >
              <img alt="Telegram" src={telegram_logo} className="w-6" />
            </a>
            <a
              href="https://twitter.com/retro_neko"
              target="_blank"
              rel="noreferrer"
              className="bg-dark-violet p-3 rounded-lg flex items-center justify-center select-none"
            >
              <img alt="Twitter" src={twitter_logo} className="w-6" />
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
