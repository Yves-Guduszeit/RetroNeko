import {NavLink} from "react-router-dom";
import logo from "../assets/img/logo.png";

export default function Header(props) {

    return (
        <header
            className="pt-2 xl:pt-6 2xl:pt-8 mb-4 2xl:mb-16 md:mx-16 flex flex-col md:flex-row gap-8 md:gap-0 justify-between items-center text-white">
            <a href="https://retroneko.com" className="flex flex-row gap-4 items-center">
                <img alt="Fuckinou" src={logo} className="w-20 xl:w-28"/>
                <p className="font-bold text-xl rowdies">RETRO NEKO</p>
            </a>
            <div>
                <ul className="text-lg font-medium flex flex-row gap-4">
                    <li>
                        <NavLink
                            to="/"
                            style={({isActive}) => isActive ? {textUnderlineOffset: "8px", textDecoration: "underline"} : {}}
                        >
                            Dashboard
                        </NavLink>
                    </li>
                    <li>
                        <NavLink
                            to="/staking"
                            style={({isActive}) => isActive ? {textUnderlineOffset: "8px", textDecoration: "underline"} : {}}
                        >
                            Staking
                        </NavLink>
                    </li>
                    <li>
                        <p
                            className="cursor-pointer"
                        >
                            NFT APY (Comming soon)
                        </p>
                    </li>
                </ul>
            </div>
            <div className="hidden lg:block text-xl rowdies text-white font-medium">
                <button onClick={props.connectWalletHandler} className="flex flex-row items-center gap-2">
                    <span className="material-icons-round">account_balance_wallet</span>
                    <p>{props.connectionButtonText}</p>
                </button>
            </div>
        </header>
    );
}
