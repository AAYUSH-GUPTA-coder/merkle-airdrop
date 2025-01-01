// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20, SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    // some list of addresses
    // allow someone in the list to claim tokens
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hashClaimed;

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_hashClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // calculate using the account and the amount, the hash => leaf node. we are doing double hashing here
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // verify the proof, that it is merkle proof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hashClaimed[account] = true;

        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    ///////////////////////////////////
    ////// VIEW FUNCTIONS   ///////////
    ////////////////////////////////////
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function checkClaimed(address account) external view returns (bool) {
        return s_hashClaimed[account];
    }
}
