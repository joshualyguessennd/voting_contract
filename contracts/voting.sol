//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.6; 

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract Voting is ChainlinkClient{
    uint private oraclePayment;
    address private oracle;
    bytes32 private jobId;
    uint private yesCount;
    uint private noCount;
    bool private votingLive;
    address payable owner;
    mapping(address => bool) public voters;
    
    //modifier only the owner can start the contract 
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        setPublicChainlinkToken();
        owner = msg.sender;
        oraclePayment = 0.1 * 10 ** 18; // 0.1 LINK 
        //Kovan alarm
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "a7ab70d561d34eb49e9b1612fd2e044b";
        yesCount = 0;
        noCount = 0;
    }
    
    function startVote(uint voteMinutes) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.addUint("until", now + voteMinutes * 1 minutes);
        // start voting window the submit request to sleep $voteMinutes
        votingLive = true;
        sendChainlinkRequestTo(oracle, req, oraclePayment);
    }
    
    function fulfill(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
        //$voteMinutes has elapsed stop voting
        votingLive = false;
    }
    
    function vote(bool voteCast) public {
        require(!voters[msg.sender], "already vote");
        // if voting is live an address hasn't vote yet, count vote 
        if(voteCast) {yesCount++;}
        if(!voteCast) {noCount++;}
        //address has vote, mark them as them as such 
        voters[msg.sender] =  true;
        
    }
    
    function getVote() public view returns (uint yesVotes, uint noVotes) {
        return(yesCount, noCount);
    }
    
    function haveYouVote() public view returns(bool) {
        return voters[msg.sender];
    }
}