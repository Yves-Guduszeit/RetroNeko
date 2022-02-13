import silver_staking from "../assets/img/silver_staking.png";
import gold_staking from "../assets/img/gold_staking.png";
import diamond_staking from "../assets/img/diamond_staking.png";
import { BigNumber } from "ethers";
import { formatSecond, timeLeftInSeconds } from "../utils/format";
import { useState } from "react";
import StakingButton from "./components/StakingButton";
import Modal from "../overlays/Modal";

const { StakingProxyDeployedAddress } = require("../config.json");

export default function Staking(props) {
  const amount = BigNumber.from("99999999999914289216000000000000000000");
  const [stakingSlot0, setStakingSlot0] = useState("Slot 1");
  const [stakingSlot1, setStakingSlot1] = useState("Slot 2");
  const [stakingSlot2, setStakingSlot2] = useState("Slot 3");
  const [stakingSlot3, setStakingSlot3] = useState("Slot 1");
  const [stakingSlot4, setStakingSlot4] = useState("Slot 2");
  const [stakingSlot5, setStakingSlot5] = useState("Slot 3");
  const [stakingSlot6, setStakingSlot6] = useState("Slot 1");
  const [stakingSlot7, setStakingSlot7] = useState("Slot 2");
  const [stakingSlot8, setStakingSlot8] = useState("Slot 3");

  const [isModalShow, setIsModalShow] = useState(false);
  const [modalType, setModalType] = useState("");
  const [modalTitle, setModalTitle] = useState("");
  const [modalMessage, setModalMessage] = useState("");
  const [modalConfirmation, setModalConfirmation] = useState("");
  const [modalCancel, setModalCancel] = useState("");

  const [indexChoose, setIndexChoose] = useState(0);
  const [level, setLevel] = useState("silver");

  async function checkForApprove(amount) {
    if (window.ethereum) {
      try {
        const signerAddress = await props.getAddress();
        const tokenContract = await props.getTokenContract();

        if ((await tokenContract.allowance(StakingProxyDeployedAddress, signerAddress)) < amount) {
          let transation = await tokenContract.approve(StakingProxyDeployedAddress, amount);
          await transation.wait();
          return true;
        }
      } catch (error) {
        props.newNotification("An error Occurred", error.message.toString(), "danger");
        return false;
      }
    }
  }

  async function silverStaking(index) {
    if (props.connected) {
      if (0 <= index && index < 3) {
        const stakeInfo = await props.getStakeInfo();
        const stakingContract = await props.getStakeContract();

        if (stakeInfo?.["stakes"]?.[index]?.["amount"].toString() === "0") {
          if (await checkForApprove(amount)) {
            try {
              await stakingContract.stakeSilver(index);
              props.newNotification(
                "Permission granted",
                `Your request for the silver staking is being processed. When accepted on Metamask refresh the page.`,
                "info",
              );
            } catch (error) {
              props.newNotification("An error Occurred", error.data.message.toString(), "danger");
            }
          }
        } else if (timeLeftInSeconds(index, stakeInfo?.["stakes"]?.[index]?.["since"]) <= 0) {
          try {
            await stakingContract.withdrawSilver(index);
            props.newNotification(
              "Success",
              `You successfully withdraw your silver stake`,
              "success",
            );
          } catch (error) {
            const message = error.data.message.toString();
            props.newNotification("An error occurred", message, "danger");
          }
        }
      }
    } else {
      props.newNotification(
        "An error occurred",
        "You need to connect your metamask first !",
        "warning",
      );
    }
  }

  async function goldStaking(index) {
    if (props.connected) {
      if (0 <= index && index < 3) {
        const stakeInfo = await props.getStakeInfo();
        const stakingContract = await props.getStakeContract();

        if (stakeInfo?.["stakes"]?.[index + 3]?.["amount"].toString() === "0") {
          if (await checkForApprove(amount)) {
            try {
              await stakingContract.stakeGold(index);
              props.newNotification(
                "Permission granted",
                `Your request for the gold staking is being processed`,
                "info",
              );
            } catch (error) {
              props.newNotification("An error Occurred", error.data.message.toString(), "danger");
            }
          }
        } else if (timeLeftInSeconds(index, stakeInfo?.["stakes"]?.[index + 3]?.["since"]) <= 0) {
          try {
            await stakingContract.withdrawGold(index);
            props.newNotification(
              "Success",
              `You successfully withdraw your gold stake`,
              "success",
            );
          } catch (error) {
            const message = error.data.message.toString();
            props.newNotification("An error occurred", message, "danger");
          }
        }
      }
    } else {
      props.newNotification(
        "An error occurred",
        "You need to connect your metamask first !",
        "warning",
      );
    }
  }

  async function diamondStaking(index) {
    if (props.connected) {
      if (0 <= index && index < 3) {
        const stakeInfo = await props.getStakeInfo();
        const stakingContract = await props.getStakeContract();

        if (stakeInfo?.["stakes"]?.[index + 3]?.["amount"].toString() === "0") {
          if (await checkForApprove(amount)) {
            try {
              await stakingContract.stakeDiamond(index);
              props.newNotification(
                "Permission granted",
                `Your request for the diamond staking is being processed`,
                "info",
              );
            } catch (error) {
              props.newNotification("An error Occurred", error.data.message.toString(), "danger");
            }
          }
        } else if (timeLeftInSeconds(index, stakeInfo?.["stakes"]?.[index + 6]?.["since"]) <= 0) {
          try {
            await stakingContract.withdrawDiamond(index);
            props.newNotification(
              "Success",
              `You successfully withdraw your diamond stake`,
              "success",
            );
          } catch (error) {
            const message = error.data.message.toString();
            props.newNotification("An error occurred", message, "danger");
          }
        }
      }
    } else {
      props.newNotification(
        "An error occurred",
        "You need to connect your metamask first !",
        "warning",
      );
    }
  }

  async function refreshStakingSlot() {
    const stakeInfo = await props.getStakeInfo();
    for (let i = 0; i < 8; i++) {
      if (stakeInfo?.["stakes"]?.[i]?.["amount"].toString() !== "0") {
        const since = stakeInfo?.["stakes"]?.[i]?.["since"];
        let typeStaking = i >= 6 ? "diamond" : i >= 3 ? "gold" : "silver";
        const formatedTimeLeft = formatSecond(timeLeftInSeconds(typeStaking, since.toNumber()));

        switch (i) {
          case 0:
            setStakingSlot0(formatedTimeLeft);
            break;
          case 1:
            setStakingSlot1(formatedTimeLeft);
            break;
          case 2:
            setStakingSlot2(formatedTimeLeft);
            break;
          case 3:
            setStakingSlot3(formatedTimeLeft);
            break;
          case 4:
            setStakingSlot4(formatedTimeLeft);
            break;
          case 5:
            setStakingSlot5(formatedTimeLeft);
            break;
          case 6:
            setStakingSlot6(formatedTimeLeft);
            break;
          case 7:
            setStakingSlot7(formatedTimeLeft);
            break;
          case 8:
            setStakingSlot8(formatedTimeLeft);
            break;
          default:
            break;
        }
      }
    }
  }

  async function beforeOpenModal(level, index) {
    const stakeInfo = await props.getStakeInfo();
    const amount = stakeInfo?.["stakes"]?.[index]?.["amount"].toString();
    let timeStaking;
    let indexArray;
    setIndexChoose(index);
    setLevel(level);

    if (level === "silver") {
      timeStaking = "3 months";
      indexArray = index;
    } else if (level === "gold") {
      timeStaking = "6 months";
      indexArray = index + 3;
    } else {
      timeStaking = "9 months";
      indexArray = index + 6;
    }

    if (amount === "0") {
      setModalType("info");
      setModalTitle("Information");
      setModalMessage(
        `You can stake your $RNK for a period of ${timeStaking}.
        It is a soft staking process. In case you withdraw your staked $RNK anytime before the end of the commitment period, you will lose your accumulated rewards.`,
      );
      setModalConfirmation("I understand");
      setModalCancel("Cancel");
    } else if (timeLeftInSeconds(indexArray, stakeInfo?.["stakes"]?.[indexArray]?.["since"]) > 0) {
      setModalType("warning");
      setModalTitle("Information");
      setModalMessage(
        "You are about to withdraw your staking before the countdown ends. After confirmation, you will lose all your accumulated rewards.",
      );
      setModalConfirmation("I still want to withdraw");
      setModalCancel("Cancel");
    }
    setIsModalShow(true);
  }

  function confirmationModal() {
    if (level === "silver") {
      silverStaking(indexChoose);
    } else if (level === "gold") {
      goldStaking(indexChoose);
    } else if (level === "diamond") {
      diamondStaking(indexChoose);
    }
  }

  if (props.connected) {
    refreshStakingSlot();
  }
  return (
    <div className="w-full h-full flex flex-col md:flex-row gap-8 items-center justify-center">
      <div className="text-white"></div>
      <div className=" w-56 flex flex-col text-white font-bold text-center bg-dark-violet rounded-2xl px-4 py-8">
        <p className="font-md silver-text-shadow">Silver Staking</p>
        <img
          alt="Silver Staking"
          src={silver_staking}
          className="mt-4 w-24 mb-6 mx-auto select-none"
        />
        <p>3 months lock</p>
        <p className="text-gray">108% APY</p>
        <div className="mt-8 flex flex-col gap-4">
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("silver", 0)}
            buttonName={stakingSlot0}
            defaultButtonName="Slot 1"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("silver", 1)}
            buttonName={stakingSlot1}
            defaultButtonName="Slot 2"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("silver", 2)}
            buttonName={stakingSlot2}
            defaultButtonName="Slot 3"
          ></StakingButton>
        </div>
      </div>
      <div className=" w-56 flex flex-col text-white font-bold text-center bg-dark-violet rounded-2xl px-4 py-8">
        <p className="font-md gold-text-shadow">Gold Staking</p>
        <img alt="Gold Staking" src={gold_staking} className="mt-4 w-24 mb-6 mx-auto select-none" />
        <p>6 months lock</p>
        <p className="text-yellow">144% APY</p>
        <div className="mt-8 flex flex-col gap-4">
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("gold", 0)}
            buttonName={stakingSlot3}
            defaultButtonName="Slot 1"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("gold", 1)}
            buttonName={stakingSlot4}
            defaultButtonName="Slot 2"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("gold", 2)}
            buttonName={stakingSlot5}
            defaultButtonName="Slot 3"
          ></StakingButton>
        </div>
      </div>
      <div className=" w-56 flex flex-col text-white font-bold text-center bg-dark-violet rounded-2xl px-4 py-8">
        <p className="font-md diamond-text-shadow">Diamond Staking</p>
        <img
          alt="Diamond Staking"
          src={diamond_staking}
          className="mt-4 w-24 mb-6 mx-auto select-none"
        />
        <p>9 months lock</p>
        <p className="text-pink">175.5% APY</p>
        <div className="mt-8 flex flex-col gap-4">
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("diamond", 0)}
            buttonName={stakingSlot6}
            defaultButtonName="Slot 1"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("diamond", 1)}
            buttonName={stakingSlot7}
            defaultButtonName="Slot 2"
          ></StakingButton>
          <StakingButton
            connected={props.connected}
            whenClick={() => beforeOpenModal("diamond", 2)}
            buttonName={stakingSlot8}
            defaultButtonName="Slot 3"
          ></StakingButton>
        </div>
      </div>
      <Modal
        isShow={isModalShow}
        type={modalType}
        title={modalTitle}
        message={modalMessage}
        confirmation={modalConfirmation}
        cancel={modalCancel}
        handleConfirmation={() => confirmationModal()}
        handleClose={() => setIsModalShow(false)}
      ></Modal>
    </div>
  );
}
