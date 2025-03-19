// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Demo {
    mapping (string => uint) public m ;

    function getm(string memory key) public view returns (uint){
        return m[key];
    }

}