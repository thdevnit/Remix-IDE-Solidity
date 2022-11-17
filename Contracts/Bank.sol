//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

error Library__BookisAlreadyAdded();
error Library__notOwner();
error Library__BookSold();
contract Library{
  struct Book {
      uint256 id;
      string name;
      uint256 price;
      address owner;
      bool available;
  }
  address private immutable i_owner;
  mapping(uint256=>Book) private Books;
event BookListed(string indexed name,uint256 indexed price);
event newOwner(address indexed_newOwner);
modifier isOwner(){
    if(msg.sender != i_owner){
revert Library__notOwner();
    }_;
}
modifier isAvailable(uint256 _id){
    if(Books[_id].available != true){
        revert Library__BookSold();
    }_;
}
  constructor(){
      i_owner = msg.sender;
  }
function addNewBook(uint256 _id, string memory _name,uint256 _price) public isOwner{
    Books[_id].id = _id;
    Books[_id].name = _name;
    Books[_id].price = _price;
    Books[_id].owner = i_owner;
    Books[_id].available = true;
    emit BookListed(_name,_price);
}
function queryBook(uint256 _id) public view returns(string memory name, uint256 price, bool available ){
    return (Books[_id].name,Books[_id].price,Books[_id].available
    );
}
function sellBook(uint256 _id, address _newOwner) public isAvailable(_id)  {
    Books[_id].owner = _newOwner;
    Books[_id].available = false;
    emit newOwner(_newOwner);
}
  function getOwner() public view returns(address){
      return i_owner;
  }




}
