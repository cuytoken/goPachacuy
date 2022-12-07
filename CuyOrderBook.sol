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

//SPDX-License-Identifier: MIT
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
        address seller;
        address buyer;
    }

    event sellOrderEstablished(
        address seller,
        uint256 pcuyAmount,
        uint256 usdcAmount
    );

    event sellOrderremoved(uint256 ID);
    event orderCompleted(
        address buyer,
        address seller,
        uint256 pcuyAmount,
        uint256 usdcAmount
    );

    mapping(uint256 => salesOrder) private salesBook;
    mapping(uint256 => salesOrder) private salesBookCompleted;
    mapping(address => uint256) private blackList;
    uint256[] private keyBookPending;

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
            executed: false,
            seller: _msgSender(),
            buyer: address(0)
        });

        keyBookPending.push(orderBookNum);
        salesBook[orderBookNum] = newSalesOrder;

        emit sellOrderEstablished(_msgSender(), _pcuyAmount, _usdcAmount);
    }

    //remove a sell order
    function removeSellorder(uint256 ID) public whenNotPaused {
        require(
            keyBookPending[ID - 1] > 0,
            "CUY SWAP: There is no pending order"
        );
        uint256 IDOrder = keyBookPending[ID - 1];
        _removeSellorder(ID - 1, IDOrder, _msgSender());
        emit sellOrderremoved(ID);
    }

    //Internal fuction - Remove Sell Order
    function _removeSellorder(
        uint256 index,
        uint256 IDOrder,
        address seller
    ) internal {
        salesOrder storage so = salesBook[IDOrder];
        require(so.numID > 0, "CUY SWAP: There is no pending order");
        require(so.seller == seller, "CUY SWAP: Wallet without pending orders");

        keyBookPending[index] = keyBookPending[keyBookPending.length - 1];
        keyBookPending.pop();

        salesBook[IDOrder] = salesOrder({
            numID: 0,
            pcuyAmount: 0,
            usdcAmount: 0,
            executed: true,
            seller: address(0),
            buyer: address(0)
        });
    }

    //Buy an order by ID
    function buyOrder(uint256 ID) public whenNotPaused {
        require(
            keyBookPending[ID - 1] > 0,
            "CUY SWAP: There is no pending order"
        );

        uint256 IDOrder = keyBookPending[ID - 1];

        salesOrder storage so = salesBook[IDOrder];
        require(so.numID > 0, "CUY SWAP: There is no pending order");
        uint256 newPcuy18d = so.pcuyAmount * 1e18;
        uint256 newUSDC6d = so.usdcAmount * 1e6;

        require(
            _PachacuyToken.isOperatorFor(address(this), so.seller),
            "CUY SWAP:The seller has withdrawn permission to sell"
        );

        uint256 pcuyBalance = _PachacuyToken.balanceOf(so.seller);

        if (pcuyBalance < newPcuy18d) {
            blackList[so.seller] = blackList[so.seller] + 1;
            require(false, "CUY SWAP: The seller no longer has the balance");
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

        _PachacuyToken.operatorSend(
            so.seller,
            _msgSender(),
            newPcuy18d,
            "",
            ""
        );

        _USDCToken.transferFrom(_msgSender(), so.seller, newUSDC6d);

        completedOrders = completedOrders + 1;

        salesBookCompleted[completedOrders] = salesOrder({
            numID: completedOrders,
            pcuyAmount: so.pcuyAmount,
            usdcAmount: so.usdcAmount,
            executed: true,
            seller: so.seller,
            buyer: _msgSender()
        });
        _removeSellorder(ID - 1, IDOrder, so.seller);

        emit orderCompleted(
            _msgSender(),
            salesBookCompleted[completedOrders].seller,
            salesBookCompleted[completedOrders].pcuyAmount,
            salesBookCompleted[completedOrders].usdcAmount
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

    //List Sales Order By Wallet
    function listSalesOrderByWallet(address seller)
        external
        view
        returns (
            uint256[] memory _keyOrders,
            uint256[] memory _pcuysAmounts,
            uint256[] memory _usdcAmounts,
            bool[] memory _executeds
        )
    {
        uint256 index = keyBookPending.length;
        uint256 s;

        uint256[] memory aux_pcuysAmounts = new uint256[](
            keyBookPending.length
        );
        uint256[] memory aux_keyOrders = new uint256[](keyBookPending.length);
        uint256[] memory aux_usdcAmounts = new uint256[](keyBookPending.length);
        bool[] memory aux_executeds = new bool[](keyBookPending.length);

        for (s = 0; s < index; s++) {
            salesOrder storage so = salesBook[keyBookPending[s]];
            if (so.seller == seller) {
                aux_keyOrders[s] = s + 1;
                aux_pcuysAmounts[s] = so.pcuyAmount;
                aux_usdcAmounts[s] = so.usdcAmount;
                aux_executeds[s] = so.executed;
            }
        }

        _keyOrders = aux_keyOrders;
        _pcuysAmounts = aux_pcuysAmounts;
        _usdcAmounts = aux_usdcAmounts;
        _executeds = aux_executeds;
    }

    function listSalesOrderCompleted()
        external
        view
        returns (
            uint256[] memory _keyOrders,
            uint256[] memory _pcuysAmounts,
            uint256[] memory _usdcAmounts,
            address[] memory _buyers,
            address[] memory _sellers
        )
    {
        uint256[] memory aux_pcuysAmounts = new uint256[](completedOrders);
        uint256[] memory aux_usdcAmounts = new uint256[](completedOrders);
        address[] memory aux_buyers = new address[](completedOrders);
        address[] memory aux_sellers = new address[](completedOrders);
        uint256[] memory aux_keyOrders = new uint256[](completedOrders);

        uint256 index = completedOrders;
        uint256 s;

        for (s = 1; s <= index; s++) {
            salesOrder storage so = salesBookCompleted[s];
            aux_keyOrders[s - 1] = so.numID;
            aux_pcuysAmounts[s - 1] = so.pcuyAmount;
            aux_usdcAmounts[s - 1] = so.usdcAmount;
            aux_buyers[s - 1] = so.buyer;
            aux_sellers[s - 1] = so.seller;
        }

        _keyOrders = aux_keyOrders;
        _pcuysAmounts = aux_pcuysAmounts;
        _usdcAmounts = aux_usdcAmounts;
        _buyers = aux_buyers;
        _sellers = aux_sellers;
    }

    function listSalesOrderPending()
        external
        view
        returns (
            uint256[] memory _keyOrders,
            address[] memory _sellers,
            uint256[] memory _pcuysAmounts,
            uint256[] memory _usdcAmounts
        )
    {
        uint256 index = keyBookPending.length;
        uint256 s;

        uint256[] memory aux_pcuysAmounts = new uint256[](
            keyBookPending.length
        );
        uint256[] memory aux_keyOrders = new uint256[](keyBookPending.length);
        uint256[] memory aux_usdcAmounts = new uint256[](keyBookPending.length);
        address[] memory aux_sellers = new address[](keyBookPending.length);

        for (s = 0; s < index; s++) {
            salesOrder storage so = salesBook[keyBookPending[s]];
            aux_keyOrders[s] = s + 1;
            aux_pcuysAmounts[s] = so.pcuyAmount;
            aux_usdcAmounts[s] = so.usdcAmount;
            aux_sellers[s] = so.seller;
        }

        _keyOrders = aux_keyOrders;
        _sellers = aux_sellers;
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

    function orderPending() public view returns (uint256) {
        return keyBookPending.length;
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
