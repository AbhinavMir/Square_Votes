// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


/**
 * @title QuadVoting
 * @dev Quadratic Voting Contract
 */
 
contract QuadVoting {
    
    /////////////////// ERC20 related variables ///////////////////
    string  public name = "Quadratic Voting Token";
    string  public symbol = "QUAD";
    string  public standard = "Quadratic Voting Token v1.0";
    uint256 public tokensPerPerson;
    uint256 public totalSupply;
    uint8 public decimals;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public approvedAddresses;
    
    
    /////////////////// Voting related variables ///////////////////
    struct Poll {
        uint256 noOfOptions;
        uint256[] votes;
    }

    uint256 public number;
    address private owner;
    uint256 public id = 0;
    
    mapping(uint256 => Poll)  public pollMap;
    /////////////////////////////////////////////////////////////////
    
    /////////////////// constructor ///////////////////
    constructor(uint256 _initialSupply, uint256 _tokensPerPerson) {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        totalSupply = _initialSupply;
        tokensPerPerson = _tokensPerPerson;
        balanceOf[msg.sender] = _tokensPerPerson;
        balanceOf[address(this)] = _initialSupply - _tokensPerPerson;
        decimals = 2;
    }
    /////////////////////////////////////////////////////
    
    //////////////////// Voting related functions ////////////////////
    function createPoll(uint256 options) public{
        require(options >= 2, "You need to provide 2 or more options");
        Poll storage poll = pollMap[id];
        poll.noOfOptions = options;
        id = id + 1;
        
        while(options != 0){
            poll.votes.push(0);
            options = options - 1;
        }
    }
    
    function vote(uint256 selectedPoll, uint256 selectedOption, uint256 noOfVotes) public returns (uint256){
        require(balanceOf[msg.sender] >= noOfVotes * noOfVotes,"You don't have enough balance for this transaction");
        uint256 votes = noOfVotes * noOfVotes;
        pollMap[selectedPoll].votes[selectedOption] = pollMap[selectedPoll].votes[selectedOption] + votes;
        number = votes;
        
        transfer(0x0000000000000000000000000000000000000000, votes);
        return pollMap[selectedPoll].votes[selectedOption];
    }
    ////////////////////////////////////////////////////////////
    
    
    /////////////////// ERC20 related functions ////////////////
    function approveAddresses(address _approveAddress) public returns (bool success){
        require(msg.sender == owner, "Only the owner of the contract can approve addresses");
        approvedAddresses[_approveAddress] = true;
        transferFromContract(_approveAddress, tokensPerPerson);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value,"You don't have enough balance for this transaction");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function transferFromContract(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[address(this)] >= _value,"Not enough balance for this transaction");

        balanceOf[address(this)] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(address(this), _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from],"The sender does not have enough balance for this transaction");
        require(_value <= allowance[_from][msg.sender],"Not authorized by the sender");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    ///////////////////////////////////////////////////////////////
}