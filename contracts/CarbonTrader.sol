// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
error CarbonTrader_NotOwner();
error CarbonTrader_ParamError();
contract  CarbonTrader {

    struct treade {
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
    mapping (string => treade) private  s_trade;

    // 管理员地址,补课修改
    address private  immutable i_owner;
    constructor () {
        i_owner = msg.sender;
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

        treade storage newTrade = s_trade[tradeId];
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



}