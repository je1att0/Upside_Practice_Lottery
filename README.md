# 문제 2: Lottery 컨트랙트 구현하기

## 2.1. 전역 변수 및 함수 개요

```solidity
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
```

### 전역 변수

- `hasBought` : 특정 주소가 이미 복권을 구매했는지 여부를 추적하는 `mapping` 변수이다. 각 주소는 한 번만 복권을 구매할 수 있다.
- `guess` : 각 주소가 추측한 숫자를 저장하는 `mapping` 변수이다. 추측한 숫자는 복권의 결과와 비교된다.
- `balance` : 각 주소가 복권 구매에 지불한 금액을 저장하는 `mapping` 변수이다.
- `buyStartTime` : 복권 구매가 시작된 시간을 기록하는 `uint256` 변수이다.
- `buyStarted` : 복권 구매가 시작되었는지 여부를 나타내는 `bool` 변수이다.
- `claimStarted` : 복권 당첨금의 청구가 시작되었는지 여부를 나타내는 `bool` 변수이다.
- `winNumber` : 복권에서 당첨된 숫자를 저장하는 `uint16` 변수이다.

### 함수 개요

- `onlyOnce` : 특정 주소가 복권을 한 번만 구매할 수 있도록 제한하는 `modifier`이다.
- `beforeClaimStart` : 당첨금 청구가 시작되기 전에만 함수를 실행할 수 있도록 제한하는 `modifier`이다.
- `buy(uint16 _guess)` : 특정 주소가 복권을 구매하고, 추측한 숫자를 제출한다.
- `draw()` : 복권의 당첨 숫자를 무작위로 생성한다.
- `winningNumber()` : 복권의 당첨 숫자를 반환한다.
- `claim()` : 복권 당첨자가 당첨금을 청구할 수 있다.
- `receive()` : 컨트랙트가 이더를 받을 수 있도록 하는 함수이다.

## 2.2. `buy(uint16 _guess)`

- 특정 주소가 복권을 구매하고, `_guess`로 제출한 숫자를 기록한다.
- 구매 금액이 정확히 0.1 이더인지 확인한다.
- 복권 구매가 처음 시작되었는지 확인하고, 그렇다면 시작 시간을 기록한다.
- 복권 구매가 24시간 이내에 이루어졌는지 확인한다. 이는 테스트코드 상 sell phase가 24시간동안 일어나기 때문이다.
- 해당 주소의 추측 숫자를 `guess` 매핑에 기록한다.
- 복권 구매가 시작되었음을 기록하고, 당첨금 청구가 시작되지 않았음을 기록한다.
- 해당 주소의 `balance`를 증가시켜 복권 구매 금액을 기록한다.

## 2.3. `draw()`

- 복권 구매가 끝난 후 당첨 숫자를 무작위로 생성한다.
- 구매 단계가 끝났는지 확인하고, 24시간이 경과했는지 확인한다.
- 현재 시간을 기준으로 해시값을 생성하고, 이를 바탕으로 당첨 숫자를 계산하여 `winNumber`에 저장한다.

## 2.4. `winningNumber()`

- 당첨금 청구가 시작되지 않았음을 기록하고, 당첨 숫자를 반환한다.

## 2.5. `claim()`

- 24시간이 지나서 sell phase가 끝났는지 확인한다.
- 제출한 숫자가 당첨 숫자와 일치하면, 해당 주소로 당첨금을 전송한다.
- 해당 주소의 복권 구매 기록을 초기화하고, 당첨금 청구가 시작되었음을 기록한다.
- 복권 구매 상태를 초기화한다.

## 2.6. `receive()`

- 컨트랙트가 이더를 받을 수 있도록 한다.
