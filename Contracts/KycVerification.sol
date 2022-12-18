// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* Errors */

error KycVerification__notCentralBankAdmin();
error KycVerification__nameNotAvailable();
error KycVerification__alreadyAdded();
error KycVerification__notBankAdmin();
error KycVerification__customerAddedAlready();
error KycVerification__notAllowedForKycVerification();

/**    @title A sample KYC Verification Smart Contract
       @author Nitesh Singh (nksingh413@gmail.com)
       @notice This contract is for creating a sample KYC Verification Contract
   */

contract KycVerification {

    /* Type Declarations */

    struct bankDetails {
        string name;
        string add;
        address uniqueAdd;
        uint256 numOfCustomers;
        bool blockedAddingCustomer;
        bool blockedKycVerification;
    }

    struct customerDetails {
        string name;
        string add;
        uint256 phoneNum;
        string bankName;
        address bankUniqueAdd;
        bool kycStatus;
    }

    /* State Variables */

    address private immutable i_centralBankAdmin;
    uint256 private s_numOfBanks;
    string[] private s_bankNames;

    mapping(address => bankDetails) private s_bankDetails;
    mapping(uint256 => customerDetails) private s_customerDetails;
    

    /* Events */

    event BankAdded(string bankName, string bankAdd, address bankUniqueAdd);
    event CustomerAdded(
        string customerName,
        uint256 indexed phoneNum,
        address indexed bankUniqueadd
    );
    event KycVerified(uint256 customerPhoneNum);
    event BankBlockedToAddCustomer(address indexed bankUnqiueAdd, uint256 indexed blockTimeStamp);
    event BankBlockedForKycVerification(
        address indexed bankUniqueAdd,
        uint256 indexed blockTimeStamp
    );
    event BankUnBlockedToAddCustomer(address indexed bankUniqueAdd, uint256 indexed blockTimeStamp);
    event BankUnBlockedForKycVerification(
        address indexed bankUniqueAdd,
        uint256 indexed blockTimeStamp
    );

    /* Functions */

    constructor() {
        i_centralBankAdmin = msg.sender;
    }

    /* Modifiers */

    modifier onlyCentralBankAdmin() {
        if (msg.sender != i_centralBankAdmin) {
            revert KycVerification__notCentralBankAdmin();
        }
        _;
    }

    modifier isAlreadyAdded(address _address) {
        if (
            s_bankDetails[_address].uniqueAdd == _address &&
            s_bankDetails[_address].uniqueAdd != address(0)
        ) {
            revert KycVerification__alreadyAdded();
        }
        _;
    }

    modifier onlyBankAdmin(address _address) {
        if (msg.sender != _address) {
            revert KycVerification__notBankAdmin();
        }
        _;
    }

    modifier isCustomerAddedAlready(uint256 _phoneNum, address _address) {
        if (s_customerDetails[_phoneNum].bankUniqueAdd == _address) {
            revert KycVerification__customerAddedAlready();
        }
        _;
    }

    modifier isAllowedKycVerification(address _address) {
        if (s_bankDetails[_address].blockedKycVerification == true) {
            revert KycVerification__notAllowedForKycVerification();
        }
        _;
    }

    /*  @title This is a addBank function
        @notice This function adds Bank to the blockchain ledger
        @dev Only centralBank admin can add Banks using name, address and unique address of any Bank,Name & address, must be unique
   */

    function addBank(
        address _address,
        string memory _name,
        string memory _add
    ) external onlyCentralBankAdmin isAlreadyAdded(_address) {
        require(_address != address(0), "Need valid address to add college");
        require(_address != i_centralBankAdmin, "admin can't add college on his own address");

        for (uint256 i = 0; i < s_bankNames.length; i++) {
            string memory bankName = s_bankNames[i];
            if (keccak256(abi.encodePacked(bankName)) == keccak256(abi.encodePacked(_name))) {
                revert KycVerification__nameNotAvailable();
            }
        }

        bankDetails storage details = s_bankDetails[_address];
        details.name = _name;
        details.add = _add;
        details.uniqueAdd = _address;
        details.numOfCustomers = 0;
        details.blockedAddingCustomer = false;
        details.blockedKycVerification = false;

        s_bankNames.push(_name);
        s_numOfBanks++;

        emit BankAdded(_name, _add, _address);
    }

    /*  @title This is a addCustomer function
        @notice This function adds customer to the particular bank
        @dev Only Bank admin can add customer using name, address and phone number, One phone number is valid for one account only
   */

    function addCustomer(
        address _address,
        string memory _name,
        string memory _add,
        uint256 _phoneNum
    ) external onlyBankAdmin(_address) isCustomerAddedAlready(_phoneNum, _address) {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_bankDetails[_address].blockedAddingCustomer == false,
            "This bank is not allowed to add customer"
        );

        customerDetails storage custDetails = s_customerDetails[_phoneNum];

        custDetails.name = _name;
        custDetails.add = _add;
        custDetails.phoneNum = _phoneNum;
        custDetails.bankName = s_bankDetails[_address].name;
        custDetails.bankUniqueAdd = s_bankDetails[_address].uniqueAdd;
        custDetails.kycStatus = false;

        s_bankDetails[_address].numOfCustomers++;

        emit CustomerAdded(_name, _phoneNum, _address);
    }

    /*  @title This is a performKycVerification function
        @notice This function verifies the KYC of existing customer of their bank
        @dev Only Bank admin can perform kyc verification and that bank must be allowed for kyc verification
   */

    function performKycVerification(
        address _address,
        uint256 _phoneNum
    ) external onlyBankAdmin(_address) isAllowedKycVerification(_address) {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_customerDetails[_phoneNum].bankUniqueAdd == _address,
            "This is not a bank customer"
        );
        require(s_customerDetails[_phoneNum].kycStatus == false, "KYC already done");

        s_customerDetails[_phoneNum].kycStatus = true;

        emit KycVerified(_phoneNum);
    }

    /*  @title This is a blockBankToAddCustomer function
        @notice This function block the bank to add customer
        @dev Only centralbank admin can block the bank and that bank must be registered with central bank
   */

    function blockBankToAddCustomer(address _address) external onlyCentralBankAdmin {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_bankDetails[_address].blockedAddingCustomer == false,
            "This bank is already blocked to add customer"
        );

        s_bankDetails[_address].blockedAddingCustomer = true;

        emit BankBlockedToAddCustomer(_address, block.timestamp);
    }

    /*  @title This is a unBlockBankToAddCustomer function
        @notice This function unblock the bank to add customer
        @dev Only centralbank admin can unblock the bank and that bank must be blocked before
   */

    function unBlockBankToAddCustomer(address _address) external onlyCentralBankAdmin {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_bankDetails[_address].blockedAddingCustomer == true,
            "This bank is not blocked to add customer"
        );

        s_bankDetails[_address].blockedAddingCustomer = false;

        emit BankUnBlockedToAddCustomer(_address, block.timestamp);
    }

    /*  @title This is a blockBankForKycVerification function
        @notice This function block the bank to perform KYC verification
        @dev Only centralbank admin can block the bank and that bank must be registered with central bank
   */

    function blockBankForKycVerification(address _address) external onlyCentralBankAdmin {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_bankDetails[_address].blockedKycVerification == false,
            "This Bank is already blocked for kyc verification"
        );

        s_bankDetails[_address].blockedKycVerification = true;

        emit BankBlockedForKycVerification(_address, block.timestamp);
    }

    /*  @title This is a unBlockBankForKycVerification function
        @notice This function unblock the bank to perform KYC verification
        @dev Only centralbank admin can unblock the bank and that bank must be registered with central bank
   */

    function unBlockBankForKycVerification(address _address) external onlyCentralBankAdmin {
        require(s_bankDetails[_address].uniqueAdd == _address, "Bank is not registered yet");
        require(
            s_bankDetails[_address].blockedKycVerification == true,
            "This Bank is not blocked for kyc verification"
        );

        s_bankDetails[_address].blockedKycVerification = false;

        emit BankUnBlockedForKycVerification(_address, block.timestamp);
    }

    /*  @title This is a getCustomerDetails function
        @notice This function allows a bank to view details of any customer
        @dev any customer can check their details using their phone number registered with bank 
   */

    function getCustomerDetails(
        uint256 _phoneNum
    )
        public
        view
        returns (
            string memory name,
            string memory add,
            uint256 phoneNum,
            string memory bankName,
            address bankUniqueAdd,
            bool kycStatus
        )
    {
        customerDetails memory customers = s_customerDetails[_phoneNum];
        return (
            customers.name,
            customers.add,
            customers.phoneNum,
            customers.bankName,
            customers.bankUniqueAdd,
            customers.kycStatus
        );
    }

    /*  @title This is a getBankDetails function
        @notice This function shows the details of any registered bank
        @dev anybody can check the details of any bank using the bank's unique address
   */

    function getBankDetails(
        address _address
    )
        public
        view
        returns (
            string memory name,
            string memory add,
            address uniqueAdd,
            uint256 numOfCustomers,
            bool blockedAddingCustomer,
            bool blockedKycVerification
        )
    {
        bankDetails memory banks = s_bankDetails[_address];

        return (
            banks.name,
            banks.add,
            banks.uniqueAdd,
            banks.numOfCustomers,
            banks.blockedAddingCustomer,
            banks.blockedKycVerification
        );
    }

    /* Getter Functions */

    function getAdmin() public view returns (address) {
        return i_centralBankAdmin;
    }

    function getNumOfBanks() public view returns (uint256) {
        return s_numOfBanks;
    }

    function getBankName(uint256 _index) public view returns (string memory) {
        return s_bankNames[_index];
    }
}
