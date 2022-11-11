///Developer:lenin.tarrillo.v@gmail.com
///Bio:https://www.linkedin.com/in/lenintv/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//In progress
//is pending: Delete sales order, execute sales order, validate balances.

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

contract CuyOrderBook is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC777 public _PachacuyToken;
    IERC20 public _USDCToken;
    uint256 public orderBookNum = 0;

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

    mapping(address => salesOrder) private salesBook;
    mapping(address => uint256) private blackList;

    address[] private sellers;

    constructor() {
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    //Set PCUY Token Address
    function setPCUYTokenAddress(address pcuyAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _PachacuyToken = IERC777(pcuyAddress);
    }

    //Swap PCUY to USDC
    function placeSellOrder(uint256 _pcuyAmount, uint256 _usdcAmount)
        public
        whenNotPaused
    {
        require(
            _PachacuyToken.isOperatorFor(address(this), _msgSender()),
            "CUY SWAP: Not enough PCUY allowance"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());
        require(
            pcuyBalance >= _pcuyAmount,
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

    //Swap PCUY to USDC
    function removeSellorder() public whenNotPaused {
        salesOrder storage so = salesBook[_msgSender()];
        salesBook[_msgSender()] = salesOrder({
            numID: 0,
            pcuyAmount: 0,
            usdcAmount: 0,
            executed: true
        });

        if (sellers.length > 0) {
            sellers[so.numID - 1] = sellers[sellers.length - 1];
        }
        sellers.pop();
        emit sellOrderremoved(_msgSender());
    }

    function buyOrder(address _seller) public whenNotPaused {
        salesOrder storage so = salesBook[_msgSender()];
        salesBook[_msgSender()] = salesOrder({
            numID: 0,
            pcuyAmount: 0,
            usdcAmount: 0,
            executed: true
        });

        require(
            _PachacuyToken.isOperatorFor(address(this), _msgSender()),
            "CUY SWAP: Not enough PCUY allowance"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(_msgSender());

        if (pcuyBalance <= so.pcuyAmount) {
            blackList[_seller] = blackList[_seller] + 1;
            require(false, "CUY SWAP: The holder no longer has the tokens");
        }

        uint256 usdcAllowance = _USDCToken.allowance(
            _msgSender(),
            address(this)
        );

        require(
            usdcAllowance >= so.usdcAmount,
            "CUY SWAP: Not enough USDC allowance"
        );

        uint256 usdcBalance = _USDCToken.balanceOf(_msgSender());
        require(
            usdcBalance >= so.usdcAmount,
            "CUY SWAP: Not enough USDC balance"
        );

        //enviamos los pCUY

        _PachacuyToken.operatorSend(
            _seller,
            _msgSender(),
            so.pcuyAmount * 1e18,
            "",
            ""
        );

        _USDCToken.transferFrom(_msgSender(), _seller, so.usdcAmount);
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

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
