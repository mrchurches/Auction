// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.26;
contract Auction {
    // Struct to store bidder information
    struct Bider {
        uint256 value;      // current bid amount
        uint256 lastOffer;  // previous valid bid amount
        address bider;      // bidder's address
    }

    // Events
    event NewOffer(address indexed bider, uint256 amount);
    event AuctionEnded();

    // State variables (private for security)
    address private owner; // deployer and admin
    uint256 private startTime; // auction start timestamp
    uint256 private limitDate; // auction end timestamp
    Bider private winner; // Current highest bidder
    mapping(address => Bider) private biders; // maps addresses to bidder data
    address[] private biderAddresses; // tracks bidder addresses for refund iteration

    constructor() {
        startTime = block.timestamp;
        limitDate = startTime + 7 days; // set 7 days minimun duration
        owner = msg.sender;
    }

    //modifiers
    
    modifier isActive() {
        require(block.timestamp < limitDate, "Auction already ended");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp >= limitDate, "Auction has not ended");
        _;
    }

    // extends auction by 10 minutes if is in the last 10 minutes
    function extendLimitDate() private {
        if ((limitDate - block.timestamp) < 10 minutes) {
            limitDate += 10 minutes;
        }
    }

    // allows users to set a bid, must be 5% higher than current highest
    function bid() external payable isActive {
        require(msg.value > 0, "Bid amount must be greater than zero");
        require(msg.value > (winner.value * 105 / 100), "Bid must be at least 5% higher");

        Bider storage bider = biders[msg.sender];
        if (bider.value == 0) {
            biderAddresses.push(msg.sender); // add new bidder address
            bider.bider = msg.sender;
        }
        // save current value as lastOffer before updating
        bider.lastOffer = bider.value;
        bider.value = msg.value;

        // update winner if the bid is higher
        if (bider.value > winner.value) {
            winner.value = bider.value;
            winner.bider = msg.sender;
            extendLimitDate();
        }
           emit NewOffer(msg.sender, msg.value);
    }

    // returns the current highest bidder
    function showWinner() external view returns (Bider memory) {
        return winner;
    }

    // returns all bids
    function showOffers() external view returns (Bider[] memory) {
        Bider[] memory offers = new Bider[](biderAddresses.length);
        for (uint i = 0; i < biderAddresses.length; ++i) {
            offers[i] = biders[biderAddresses[i]];
        }
        return offers;
    }

    // Refunds non-winners with 2% discount, only callable by owner after the auction ends
    function refund() external isOwner hasEnded {
        for (uint i = 0; i < biderAddresses.length; ++i) {
            address biderAddr = biderAddresses[i];
            if (biderAddr != winner.bider) {
                Bider storage bider = biders[biderAddr];
                    uint256 value = bider.lastOffer;
                    value -= 2 * value / 100; // Deduct 2%
                    bider.value = 0; // Prevent reentrancy
                    bider.lastOffer = 0;
                    (bool success, ) = biderAddr.call{value: value}("");
                    require(success, "Refund failed");
            }
        }
        emit AuctionEnded();
    }

    // allows bidders to withdraw excess over their last valid bid during auction
    function partialRefund() external isActive {
        Bider storage bider = biders[msg.sender];
        require(bider.value > 0, "No bids found");
        require(bider.lastOffer>0,"No last offer to refund");
        require(bider.value > bider.lastOffer, "No refundable amount");

        uint256 refundAmount = bider.lastOffer;
        bider.lastOffer = 0;
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        if(success){
            bider.lastOffer = 0;
        }
        require(success, "Refund failed");
    }

    // fallback function to handle accidental ETH transfers
    receive() external payable {
        revert("Direct ETH transfers not allowed, use bid()");
    }
}
