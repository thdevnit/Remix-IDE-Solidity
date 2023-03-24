// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract myDetails {
    uint256 private age;

    function setDetails(string memory _age) public {
        age = _age;
    }

    function getAge() public view returns (string memory) {
        return age;
    }
}
