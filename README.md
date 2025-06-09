# Auction Smart Contract

This repository contains a Solidity smart contract for an auction system, developed as the final project for Module 2 of the Ethereum Developer Pack course. I built this contract to learn about smart contract development, focusing on secure bidding and refund mechanisms. The contract is deployed on the Sepolia testnet and verified with source code.

## Contract Details

- **Deployed Address**: [0x46Eafa2B0392805964D41e29bE0A1D4979Fe72ad](https://sepolia.etherscan.io/address/0x46Eafa2B0392805964D41e29bE0A1D4979Fe72ad)
- **Solidity Version**: >=0.8.26
- **License**: GPL-3.0
- **File**: `Auction.sol`

## Overview

The `Auction` smart contract allows users to bid on an item. Key features include:
- Bids must be at least 5% higher than the current highest bid.
- The auction extends by 10 minutes if a valid bid is placed in the last 10 minutes.
- Non-winners are refunded their last bid minus a 2% commission after the auction ends.
- Bidders can request a partial refund during the auction (see Notes for limitations).
- Events notify participants of new bids and auction completion.

### Auction Logic Example

| Time | User     | Offer  | Action                                      |
|------|----------|--------|---------------------------------------------|
| T0   | User 1   | 1 ETH  | Places bid, becomes highest bidder          |
| T1   | User 2   | 2 ETH  | Places bid, becomes highest bidder          |
| T2   | User 1   | 3 ETH  | Places bid, can request refund (see Notes)  |

## Variables

- `owner` (`address`, private): The contract deployer's address, used for admin tasks like refunds.
- `startTime` (`uint256`, private): Timestamp when the auction starts.
- `limitDate` (`uint256`, private): Timestamp when the auction ends (7 days after start).
- `winner` (`Bider`, private): Struct with the highest bidder's address and bid amount.
- `biders` (`mapping(address => Bider)`, private): Maps addresses to bidder data.
- `biderAddresses` (`address[]`, private): Tracks bidder addresses for refund processing.
- `Bider` (struct):
  - `value` (`uint256`): Current bid amount for the bidder.
  - `lastOffer` (`uint256`): Previous bid amount (used for refunds).
  - `bider` (`address`): Bidder's address.

## Events

- `NewOffer(address indexed bider, uint256 amount)`: Emitted when a new bid is placed, with the bidder's address and amount.
- `AuctionEnded()`: Emitted when the auction ends and refunds are processed.

## Functions

- **constructor()**: Sets up the auction with a 7-day duration and assigns the deployer as the owner.
- **bid()**: Allows bidding (payable). Requires the bid to be 5% higher than the current highest and the auction to be active. Updates bidder data, extends the auction if needed, and emits `NewOffer`.
- **showWinner()**: Returns the current highest bidder's data (`Bider` struct).
- **showOffers()**: Returns an array of all bids. Note: Gas-intensive, use carefully.
- **refund()**: Refunds non-winners' last bids minus 2% commission, callable by the owner after the auction ends. Clears bidder data and emits `AuctionEnded`.
- **partialRefund()**: Allows bidders to withdraw their previous bid during the auction. Note: Currently refunds `lastOffer` (see Notes).
- **extendLimitDate()** (private): Extends the auction by 10 minutes if a bid is placed in the last 10 minutes.
- **receive()**: Reverts accidental ETH transfers, ensuring funds go through `bid()`.

## Modifiers

- `isActive()`: Checks that the auction is ongoing (`block.timestamp < limitDate`).
- `isOwner()`: Restricts access to the contract owner.
- `hasEnded()`: Ensures the auction has ended (`block.timestamp >= limitDate`).

## Deployment and Usage

1. **Deployment**:
   - Deployed on Sepolia at [0x46Eafa2B0392805964D41e29bE0A1D4979Fe72ad](https://sepolia.etherscan.io/address/0x46Eafa2B0392805964D41e29bE0A1D4979Fe72ad).
   - Source code verified on Etherscan.
   - Deploy using Remix with Solidity compiler >=0.8.26.

2. **Interaction**:
   - **Bidding**: Call `bid()` with ETH, ensuring the amount is 5% higher than the current highest bid.
   - **Partial Refund**: Call `partialRefund()` during the auction to withdraw previous bids.
   - **View Data**: Use `showWinner()` and `showOffers()` to check bids.
   - **End Auction**: After `limitDate`, the owner calls `refund()` to process refunds.

3. **Testing**:
   - Use Sepolia test ETH for bids and refunds.
   - Check events on Etherscan to verify state changes.
   - Ensure sufficient ETH for `bid()` calls.

## Notes

- **Partial Refund Limitation**: The `partialRefund` function currently refunds the previous bid (`lastOffer`) instead of the excess over the last valid bid (e.g., 1 ETH from T0 in the example). This is a known issue due to the contract's logic, where `lastOffer` is set to the current `value` before refunding.
- **Gas Usage**: `showOffers` and `refund` iterate over `biderAddresses`, which can be costly for many bidders. Suitable for this project but not for large-scale auctions.
- **Security**: The contract uses `call` for safe ETH transfers, checks inputs with `require`, and clears data to prevent reentrancy.
