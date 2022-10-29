/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////██╗░░░██╗░██████╗██████╗░░█████╗░  ███████╗░█████╗░██████╗░  ████████╗███████╗░██████╗████████╗/////////////
/////////██║░░░██║██╔════╝██╔══██╗██╔══██╗  ██╔════╝██╔══██╗██╔══██╗  ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝/////////////
/////////██║░░░██║╚█████╗░██║░░██║██║░░╚═╝  █████╗░░██║░░██║██████╔╝  ░░░██║░░░█████╗░░╚█████╗░░░░██║░░░/////////////
/////////██║░░░██║░╚═══██╗██║░░██║██║░░██╗  ██╔══╝░░██║░░██║██╔══██╗  ░░░██║░░░██╔══╝░░░╚═══██╗░░░██║░░░/////////////
/////////╚██████╔╝██████╔╝██████╔╝╚█████╔╝  ██║░░░░░╚█████╔╝██║░░██║  ░░░██║░░░███████╗██████╔╝░░░██║░░░/////////////
/////////░╚═════╝░╚═════╝░╚═════╝░░╚════╝░  ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝  ░░░╚═╝░░░╚══════╝╚═════╝░░░░╚═╝░░░/////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////GOPACHACUY CONTRACTS//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////This contract simulates the USDC token to be used within the SWAP tests.///////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Developer:lenin.tarrillo.v@gmail.com
//Bio:https://www.linkedin.com/in/lenintv/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCFAKE is ERC20 {
    constructor() ERC20("USDCFAKE", "USDC") {
        _mint(msg.sender, 100 * 1e6 * 1e6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

}
