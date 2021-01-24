// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


/** 
 * @title QuadVotingFactory Contract
 * @dev Contract for creating child contracts
*/
contract QuadVotingFactory{
    address [] public listOfChildContracts;
    
    event ContractCreated(address contractAddress);
    
    /** 
    * @dev Function which creates child contracts
    * @param _initialSupply Number of voting tokens to be minted
    * @param _tokensPerPerson Numberof tokens distributed to approved addresses
    */
    function createChildContract(uint256 _initialSupply, uint256 _tokensPerPerson) public{
        address newContract = address(new QuadVoting(_initialSupply, _tokensPerPerson, msg.sender));
        
        listOfChildContracts.push(newContract);
        emit ContractCreated(newContract);
    }
    
    /**
    * @dev Function which returns all the created child contracts
    * @return This returns the entire array of deployed contract addresses
    */
    function getDeployedChildContract() external view returns (address[] memory){
        return listOfChildContracts;
    }
}


/*
 * @title QuadVoting Contract1
 * @dev Contains ERC-20 functions and functions to create and vote in polls
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
    ////////////////////////////////////////////////////////////////
    
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
    /**
    @dev Set the initial supply and token per person
    @param _initialSupply No of initial tokens supplied by Factory Contract
    @param _tokensPerPerson No of tokens per person supplied by Factory Contract
    @param _msgSender Address of the owner to be set supplied by Factory Contract
    */
    constructor(uint256 _initialSupply, uint256 _tokensPerPerson, address _msgSender) {
        owner = _msgSender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        totalSupply = _initialSupply;
        tokensPerPerson = _tokensPerPerson;
        balanceOf[_msgSender] = _tokensPerPerson;
        balanceOf[address(this)] = _initialSupply - _tokensPerPerson;
        decimals = 2;
    }
    /////////////////////////////////////////////////////
    
    //////////////////// Voting related functions ////////////////////
    /**
    @dev Function to be called by the owner of the contract
    @param options No of options in the poll 
    */
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
    
    /**
    @dev Function to vote in a particular poll
    @param selectedPoll To select the poll in which to vote
    @param selectedOption To select the option on which to vote
    @param noOfVotes No of votes to be cast
    */
    function vote(uint256 selectedPoll, uint256 selectedOption, uint256 noOfVotes) public returns (uint256){
        require(balanceOf[msg.sender] >= noOfVotes * noOfVotes,"You don't have enough balance for this transaction");
        uint256 votes = noOfVotes * noOfVotes;
        pollMap[selectedPoll].votes[selectedOption] = pollMap[selectedPoll].votes[selectedOption] + votes;
        number = votes;
        
        transfer(0x0000000000000000000000000000000000000000, votes);
        return pollMap[selectedPoll].votes[selectedOption];
    }
    
    /**
    @dev Function which returns the current state of the polls
    @param selectedPoll To select the poll to return
    @return This function returns the array containing state of the selected poll. 
    */
    function getVotes(uint256 selectedPoll) external view returns (uint256[] memory){
        return pollMap[selectedPoll].votes;
    }

    /**
    @dev Approve address to be part of the poll
    @param _approveAddress Approve address and airdrop the set amount of tokens
    */
    function approveAddresses(address _approveAddress) public returns (bool success){
        require(msg.sender == owner, "Only the owner of the contract can approve addresses");
        approvedAddresses[_approveAddress] = true;
        transferFromContract(_approveAddress, tokensPerPerson);
        return true;
    }
    
    ////////////////////////////////////////////////////////////
    
    
    /////////////////// ERC20 related functions ////////////////
    
    /**
    @dev Standard ERC-20 function to transfer tokens
    @param _to Address to which to transfer
    @param _value No of tokens to transfer
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value,"You don't have enough balance for this transaction");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    
    /**
    @dev Additional function to transger from the contract to the approved address
    @param _to Address to which to transfer tokens
    @param _value No of tokens to be transferred
    */
    function transferFromContract(address _to, uint256 _value) private returns (bool success) {
        require(balanceOf[address(this)] >= _value,"Not enough balance for this transaction");

        balanceOf[address(this)] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(address(this), _to, _value);

        return true;
    }

    /**
    @dev Standard ERC-20 function to approve spending by another address
    @param _spender The address which the person approves the fund
    @param _value No of tokens approved
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    @dev Standard ERC-20 function to spend tokens from approved addresses
    @param _from The address of the sender
    @param _to  The address of the receiver
    @param _value No of tokens to be transferred
    */
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