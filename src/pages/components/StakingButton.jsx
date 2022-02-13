import { useState } from "react";

export default function StakingButton(props) {
  const [mouseInIndex, setMouseInIndex] = useState(false);
  function handleMouseEnter() {
    setMouseInIndex(true);
  }
  function handleMouseLeave() {
    setMouseInIndex(false);
  }

  return (
    <button
      onClick={() => props.whenClick(0)}
      onMouseEnter={() => (props.buttonName !== props.defaultButtonName ? handleMouseEnter(0) : "")}
      onMouseLeave={() => (props.buttonName !== props.defaultButtonName ? handleMouseLeave() : "")}
      className={`w-full h-8 rounded text-white font-bold text-base flex items-center justify-center ${
        !props.connected ? "opacity-50" : "opacity-100"
      } ${props.buttonName !== props.defaultButtonName ? "bg-blue" : "bg-pink"}`}
      disabled={!props.connected}
    >
      <span className="material-icons-round text-xl">
        {props.buttonName === props.defaultButtonName || mouseInIndex === true ? "" : "hourglass_top"}
      </span>
      <p>{mouseInIndex === true && props.connected ? "Withdraw" : props.buttonName}</p>
    </button>
  );
}
