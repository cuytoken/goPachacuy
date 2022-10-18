
////██████╗░░█████╗░░█████╗░██╗░░██╗░█████╗░░█████╗░██╗░░░██╗██╗░░░██╗  ████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗////
////██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔══██╗██║░░░██║╚██╗░██╔╝  ╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║////
////██████╔╝███████║██║░░╚═╝███████║███████║██║░░╚═╝██║░░░██║░╚████╔╝░  ░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║////
////██╔═══╝░██╔══██║██║░░██╗██╔══██║██╔══██║██║░░██╗██║░░░██║░░╚██╔╝░░  ░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║////
////██║░░░░░██║░░██║╚█████╔╝██║░░██║██║░░██║╚█████╔╝╚██████╔╝░░░██║░░░  ░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║////
////╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░░╚═════╝░░░░╚═╝░░░  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////Tokenized gaming ecosystem/////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Developer:lenin.tarrillo.v@gmail.com
///Bio:https://www.linkedin.com/in/lenintv/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

/// @custom:security-contact lee@pachacuy.com
contract PachaCuyToken is ERC777, IERC777Sender, IERC777Recipient {
    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensSent(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );


        address[]  defaultOperators_;

    constructor(
        
    ) ERC777("Pachacuy", "PCUY", defaultOperators_) {
        ///Tokenomics implementation pending
        _mint(msg.sender, 100 * 1e6 * 1e18, "", "");
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensSent(operator, from, to, amount, userData, operatorData);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}