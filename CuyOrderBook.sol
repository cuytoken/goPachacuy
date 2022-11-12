////////////////////////////////////////////////////////////////////////////////////////////////
//////////////░█████╗░██████╗░██████╗░███████╗██████╗░  ██████╗░░█████╗░░█████╗░██╗░░██╗////////
//////////////██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝////////
//////////////██║░░██║██████╔╝██║░░██║█████╗░░██████╔╝  ██████╦╝██║░░██║██║░░██║█████═╝░////////
//////////////██║░░██║██╔══██╗██║░░██║██╔══╝░░██╔══██╗  ██╔══██╗██║░░██║██║░░██║██╔═██╗░////////
//////////////╚█████╔╝██║░░██║██████╔╝███████╗██║░░██║  ██████╦╝╚█████╔╝╚█████╔╝██║░╚██╗////////
//////////////░╚════╝░╚═╝░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝  ╚═════╝░░╚════╝░░╚════╝░╚═╝░░╚═╝////////
/////////////////////////////////////////////////////////////////////////////////////////////////
////////////Allows Pachacuy holders to establish sales orders for their tokens///////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

///Developer:lenin.tarrillo.v@gmail.com
///Bio:https://www.linkedin.com/in/lenintv/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract CuyOrderBook is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC777 public _PachacuyToken;
    IERC20 public _USDCToken;
    uint256 public orderBookNum = 0;
    uint256 public completedOrders = 0;

    struct salesOrder {
        uint256 numID;
        uint256 pcuyAmount;
        uint256 usdcAmount;
        bool executed;
    }

    event sellOrderEstablished(
        address seller,
        uint256 pcuyAmount,
        uint256 usdcAmount
    );

    event sellOrderremoved(address seller);
    event orderCompleted(
        address buyer,
        address seller,
        uint256 pcuyAmount,
        uint256 usdcAmount
    );

    mapping(address => salesOrder) private salesBook;
    mapping(address => uint256) private blackList;

    address[] private sellers;

    constructor(address pachacuyToken, address usdcToken) {
        _setupRole(ADMIN_ROLE, _msgSender());
        _PachacuyToken = IERC777(pachacuyToken);
        _USDCToken = IERC20(usdcToken);
    }

    //set up a sell order
    function setSellOrder(uint256 _pcuyAmount, uint256 _usdcAmount)
        public
        whenNotPaused
    {
        uint256 _newpcuyAmount = _pcuyAmount * 1e18;

        require(
            blackList[_msgSender()] <= 1,
            "CUY SWAP:Wallet blacklisted for unsuccessful attempts to sell"
        );

        require(
            _PachacuyToken.isOperatorFor(address(this), _msgSender()),
            "CUY SWAP: Not enough PCUY allowance"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());
        require(
            pcuyBalance >= _newpcuyAmount,
            "CUY SWAP: Not enough PCUY balance"
        );

        orderBookNum = orderBookNum + 1;

        salesOrder memory newSalesOrder = salesOrder({
            numID: orderBookNum,
            pcuyAmount: _pcuyAmount,
            usdcAmount: _usdcAmount,
            executed: false
        });

        salesBook[_msgSender()] = newSalesOrder;

        sellers.push(_msgSender());

        emit sellOrderEstablished(_msgSender(), _pcuyAmount, _usdcAmount);
    }

    //remove a sell order
    function removeSellorder() public whenNotPaused {
        _removeSellorder(_msgSender());

        emit sellOrderremoved(_msgSender());
    }

    //Swap PCUY to USDC
    function _removeSellorder(address _seller) internal {
        salesOrder storage so = salesBook[_seller];
        salesBook[_seller] = salesOrder({
            numID: 0,
            pcuyAmount: 0,
            usdcAmount: 0,
            executed: true
        });

        if (sellers.length > 0) {
            sellers[so.numID - 1] = sellers[sellers.length - 1];
            orderBookNum = orderBookNum - 1;
            sellers.pop();
        }
    }

    //Buy an order (100%)
    function buyOrder(address _seller) public whenNotPaused {
        salesOrder storage so = salesBook[_msgSender()];

        uint256 newPcuy18d = so.pcuyAmount * 1e18;
        uint256 newUSDC6d = so.usdcAmount * 1e6;

        require(
            _PachacuyToken.isOperatorFor(address(this), _msgSender()),
            "CUY SWAP: Not enough PCUY allowance"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());

        if (pcuyBalance < newPcuy18d) {
            blackList[_seller] = blackList[_seller] + 1;
            require(false, "CUY SWAP: The holder no longer has the tokens");
        }

        uint256 usdcAllowance = _USDCToken.allowance(
            _msgSender(),
            address(this)
        );

        require(
            usdcAllowance >= newUSDC6d,
            "CUY SWAP: Not enough USDC allowance"
        );

        uint256 usdcBalance = _USDCToken.balanceOf(_msgSender());
        require(usdcBalance >= newUSDC6d, "CUY SWAP: Not enough USDC balance");

        _PachacuyToken.operatorSend(_seller, _msgSender(), newPcuy18d, "", "");

        _USDCToken.transferFrom(_msgSender(), _seller, newUSDC6d);

        _removeSellorder(_seller);

        completedOrders = completedOrders + 1;

        emit orderCompleted(
            _msgSender(),
            _seller,
            so.pcuyAmount,
            so.usdcAmount
        );
    }


    function setPCUYTokenAddress(address pcuyAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _PachacuyToken = IERC777(pcuyAddress);
    }

    function setUSDCTokenAddress(address uSDCTokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _USDCToken = IERC20(uSDCTokenAddress);
    }

    function removeBlacklist(address seller)
        public
        whenNotPaused
        onlyRole(ADMIN_ROLE)
    {
        blackList[seller] = 0;
    }

    function listSalesOrder()
        external
        view
        returns (
            address[] memory _sellers,
            uint256[] memory _pcuysAmounts,
            uint256[] memory _usdcAmounts
        )
    {
        uint256[] memory aux_pcuysAmounts = new uint256[](sellers.length);
        uint256[] memory aux_usdcAmounts = new uint256[](sellers.length);

        uint256 index = sellers.length;
        uint256 s;

        for (s = 0; s < index; s++) {
            salesOrder storage so = salesBook[sellers[s]];

            if (so.executed == false) {
                aux_pcuysAmounts[s] = so.pcuyAmount;
                aux_usdcAmounts[s] = so.usdcAmount;
            }
        }

        _sellers = sellers;
        _pcuysAmounts = aux_pcuysAmounts;
        _usdcAmounts = aux_usdcAmounts;
    }

    function copyright() public view virtual returns (string memory) {
        return "PACHACUY WEB3 SERVICES";
    }

    function name() public view virtual returns (string memory) {
        return "CUY SWAP: ORDER BOOK";
    }

    function symbol() public view virtual returns (string memory) {
        return "CUY";
    }

    function isBlackList(address seller) public view returns (uint256) {
        return blackList[seller];
    }

    function numSellers() public view returns (uint256) {
        return sellers.length;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
