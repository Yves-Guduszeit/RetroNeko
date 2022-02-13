import { Outlet, Route, Routes } from "react-router-dom";
import React, { useState } from "react";
import { ethers } from "ethers";

import RetroNekoToken from "./artifacts/contracts/tokens/RetroNeko.sol/RetroNeko.json";
import TokenStaking from "./artifacts/contracts/staking/Staking.sol/Staking.json";

import Footer from "./layout/Footer";
import Header from "./layout/Header";

import Dashboard from "./pages/Dashboard";
import Nft from "./pages/Nft";
import Staking from "./pages/Staking";

import { ReactNotifications, Store } from "react-notifications-component";
import 'animate.css/animate.min.css';

const { StakingProxyDeployedAddress, RetroNekoProxyDeployedAddress } = require("../config.testnest.json");

export default function App() {
  const [connectionButtonText, setConnectionButtonText] = useState("Connect Wallet");
  const [connected, setConnected] = useState(false);

  async function requestAccount() {
    await window.ethereum.request({ method: "eth_requestAccounts" });
  }

  //Type: success, danger, info, warning, default
  function newNotification(title, message, type) {
    var pattern = /MetaMask Tx Signature: |execution reverted: /;
    Store.addNotification({
      title: title,
      message: message.replace(pattern, ""),
      type: type,
      insert: "top",
      container: "top-right",
      animationIn: ["animate__animated", "animate__fadeInRight"],
      animationOut: ["animate__animated", "animate__fadeOutRight"],
      dismiss: {
        duration: 5000,
      }
    });
  }

  async function getSigner() {
    await requestAccount();
    let provider = new ethers.providers.Web3Provider(window.ethereum);
    return provider.getSigner();
  }

  async function getAddress() {
    const signer = await getSigner();
    return signer.getAddress();
  }

  async function getTokenContract() {
    let signer = await getSigner();
    return new ethers.Contract(RetroNekoProxyDeployedAddress, RetroNekoToken.abi, signer);
  }

  async function getStakeContract() {
    let signer = await getSigner();
    return new ethers.Contract(StakingProxyDeployedAddress, TokenStaking.abi, signer);
  }

  async function getStakeInfo() {
    const stakingContract = await getStakeContract();
    return stakingContract.stakeSummary(getAddress());
  }

  async function getTotalRewards() {
    const stakingContract = await getStakeContract();
    return stakingContract.totalClaimableAmount();
  }

  async function getTotalStakedAmount() {
    const stakingContract = await getStakeContract();
    return stakingContract.totalStakedAmount();
  }

  async function connectWalletHandler() {
    if (window.ethereum) {
      await requestAccount();
      await getStakeInfo();
      await setConnectionButtonText("Wallet Connected");
      await setConnected(true);
    } else {
      newNotification("An error occurred", "You need to install MetaMask !", "warning");
    }
  }

  return (
    <div>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route
            index
            element={
              <Dashboard
                connected={connected}
                getTokenContract={() => getTokenContract()}
                getStakeContract={() => getStakeContract()}
                getSigner={() => getSigner()}
                getAddress={() => getAddress()}
                getStakeInfo={() => getStakeInfo()}
                getTotalRewards={() => getTotalRewards()}
                getTotalStakedAmount={() => getTotalStakedAmount()}
                newNotification={(title, message, type) => newNotification(title, message, type)}
              />
            }
          />
          <Route
            path="staking"
            element={
              <Staking
                connected={connected}
                getTokenContract={() => getTokenContract()}
                getStakeContract={() => getStakeContract()}
                getSigner={() => getSigner()}
                getAddress={() => getAddress()}
                getStakeInfo={() => getStakeInfo()}
                newNotification={(title, message, type) => newNotification(title, message, type)}
              />
            }
          />
          <Route path="nft" element={<Nft />} />

          <Route path="*" element={<Dashboard />} />
        </Route>
      </Routes>
    </div>
  );

  function Layout() {
    return (
      <div>
        <ReactNotifications />
        <Header
          connectionButtonText={connectionButtonText}
          getStakeInfo={() => getStakeInfo()}
          connectWalletHandler={connectWalletHandler}
        />
        <Outlet />
        <Footer />
      </div>
    );
  }
}
