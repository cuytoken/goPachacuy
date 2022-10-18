//////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////██████╗░░█████╗░░█████╗░██╗░░██╗░█████╗░░░░░░░░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░//////////////////
////////██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔══██╗░░░░░░██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗//////////////////
////////██████╔╝███████║██║░░╚═╝███████║███████║█████╗╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝//////////////////
////////██╔═══╝░██╔══██║██║░░██╗██╔══██║██╔══██║╚════╝░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░//////////////////
////////██║░░░░░██║░░██║╚█████╔╝██║░░██║██║░░██║░░░░░░██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░//////////////////
////////╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░//////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////Pachacuy Ecosystem Swap/////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Developer:lenin.tarrillo.v@gmail.com
///Bio:https://www.linkedin.com/in/lenintv/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PachacuySwap is
    AccessControl,
    Pausable,
    IERC777Sender,
    IERC777Recipient
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    IERC777 public _PachacuyToken;
    IERC20 public _USDCToken;

    uint256 private _swapRateUSDCtoPcuy;
    uint256 private _swapRatePCUYtoUSDC;
    

    uint256 private _totalUsdcSwap;
    uint256 private _totalPcuySwap;

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

    event TokenPcuySwap(
        address Swaper,
        uint256 usdcAmount,
        uint256 TokenSwap
    );

    event TokenUSDCSwap(
        address Swaper,
        uint256 pcuyAmount,
        uint256 TokenSwap
    );
    


    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");
        

    constructor(address admin) {
       
        _setupRole(ADMIN_ROLE, admin);
    }

    function totalUsdcSwap() public view returns (uint256) {
        return _totalUsdcSwap;
    }

    function totalPcuySwap() public view returns (uint256) {
        return _totalPcuySwap;
    }

    

    /**
     * @dev Lenin Tarrillo
     * SWAP PCUY to USDC
     */
    function swapUSDC_To_PCUY(uint256 _usdcAmount) public whenNotPaused {
        
        // verify if approved
        uint256 usdcAllowance = _USDCToken.allowance(
            _msgSender(),
            address(this)
        );
        
        require(
            usdcAllowance >= _usdcAmount,
            "Pachacuy SWAP: Not enough USDC allowance"
        );

        // verify usdc balance
        uint256 usdcBalance = _USDCToken.balanceOf(_msgSender());
        require(
            usdcBalance >= _usdcAmount,
            "Pachacuy SWAP: Not enough USDC balance"
        );

        // transfer usdc to funds wallet
        bool success = _USDCToken.transferFrom(
            _msgSender(),
            address(this),
            _usdcAmount
        );
        require(success, "Pachacuy Swap: Failed to transfer USDC");
        _totalUsdcSwap += _usdcAmount;

        // total PCUY to transfer
        uint256 tokenToTransfer = _usdcAmount * _swapRateUSDCtoPcuy;

        // verify PCUY balance
        uint256 pcuyBalance = _PachacuyToken.balanceOf(address(this));
        require(
            pcuyBalance >= tokenToTransfer,
            "Pachacuy Swap: Not enough token to Swap"
        );

        // transfer BW3Token to customer
        _PachacuyToken.send(_msgSender(), tokenToTransfer, "");
        _totalPcuySwap += tokenToTransfer;

        emit TokenPcuySwap(_msgSender(), _usdcAmount, tokenToTransfer);
    }





    /**
     * @dev Lenin Tarrillo
     * SWAP PCUY to PCUY
     */
    function swapPCUY_To_USDC(uint256 _pcuyAmount) public whenNotPaused {
        
       
        
        require(
            _PachacuyToken.isOperatorFor( address(this),_msgSender()),
            "Pachacuy SWAP: Not enough PCUY allowance"
        );

        // verify usdc balance
        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());
        require(
            pcuyBalance >= _pcuyAmount,
            "Pachacuy SWAP: Not enough PCUY balance"
        );

        // transfer usdc to funds wallet
        _PachacuyToken.operatorSend(
            _msgSender(),
            address(this),
            _pcuyAmount, 
            "",
            ""
        );

      
        _totalPcuySwap += _pcuyAmount;

        // total PCUY to transfer
        uint256 tokenToTransfer = _pcuyAmount * _swapRateUSDCtoPcuy;

        // verify PCUY balance
        uint256 usdcBalance = _USDCToken.balanceOf(address(this));
        require(
            usdcBalance >= tokenToTransfer,
            "Pachacuy Swap: Not enough token to Swap"
        );

        // transfer BW3Token to customer
        _USDCToken.transfer(_msgSender(), tokenToTransfer);
        _totalUsdcSwap += tokenToTransfer;

        emit TokenUSDCSwap(_msgSender(), _pcuyAmount, tokenToTransfer);
    }


    ////

    function setPCUYaddress(address pcuyAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _PachacuyToken = IERC777(pcuyAddress);
    }

    function setUsdcTokenAddress(address uSDCTokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _USDCToken = IERC20(uSDCTokenAddress);
    }

    function swapRateUSDCtoPcuy(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        _swapRateUSDCtoPcuy = amount;
    }

    function swapRatePCUYtoUSDC(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        _swapRatePCUYtoUSDC = amount;
    }



    ////STARDART FUNCTIONS

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
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

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}