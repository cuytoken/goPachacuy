////////////////////////////////////////////////////////////////////////////////////////////////
////////////////░█████╗░██╗░░░██╗██╗░░░██╗  ░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░//////////////
////////////////██╔══██╗██║░░░██║╚██╗░██╔╝  ██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗//////////////
////////////////██║░░╚═╝██║░░░██║░╚████╔╝░  ╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝//////////////
////////////////██║░░██╗██║░░░██║░░╚██╔╝░░  ░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░//////////////
////////////////╚█████╔╝╚██████╔╝░░░██║░░░  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░//////////////
////////////////░╚════╝░░╚═════╝░░░░╚═╝░░░  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░//////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////Pachacuy Ecosystem Swap////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
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
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

contract PachacuySwap is
    AccessControl,
    Pausable,
    IERC777Sender,
    IERC777Recipient
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private _swapPercentageUSDCtoPcuy = 2500 * 1e18; //%
    uint256 private _swapPercentagePCUYtoUSDC = 35 * 1e5; //%
    uint256 private _totalUSDCswap;
    uint256 private _totalPCUYswap;

    IERC777 public _PachacuyToken;
    IERC20 public _USDCToken;

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

    event TokenPcuySwap(address Swaper, uint256 usdcAmount, uint256 TokenSwap);

    event TokenUSDCSwap(address Swaper, uint256 pcuyAmount, uint256 TokenSwap);

    mapping(address => uint256) public playersAuthorized;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    IERC1820Registry private _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor() {
        _setupRole(ADMIN_ROLE, _msgSender());
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_SENDER_INTERFACE_HASH,
            address(this)
        );
    }

    function totalUSDCswap() public view returns (uint256) {
        return _totalUSDCswap;
    }

    function totalPCUYswap() public view returns (uint256) {
        return _totalPCUYswap;
    }

    function USDC_to_Receive(uint256 amount) public view returns (uint256) {
       
        uint256 tokenToTransfer = Math.mulDiv(
            amount,
            _swapPercentagePCUYtoUSDC,
            100 * 1e6
        );
         return tokenToTransfer;

    }

    

    //Get the number of tokens authorized to exchange
    function getAuthorizedPCUY(address player) public view returns (uint256) {
        return playersAuthorized[player];
    }

    //SWAP PCUY to USDC
    function swapUSDC_To_PCUY(uint256 _usdcAmount) public whenNotPaused {
        uint256 usdcAllowance = _USDCToken.allowance(
            _msgSender(),
            address(this)
        );

        require(
            usdcAllowance >= _usdcAmount,
            "CUY SWAP: Not enough USDC allowance"
        );
        uint256 usdcBalance = _USDCToken.balanceOf(_msgSender());
        require(
            usdcBalance >= _usdcAmount,
            "CUY SWAP: Not enough USDC balance"
        );
        bool success = _USDCToken.transferFrom(
            _msgSender(),
            address(this),
            _usdcAmount
        );
        require(success, "CUY SWAP: Failed to transfer USDC");
        _totalUSDCswap += _usdcAmount;

        uint256 tokenToTransfer = Math.mulDiv(
            _usdcAmount,
            _swapPercentageUSDCtoPcuy,
            100 * 1e18
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(address(this));
        require(
            pcuyBalance >= tokenToTransfer,
            "CUY SWAP: Not enough token to Swap"
        );
        _PachacuyToken.send(_msgSender(), tokenToTransfer, "");
        _totalPCUYswap += tokenToTransfer;

        playersAuthorized[_msgSender()] = tokenToTransfer;

        emit TokenPcuySwap(_msgSender(), _usdcAmount, tokenToTransfer);
    }

    //Swap PCUY to USDC
    function swapPCUY_To_USDC(uint256 _pcuyAmount) public whenNotPaused {
        uint256 pcuyAutorized = playersAuthorized[_msgSender()];

        require(
            pcuyAutorized >= _pcuyAmount,
            "CUY SWAP:Unauthorized amount of tokens"
        );

        require(
            _PachacuyToken.isOperatorFor(address(this), _msgSender()),
            "CUY SWAP: Not enough PCUY allowance"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());
        require(
            pcuyBalance >= _pcuyAmount,
            "CUY SWAP: Not enough PCUY balance"
        );

        _PachacuyToken.operatorSend(
            _msgSender(),
            address(this),
            _pcuyAmount,
            "",
            ""
        );

        _totalPCUYswap += _pcuyAmount;
        uint256 tokenToTransfer = Math.mulDiv(
            _pcuyAmount,
            _swapPercentagePCUYtoUSDC,
            100 * 1e6
        );
        uint256 usdcBalance = _USDCToken.balanceOf(address(this));
        require(
            usdcBalance >= tokenToTransfer,
            "CUY SWAP: Not enough token to Swap"
        );
        _USDCToken.transfer(_msgSender(), tokenToTransfer);
        _totalUSDCswap += tokenToTransfer;

        playersAuthorized[_msgSender()] = pcuyAutorized - _pcuyAmount;
        emit TokenUSDCSwap(_msgSender(), _pcuyAmount, tokenToTransfer);
    }

    //ADMIN FUNCTIONS

    //Load authorized players to claim liquidity
    function uploadAuthorizedPlayers(
        address[] memory players,
        uint256[] memory amounts
    ) external onlyRole(ADMIN_ROLE) {
        uint256 l = players.length;
        for (uint256 i = 0; i < l; ++i) {
            playersAuthorized[players[i]] = amounts[i];
        }
    }

    //authorize a player
    function setAuthorizedPlayer(address player, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        playersAuthorized[player] = amount;
    }

    //extracts the entire PCUY balance from the SWAP
    function getAllBalancePCUY() public onlyRole(ADMIN_ROLE) {
        uint256 pcuyBalance = _PachacuyToken.balanceOf(address(this));
        _PachacuyToken.send(_msgSender(), pcuyBalance, "");
    }

    //extracts the entire PCUY balance from the SWAP
    function getAllBalanceUSDC() public onlyRole(ADMIN_ROLE) {
        uint256 usdcBalance = _USDCToken.balanceOf(address(this));
        _USDCToken.transfer(_msgSender(), usdcBalance);
    }

    //Set PCUY Token Address
    function setPCUYTokenAddress(address pcuyAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _PachacuyToken = IERC777(pcuyAddress);
    }

    //Set USDC Token Address
    function setUSDCTokenAddress(address uSDCTokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _USDCToken = IERC20(uSDCTokenAddress);
    }

    function swapPercentageUSDCtoPcuy(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        _swapPercentageUSDCtoPcuy = amount;
    }

    function swapPercentagePCUYtoUSDC(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        _swapPercentagePCUYtoUSDC = amount;
    }

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
