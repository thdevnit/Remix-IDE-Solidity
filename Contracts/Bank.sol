//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

/* Errors */

error Bank__AccountAlreadyOpened();
error Bank__OpenAccount();
error Bank_AlreadyLoanTaken();
error Bank__notEligibleForInterest();

/**    @title A sample Bank Contract
       @author Nitesh Singh
       @notice This contract is for creating a sample Bank Contract
       @dev This implements the ReentrancyGuard smart contract from Openzeppelin
   */

contract Bank is ReentrancyGuard {
    /* Type Declarations */

    struct accountDetails {
        string name;
        string add;
        address accountNumber;
        uint256 balance;
        uint256 interestAmount;
        uint256 loanAmount;
    }

    /* State Variables */

    address private immutable i_owner;
    uint256 private noOfAccounts;
    uint256 private accountOpeningTime;
    uint256 private constant MINTIME_TOGETLOAN = 60;
    address[] private listOfAccounts;
    uint256 private totalLoanGiven;
    uint256 private totalLoanAmount;
    uint256 private availableLoanAmount;
    uint256 private loanTime;
    uint256 private depositeTimeStamp;
    mapping(address => accountDetails) private accounts;

    /* Events */

    event accountOpen(string indexed name, address indexed accounNumber);
    event withdrawl(uint256 indexed _amount);
    event transferDetail(uint256 indexed _amount, address indexed _accountNumber);
    event loanDetails(uint256 indexed loanAmount, uint256 indexed loanTime);
    event loanPaid(uint256 loanAmount);
    event AccountClosed(address accountNumber);
    event DepositeAmount(uint256 indexed depositAmount);

    /* Functions */

    constructor() {
        i_owner = msg.sender;
        totalLoanGiven = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "You are not an owner");
        _;
    }

    modifier isAlreadyOpened() {
        if (accounts[msg.sender].accountNumber == msg.sender) {
            revert Bank__AccountAlreadyOpened();
        }
        _;
    }

    modifier isAccountAvailable() {
        if (accounts[msg.sender].accountNumber != msg.sender) {
            revert Bank__OpenAccount();
        }
        _;
    }

    modifier isAnyLoanBefore() {
        if (accounts[msg.sender].loanAmount != 0) {
            revert Bank_AlreadyLoanTaken();
        }
        _;
    }

    function openAccount(string memory _name, string memory _add) public isAlreadyOpened {
        accounts[msg.sender].name = _name;
        accounts[msg.sender].add = _add;
        accounts[msg.sender].accountNumber = msg.sender;
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].loanAmount = 0;
        accounts[msg.sender].interestAmount = 0;
        noOfAccounts++;
        listOfAccounts.push(msg.sender);
        accountOpeningTime = block.timestamp;
        // Emit an event when anybody opens account
        emit accountOpen(_name, msg.sender);
    }

    function deposit() public payable isAccountAvailable {
        assert(msg.value > 0);
        accounts[msg.sender].balance += msg.value;
        totalLoanAmount = (address(this).balance * 2) / 5;
        availableLoanAmount = totalLoanAmount - totalLoanGiven;
        depositeTimeStamp = block.timestamp;
        emit DepositeAmount(msg.value);
    }

    function withdraw(uint256 _amount) public isAccountAvailable nonReentrant {
        require(_amount != 0, "Can't transfer 0 amount");
        require(
            _amount <= accounts[msg.sender].balance,
            "You don't have enough funds in your account"
        );
        accounts[msg.sender].balance -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdraw Failed");
        totalLoanAmount = (address(this).balance * 2) / 5;
        availableLoanAmount = totalLoanAmount - totalLoanGiven;

        emit withdrawl(_amount);
    }

    function transfer(uint256 _amount, address _accountNumber) public isAccountAvailable {
        require(_amount != 0, "Can't transfer 0 amount");
        require(_accountNumber != address(0), "Need Valid account number to transfer");
        require(accounts[msg.sender].balance > 0, "You need to deposite amount before transfer");
        require(_amount <= accounts[msg.sender].balance, "You need some more balance");
        require(
            accounts[_accountNumber].accountNumber == _accountNumber,
            "Receipent need to create account first"
        );
        require(_accountNumber != msg.sender, "You can't transfer to yourself");
        accounts[msg.sender].balance -= _amount;
        accounts[_accountNumber].balance += _amount;

        emit transferDetail(_amount, _accountNumber);
    }

    function getLoan() public isAccountAvailable isAnyLoanBefore {
        uint256 loanAmount = (accounts[msg.sender].balance * 1) / 2;
        require(
            block.timestamp > accountOpeningTime + MINTIME_TOGETLOAN,
            "Your account is not old enough to get Loan"
        );
        require(availableLoanAmount > loanAmount, "Bank has not enough fund");
        require(accounts[msg.sender].balance >= 5 ether, "You don't have enough funds to get Loan");
        accounts[msg.sender].balance += loanAmount;
        accounts[msg.sender].loanAmount += loanAmount;
        totalLoanGiven += loanAmount;
        availableLoanAmount -= loanAmount;
        loanTime = block.timestamp;

        emit loanDetails(loanAmount, block.timestamp);
    }

    function payLoan(uint256 _amount) public isAccountAvailable {
        uint256 interestAmount = (_amount * 1) / 10;
        uint256 amount = _amount + interestAmount;
        require(accounts[msg.sender].loanAmount != 0, "You don't have any loan");
        require(_amount != 0, "Can't transfer 0 amount");
        require(
            _amount <= accounts[msg.sender].loanAmount,
            "You are giving amount more than you borrowed"
        );
        require(_amount <= accounts[msg.sender].balance, "You have not enough fund to pay loan");

        if (block.timestamp > loanTime + 60) {
            accounts[msg.sender].balance -= amount;
            accounts[msg.sender].loanAmount -= _amount;
            totalLoanGiven -= _amount;
            availableLoanAmount = totalLoanAmount - totalLoanGiven;
        } else {
            accounts[msg.sender].balance -= _amount;
            accounts[msg.sender].loanAmount -= _amount;
            totalLoanGiven -= _amount;
            availableLoanAmount = totalLoanAmount - totalLoanGiven;
        }

        emit loanPaid(_amount);
    }

    function getInterestOnSaving() public isAccountAvailable {
        uint256 interestOnSaving = ((accounts[msg.sender].balance -
            accounts[msg.sender].loanAmount) * 1) / 20;
        require(accounts[msg.sender].balance != 0, "Deposit funds to get interest");
        require(accounts[msg.sender].interestAmount == 0, "Interest already given");
        accounts[msg.sender].interestAmount += interestOnSaving;
        if (block.timestamp > depositeTimeStamp + 60) {
            accounts[msg.sender].balance += interestOnSaving;
        } else {
            revert Bank__notEligibleForInterest();
        }
    }

    function queryAccount()
        public
        view
        isAccountAvailable
        returns (
            string memory name,
            string memory add,
            address accountNumber,
            uint256 balance,
            uint256 loanAmount,
            uint256 interestAmount
        )
    {
        return (
            accounts[msg.sender].name,
            accounts[msg.sender].add,
            accounts[msg.sender].accountNumber,
            accounts[msg.sender].balance,
            accounts[msg.sender].loanAmount,
            accounts[msg.sender].interestAmount
        );
    }

    function closeAccount() public isAccountAvailable {
        require(
            accounts[msg.sender].loanAmount == 0,
            "You need to pay your loan amount before closing"
        );
        require(accounts[msg.sender].balance == 0, "Withdraw your amount before closing");
        delete accounts[msg.sender];
        noOfAccounts--;

        emit AccountClosed(accounts[msg.sender].accountNumber);
    }

    /* Getter Functions*/

    function getNumberOfAccounts() public view returns (uint256) {
        return noOfAccounts;
    }

    function bankBalance() public view returns (uint256) {
        return (address(this).balance);
    }

    function getListOfAccounts(uint256 index) public view onlyOwner returns (address) {
        return listOfAccounts[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getAccountOpeningTime() public view returns (uint256) {
        return accountOpeningTime;
    }

    function getMinTimeForLoan() public pure returns (uint256) {
        return MINTIME_TOGETLOAN;
    }

    function getTotalLoan() public view returns (uint256) {
        return totalLoanGiven;
    }

    function getTotalLoanAmount() public view returns (uint256) {
        return totalLoanAmount;
    }

    function getAvailableLoanAmount() public view returns (uint256) {
        return availableLoanAmount;
    }

    function getLoanTime() public view returns (uint256) {
        return loanTime;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}
