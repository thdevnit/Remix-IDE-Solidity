// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract myDetails {
    string private name;

    function setDetails(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}
