// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleAuction {
    address payable public immutable seller;    
    uint public endTime;
    bool public auctionIsActive;
    mapping(address => uint) public bids;    
    uint public highestBid;
    address public highestBidder;

    constructor(uint _startingPrice) {
        highestBid = _startingPrice;        
        seller = payable(msg.sender);
    }

    event AuctionStarted(uint endTime);
    event BidPlaced(address indexed bidder, uint amount);
    event AuctionEnded(address indexed winner, uint amount);

    modifier onlyIfAuctionActive() {
        require(auctionIsActive, "Auction is not active.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function.");
        _;
    }

    function start(uint duration) public onlySeller {
        require(!auctionIsActive, "Auction is active.");             
                
        endTime = block.timestamp + duration;
        auctionIsActive = true;

        emit AuctionStarted(endTime);
    }

    function placeBid() public payable onlyIfAuctionActive {   
        require(msg.sender != seller, "The seller can not place a bid.");     
        require(msg.value > highestBid, "Insufficient funds.");
        require(block.timestamp < endTime, "The auction has expired.");

        highestBidder = msg.sender;
        highestBid = msg.value;        
        bids[highestBidder] += highestBid;

        emit BidPlaced(highestBidder, highestBid);
    }

    function end() public onlyIfAuctionActive onlySeller {        
        require(block.timestamp > endTime, "End time has not been reached yet.");

        seller.transfer(highestBid); 
        auctionIsActive = false; 

        emit AuctionEnded(highestBidder, highestBid);      
    }

    // Better pattern than sending the ether to unsuccessful bidders in the end function
    function withdraw() public payable {
        require(!auctionIsActive, "Can't withdraw while auction is active.");
        require(bids[msg.sender] > 0 && msg.sender != seller, "Only bidders can withdraw.");

        uint fundsToWithdraw = (msg.sender == highestBidder) ? (bids[msg.sender] - highestBid) : bids[msg.sender] ;
        payable(msg.sender).transfer(fundsToWithdraw);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {}
}