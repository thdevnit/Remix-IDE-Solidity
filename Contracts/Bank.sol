//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

/* Errors */

error Bank__AccountAlreadyOpened();
error Bank__OpenAccount();
error Bank_AlreadyLoanTaken();
error Bank__NotEligibleForInterest();

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
    uint256 private accountOpeningTimestamp;
    uint256 private constant MINTIME_TOGETLOAN = 60;
    address[] private listOfAccounts;
    uint256 private totalLoanGiven;
    uint256 private totalLoanAmount;
    uint256 private availableLoanAmount;
    uint256 private loanTimestamp;
    uint256 private depositeTimeStamp;
    
    mapping(address => accountDetails) private accounts;

    /* Events */

    event accountOpen(string indexed name, address indexed accounNumber);
    event depositeAmount(uint256 indexed depositAmount);
    event withdrawl(uint256 indexed _amount);
    event transferDetail(uint256 indexed _amount, address indexed _accountNumber);
    event loanDetails(uint256 indexed loanAmount, uint256 indexed loanTimestamp);
    event loanPaid(uint256 loanAmount);
    event accountClosed(address accountNumber);
    

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

    function openAccount(string memory _name, string memory _add) external isAlreadyOpened {
        accountDetails storage _accounts = accounts[msg.sender]; 
        _accounts.name = _name;
        _accounts.add = _add;
        _accounts.accountNumber = msg.sender;
        _accounts.balance = 0;
        _accounts.loanAmount = 0;
        _accounts.interestAmount = 0;
        noOfAccounts++;
        listOfAccounts.push(msg.sender);
        accountOpeningTimestamp = block.timestamp;
        // Emit an event when anybody opens account
        emit accountOpen(_name, msg.sender);
    }

    function deposit() public payable isAccountAvailable {
        assert(msg.value > 0);
        accounts[msg.sender].balance += msg.value;
        totalLoanAmount = (address(this).balance * 2) / 5;
        availableLoanAmount = totalLoanAmount - totalLoanGiven;
        depositeTimeStamp = block.timestamp;
        emit depositeAmount(msg.value);
    }

    function withdraw(uint256 _amount) external isAccountAvailable nonReentrant {
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

    function transfer(uint256 _amount, address _accountNumber) external isAccountAvailable {
        require(_amount != 0, "Can't transfer 0 amount");
        require(_accountNumber != address(0), "Need Valid account number to transfer");
        require(accounts[msg.sender].balance > 0, "You need to deposite amount before transfer");
        require(_amount <= accounts[msg.sender].balance, "You need some more balance");
        require(
            accounts[_accountNumber].accountNumber == _accountNumber,
            "Receipent need to create account first"
        );
        require(_accountNumber != msg.sender, "Self transfer is not allowed");
        accounts[msg.sender].balance -= _amount;
        accounts[_accountNumber].balance += _amount;

        emit transferDetail(_amount, _accountNumber);
    }

    function getLoan() external isAccountAvailable isAnyLoanBefore {
        uint256 loanAmount = (accounts[msg.sender].balance * 1) / 2;
        accountDetails storage _accounts = accounts[msg.sender];
        require(
            block.timestamp > accountOpeningTimestamp + MINTIME_TOGETLOAN,
            "Your account is not old enough to get Loan"
        );
        require(availableLoanAmount > loanAmount, "Bank has not enough fund");
        require(accounts[msg.sender].balance >= 5 ether, "You don't have enough funds to get Loan");
        _accounts.balance += loanAmount;
        _accounts.loanAmount += loanAmount;
        totalLoanGiven += loanAmount;
        availableLoanAmount -= loanAmount;
        loanTimestamp = block.timestamp;

        emit loanDetails(loanAmount, block.timestamp);
    }

    function payLoan(uint256 _amount) external isAccountAvailable {
        uint256 interestAmount = (_amount * 1) / 10;
        uint256 amount = _amount + interestAmount;
        accountDetails storage _accounts = accounts[msg.sender];
        require(_accounts.loanAmount != 0, "You don't have any loan");
        require(_amount != 0, "Can't transfer 0 amount");
        require(
            _amount <= _accounts.loanAmount,
            "You are giving amount more than you borrowed"
        );
        require(_amount <= _accounts.balance, "You have not enough fund to pay loan");

        if (block.timestamp > loanTimestamp + 60) {
            _accounts.balance -= amount;
            _accounts.loanAmount -= _amount;
            totalLoanGiven -= _amount;
            availableLoanAmount = totalLoanAmount - totalLoanGiven;
        } else {
            _accounts.balance -= _amount;
            _accounts.loanAmount -= _amount;
            totalLoanGiven -= _amount;
            availableLoanAmount = totalLoanAmount - totalLoanGiven;
        }

        emit loanPaid(_amount);
    }

    function getInterestOnSaving() external isAccountAvailable {
        accountDetails storage _accounts = accounts[msg.sender];
        uint256 interestOnSaving = ((_accounts.balance -
            _accounts.loanAmount) * 1) / 20;

        require(_accounts.balance != 0, "Deposit funds to get interest");
        require(_accounts.interestAmount == 0, "Interest already given");
        _accounts.interestAmount += interestOnSaving;
        if (block.timestamp > depositeTimeStamp + 60) {
            _accounts.balance += interestOnSaving;
        } else {
            revert Bank__NotEligibleForInterest();
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
        accountDetails storage _accounts = accounts[msg.sender];
        return (
            _accounts.name,
            _accounts.add,
            _accounts.accountNumber,
            _accounts.balance,
            _accounts.loanAmount,
            _accounts.interestAmount
        );
    }

    function closeAccount() external isAccountAvailable {
        require(
            accounts[msg.sender].loanAmount == 0,
            "You need to pay your loan amount before closing"
        );
        require(accounts[msg.sender].balance == 0, "Withdraw your amount before closing");
        delete accounts[msg.sender];
        noOfAccounts--;

        emit accountClosed(accounts[msg.sender].accountNumber);
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

    function getaccountOpeningTimestamp() public view returns (uint256) {
        return accountOpeningTimestamp;
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

    function getloanTimestamp() public view returns (uint256) {
        return loanTimestamp;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}
