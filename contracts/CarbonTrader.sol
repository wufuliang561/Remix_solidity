// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error CarbonTrader_NotOwner();
error CarbonTrader_ParamError();
error CarbonTrader_transferFailed();
contract  CarbonTrader {

    struct Trade {
        address seller; // 卖家地址
        uint256 sellAmount; // 要拍卖的额度
        uint256 startTimeStamp; //拍卖开始时间戳
        uint256 endTimeStamp; // 拍卖结束时间戳
        uint256 minimumBidAmount; // 最少拍卖数量
        uint256 initPriceOfUint; // 每单位的起拍价格
        mapping (address => uint256) deeposits; //买家的押金
        mapping (address => string) bidInfos;
        mapping (address => string) bidSecrets;
    }

    // 发放的碳额度
    mapping (address => uint256) private s_addressToAllowances;
    // 被冻结的碳积分
    mapping (address => uint256) private  s_freezeAllowance;
    // 交易信息
    mapping (string => Trade) private  s_trade;
    // 用户账户金额
    mapping (address => uint256) private s_auctionAmount;

    // 管理员地址,补课修改
    address private  immutable i_owner;
    IERC20 private immutable i_usdt_token;
    constructor (address usdtTokenAddress) {
        i_owner = msg.sender;
        i_usdt_token = IERC20(usdtTokenAddress);
    }
    // 装饰器
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert CarbonTrader_NotOwner();
        }
        _;
    }
    // 给用户发放碳积分
    function issueAllowance(address user,uint256 amount) public onlyOwner {
        s_addressToAllowances[user]+= amount;
    }
    // 查询用户碳积分
    function getAllowance(address user)public view  returns (uint256) {
       return  s_addressToAllowances[user];
    }
    // 冻结碳积分
    function freezeAllowance (address user,uint256 amount) public  onlyOwner {
        s_addressToAllowances[user] -= amount;
        s_freezeAllowance[user] += amount;
    }   

    // 解冻碳积分
    function unFreezeAllowance (address user,uint256 amount) public onlyOwner {
        s_addressToAllowances[user] += amount;
        s_freezeAllowance[user] -= amount;
    }

    // 获取冻结的碳积分
    function getFreezeAllowance(address user) public view  returns (uint256) {
        return s_freezeAllowance[user];
    }

    // 销毁碳积分
    function destroyAllowance(address user, uint256 amount) public onlyOwner {
        s_addressToAllowances[user] -= amount;
    }

    // 销毁全部碳积分
    function destroyAllAllowance(address user) public onlyOwner {
        s_addressToAllowances[user] = 0;
        s_freezeAllowance[user] = 0;
    }

    // 发起拍卖
    function stertTrade (
        string memory tradeId,
        uint256 amount,
        uint256 stratTimeStamp,
        uint256 endTimeStamp,
        uint256 minimumBidAmount,
        uint256 initPriceOfUnit
        
    )public {
        if (
            amount <= 0 ||
            stratTimeStamp >= stratTimeStamp ||
            initPriceOfUnit <= 0 ||
            minimumBidAmount > amount
        ) revert CarbonTrader_ParamError();

        Trade storage newTrade = s_trade[tradeId];
        newTrade.seller = msg.sender;
        newTrade.sellAmount = amount;
        newTrade.startTimeStamp = stratTimeStamp;
        newTrade.endTimeStamp = endTimeStamp;
        newTrade.initPriceOfUint = initPriceOfUnit;
        newTrade.minimumBidAmount = minimumBidAmount;

        // 冻结资产
        s_addressToAllowances[msg.sender] -= amount;
        s_freezeAllowance[msg.sender] += amount;

    }
    // 获取交易
    function getTread (string memory treadId) public view returns (address,uint256,uint256,uint256,uint256,uint256){
        Trade storage curTrade = s_trade[treadId];
        return (
            curTrade.seller,
            curTrade.sellAmount,
            curTrade.startTimeStamp,
            curTrade.endTimeStamp,
            curTrade.initPriceOfUint,
            curTrade.minimumBidAmount
        );
    }
    function deposit(string memory treadId, uint256 amount, string memory info) public {
        Trade storage curTrade = s_trade[treadId];
        bool success = i_usdt_token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert CarbonTrader_transferFailed();
        // 存储质押金额
        curTrade.deeposits[msg.sender] = amount;
        setInfo(treadId, info);

    }
    function refundDeposit(string memory treadId) public {
        Trade storage curTrade = s_trade[treadId];
        uint256 depositAmount = curTrade.deeposits[msg.sender];
        curTrade.deeposits[msg.sender] = 0;
        bool success = i_usdt_token.transfer(msg.sender, depositAmount);
        if (!success) {
            curTrade.deeposits[msg.sender] = depositAmount;
            revert CarbonTrader_transferFailed();
        }

    }

    function setInfo(string memory treadId,string memory info) private {
        Trade storage curTrade = s_trade[treadId];
        curTrade.bidInfos[msg.sender] = info;
    }
     
     function setBidSecret(string memory treadId, string memory secret)public {
        Trade storage curTrade = s_trade[treadId];
        curTrade.bidSecrets[msg.sender] = secret;
     }
     function getBidSecret(string memory treadId) public view returns(string memory) {
        Trade storage curTrade = s_trade[treadId];
        return curTrade.bidSecrets[msg.sender];
     }
    // 结算
    function finalizeAuctionAndTransferCarbon(
        string memory treadId, uint256 allowanceAmount,uint256 addtionalAmountToPay
        ) public {
        Trade storage curTrade = s_trade[treadId];
        // 获取保证金
        uint256 depositAmount = curTrade.deeposits[msg.sender];
        s_trade[treadId].deeposits[msg.sender] = 0;
        s_auctionAmount[curTrade.seller] += depositAmount +addtionalAmountToPay;
        // 扣除卖家碳额度
        s_addressToAllowances[curTrade.seller] -= allowanceAmount;
        // 增加买家碳额度
        s_addressToAllowances[msg.sender] += allowanceAmount;

        // 扣除需要补的钱
         bool success = i_usdt_token.transferFrom(msg.sender, address(this), addtionalAmountToPay);
        if (!success) revert CarbonTrader_transferFailed();


    }
    function withdrawAcutionAmount()public {
        uint256 amount = s_auctionAmount[msg.sender];
        s_auctionAmount[msg.sender] = 0;
         bool success = i_usdt_token.transfer(msg.sender, amount);
        if (!success) {
           s_auctionAmount[msg.sender] = amount;
            revert CarbonTrader_transferFailed();
        }
    }

}