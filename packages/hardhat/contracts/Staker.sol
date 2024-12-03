// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 0.2 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  bool public executionDone = false;

  modifier notCompleted() {
    require(!executionDone, "Los fondos ya han sido enviados, no se pueden realizar mas acciones.");
    _;
    }



  event Stake(address,uint256);
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

function stake() public payable {
    require(block.timestamp < deadline, "El plazo para stake ha pasado.");
    require(!executionDone, "No se pueden realizar mas stakes despues de ejecutar el contrato.");
    require (msg.value > 0, "Debe enviar algo de Eth");

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);        
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

function execute() public notCompleted {
    if (address(this).balance >= threshold) {
        exampleExternalContract.complete{value: address(this).balance}();
        executionDone = true;
    } else if (block.timestamp >= deadline) {
        openForWithdraw = true;
    } else {
        revert("El umbral no se ha alcanzado y el deadline aun no ha pasado.");
    }
}



function withdraw() public notCompleted {
    require(openForWithdraw, "Los retiros no estan habilitados.");
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "No tienes fondos para retirar.");
    
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(userBalance);
}


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
        return 0;
    } else {
        return deadline - block.timestamp;
    }
}


  // Add the `receive()` special function that receives eth and calls stake()

// Función que recibe ETH y actualiza el balance llamando a `stake()`
receive() external payable {
    stake();
}
  

}
