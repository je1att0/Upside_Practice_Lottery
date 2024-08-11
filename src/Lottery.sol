// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract Lottery {
    mapping(address => bool) private hasBought;
    mapping(address => uint16) guess;
    mapping(address => uint256) public balance;
    uint256 buyStartTime;
    bool buyStarted;
    bool claimStarted;
    uint16 winNumber;

    modifier onlyOnce() {
        require(!hasBought[msg.sender], "Lottery already bought");
        hasBought[msg.sender] = true;
        _;
    }

    modifier beforeClaimStart() {
        require(!claimStarted, "Already claimed");
        _;
    }

    function buy(uint16 _guess) public onlyOnce payable {
        require(msg.value == 0.1 ether, "Incorrect value");
        if (!buyStarted){ 
            buyStartTime = block.timestamp;
        }
        require(block.timestamp < buyStartTime + 24 hours, "Sell phase ended");
        guess[msg.sender] = _guess;
        buyStarted = true;
        claimStarted = false;
        balance[msg.sender] += msg.value;
    }

    function draw() public beforeClaimStart {
        require(block.timestamp >= buyStartTime + 24 hours, "No draw: Sell phase not ended");
        uint256 hash = uint256(keccak256(abi.encodePacked(block.timestamp)));
        winNumber = uint16(hash % 2**16);
    }

    function winningNumber() public returns (uint16) {
        claimStarted = false;
        return winNumber;
    }

    function claim() public payable {
        require(block.timestamp >= buyStartTime + 24 hours, "No claim: Sell phase not ended");
        if (winNumber == guess[msg.sender]) {
            (bool success, ) = payable(msg.sender).call{value: balance[msg.sender]}("");
            require(success, "Claim failed");
        }
        hasBought[msg.sender] = false;
        claimStarted = true;
        buyStarted = false;
    }

    receive() external payable {

    }
}