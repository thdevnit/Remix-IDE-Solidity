// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




/* Errors */

error CollegeTracker__notUniversityAdmin();
error CollegeTracker__alreadyAdded();
error CollegeTracker__alreadyEnrolled();
error CollegeTracker__notAffiliated();
error CollegeTracker__blockedAddingStudents();
error CollegeTracker__notCollegeAdmin();
error CollegeTracker__collegeNameNotAvailable();
error CollegeTracker__regNumberNotAvailable();



/**    @title A sample College Tracker Smart Contract
       @author Nitesh Singh (nksingh413@gmail.com)
       @notice This contract is for creating a sample College Tracker Contract
   */


contract CollegeTracker {

    

     /* Type Declarations */

    struct collegeDetails {
        string collegeName;
        address collegeAdd;
        string regNum;
        uint256 numOfStudents;
        bool affiliated;
        bool blocked;
    }

    struct studentDetails{
        string name;
        uint256 phoneNumber;
        string courseEnrolled;
        string collegeName;
        address collegeAdd;
    }

     /* State Variables */

    address private immutable i_universityAdmin;
    uint256 private s_numOfColleges;
    string[] private s_collegesName;
    string[] private s_regNumber;

    mapping(address => collegeDetails) private s_collegeDetails;
    mapping(uint256 => studentDetails) private s_studentDetails;


      /* Events */

    event  collegeAdded(string collegeName, address indexed collegeAdd, string regNumber);
    event  studentAdded(address indexed collegeAdd,string studentName,uint256 indexed phoneNum,string courseName);
    event  courseChanged(string changedCourseName);
    
    /* Functions */ 

    constructor(){
        i_universityAdmin = msg.sender;
    }
 
     /* Modifiers */

    modifier onlyUniversityAdmin(){
        if(msg.sender != i_universityAdmin) {
            revert CollegeTracker__notUniversityAdmin();
        }_;
    }

    modifier isAlreadyAdded(address _address){
        if(s_collegeDetails[_address].collegeAdd == _address){
            revert CollegeTracker__alreadyAdded();
        }_;

    }

    modifier isCollegeAffiliated(address _address){
        if(!s_collegeDetails[_address].affiliated){
            revert CollegeTracker__notAffiliated();
        }_;
    }

    modifier isEnrolled(uint256 _phoneNum){
        if(s_studentDetails[_phoneNum].phoneNumber == _phoneNum){
            revert CollegeTracker__alreadyEnrolled();
        }_;
    }

    modifier isBlocked(address _address){
        if(s_collegeDetails[_address].blocked == true){
           revert CollegeTracker__blockedAddingStudents();
        }_;
    }

    modifier onlyCollegeAdmin(address _address){
        if(msg.sender != _address){
            revert CollegeTracker__notCollegeAdmin();
        }_;
    }
     
     /* @title This is a addCollege function
        @notice This function adds colleges to the blockchain ledger
        @dev Only university admin can add colleges using name, address and registration number of any college,Name,address,regNumber must be unique
   */


    function addCollege(string memory _name, address _address, string memory _regNumber) external onlyUniversityAdmin isAlreadyAdded(_address) {
        
        require(_address != address(0),"Need valid address to add college");
        require(_address != i_universityAdmin,"admin can't add college on his own address");   
          for(uint256 i=0; i< s_collegesName.length; i++){
              string memory collegeName = s_collegesName[i];
              if(keccak256(abi.encodePacked(collegeName))==keccak256(abi.encodePacked(_name))) {
            
             revert CollegeTracker__collegeNameNotAvailable();
             }}


             for(uint256 i=0; i< s_regNumber.length; i++){
              string memory regNumber = s_regNumber[i];
              if(keccak256(abi.encodePacked(regNumber))==keccak256(abi.encodePacked(_regNumber))) {
            
             revert CollegeTracker__regNumberNotAvailable();
             }}

         

        collegeDetails storage clgDetails = s_collegeDetails[_address];

        clgDetails.collegeName = _name;
        clgDetails.collegeAdd = _address;
        clgDetails.regNum = _regNumber;
        clgDetails.numOfStudents = 0;
        clgDetails.affiliated = true;
        clgDetails.blocked = false;

        s_numOfColleges++;
        s_collegesName.push(_name);
        s_regNumber.push(_regNumber);
        

        emit collegeAdded(_name,_address,_regNumber);
    }


     /* @title This is a blockCollege function
        @notice This function blocks colleges.
        @dev Only university admin can block colleges using address of that college and that college must be affiliated and unblocked
   */

    function blockCollege(address _address) external onlyUniversityAdmin isCollegeAffiliated(_address){
        require(!s_collegeDetails[_address].blocked,"Already blocked");
        s_collegeDetails[_address].blocked = true;
        
    }

    /*  @title This is a unBlockCollege function
        @notice This function unblocks colleges.
        @dev Only university admin can unblock colleges using address of that college and that college must be affiliated and must be blocked
   */

    function unBlockCollege(address _address) external onlyUniversityAdmin isCollegeAffiliated(_address){
        require(s_collegeDetails[_address].blocked == true,"This college is not blocked");
        s_collegeDetails[_address].blocked = false;
    }


     /* @title This is a cancelAffiliation function
        @notice This function cancel the affiliation of any college.
        @dev Only university admin can cancel affiliation of any college using address of that college and that college must be affiliated
   */


    function cancelAffiliation(address _address) external onlyUniversityAdmin isCollegeAffiliated(_address) {
        s_collegeDetails[_address].affiliated = false;
        s_numOfColleges--;
         for(uint256 i=0; i< s_collegesName.length ;i++){
            string memory collegeName = s_collegesName[i];
            if(keccak256(abi.encodePacked(collegeName)) != keccak256(abi.encodePacked(s_collegeDetails[_address].collegeName))){
                continue;
            } removeCollegeName(i);
        } 

         for(uint256 i=0; i< s_regNumber.length ;i++){
            string memory regNumber = s_regNumber[i];
            if(keccak256(abi.encodePacked(regNumber)) != keccak256(abi.encodePacked(s_collegeDetails[_address].regNum))){
                continue;
            } removeRegNumber(i);
        } 

        delete (s_collegeDetails[_address]);
    }
     
    /*  @title This is a removeCollegeName function
        @notice This function remove the college Name from array
        @dev This function is called internally
   */
    

    function removeCollegeName(uint256 _index) internal {
        require(_index < s_collegesName.length,"Index is out of bound");
        for(uint256 i=_index; i < s_collegesName.length-1; i++){
            s_collegesName[i] = s_collegesName[i+1];
        }
        s_collegesName.pop();
    }


      /*  @title This is a removeRegNumber function
          @notice This function remove the college Registration Number from array
          @dev This function is called internally
   */

    function removeRegNumber(uint256 _index) internal {
         require(_index < s_regNumber.length,"Index is out of bound");
        for(uint256 i=_index; i < s_regNumber.length-1; i++){
            s_regNumber[i] = s_regNumber[i+1];
        }
        s_regNumber.pop();
    }


     /* @title This is a addStudent function
        @notice This function adds student to college
        @dev anybody can take admission in any college  using college address, name, phone Number, Course Name and that college must be affiliated and not blocked.
   */


    function addStudent(address _address, string memory _name, uint256 _phoneNum, string memory _courseName) external isCollegeAffiliated(_address) isBlocked(_address) isEnrolled(_phoneNum) {

        studentDetails storage stdDetails = s_studentDetails[_phoneNum];

        stdDetails.name = _name;
        stdDetails.phoneNumber = _phoneNum;
        stdDetails.courseEnrolled = _courseName;
        stdDetails.collegeName = s_collegeDetails[_address].collegeName;
        stdDetails.collegeAdd = _address;

        s_collegeDetails[_address].numOfStudents++;

        emit studentAdded(_address,_name,_phoneNum,_courseName);

    }
  

     /* @title This is a cancelAdmission function
        @notice This function cancel admission in that college
        @dev any body can call this function using college address and his phone number but they must be enrolled in that college before cancelling
   */

    function cancelAdmission(address _address, uint256 _phoneNum) external {
        require(s_studentDetails[_phoneNum].collegeAdd == _address,"You haven't enrolled in this college");
        delete s_studentDetails[_phoneNum];
        s_collegeDetails[_address].numOfStudents--;
    }

     /* @title This is a changeCourse function
        @notice This function change the course of any enrolled student in that college
        @dev Only college admin can change the course using address of that college, name and phone number of that student and college must be affiliated.
   */

    function changeCourse(address _address, uint256 _phoneNum, string memory _newCourseName) external onlyCollegeAdmin(_address) isCollegeAffiliated(_address){
        studentDetails storage stdDetails = s_studentDetails[_phoneNum];
        require(stdDetails.collegeAdd == _address,"This student is not in your college");
        stdDetails.courseEnrolled = _newCourseName;
        emit courseChanged(_newCourseName);

    }

     /* @title This is a getStudentDetails function
        @notice This function gives the details of any student
        @dev anybody can call this function using their phone number if they have enrolled in any colleges
   */


    function getStudentDetails(uint256 _phoneNum) public view returns(
        string memory name,
        uint256 phoneNumber,
        string memory courseEnrolled,
         string memory collegeName,
         address collegeAdd

    ){
        studentDetails memory stdDetails = s_studentDetails[_phoneNum];
        return(stdDetails.name,
               stdDetails.phoneNumber,
               stdDetails.courseEnrolled,
               stdDetails.collegeName,
               stdDetails.collegeAdd
              );
    }

    /*  @title This is a getCollegeDetails function
        @notice This function gives the details of any colleges
        @dev anybody can call this function using the unique college address.
   */

    function getCollegeDetails(address _address) public view 
               returns(string memory collegeName,
                       address collegeAdd,
                       string memory regNum,
                       uint256 numOfStudents,
                       bool affiliated,
                       bool blocked){
        
        collegeDetails memory clgDetails = s_collegeDetails[_address];
        return (clgDetails.collegeName,clgDetails.collegeAdd,clgDetails.regNum,clgDetails.numOfStudents,clgDetails.affiliated,clgDetails.blocked);
    }


    /* Getter Functions */

    function getNumOfColleges() public view returns(uint256){
        return s_numOfColleges;
    }

     function getAdmin() public view returns(address){
        return i_universityAdmin;
    }
}
