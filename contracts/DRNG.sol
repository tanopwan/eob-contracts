pragma solidity >=0.5.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
========== DEVELOPER READ: Decentralized random number generator flow ==========
1. User request random number in your contract (Ex: Opening nftbox).
2. Your contract request current block number using IDRNG(...).getBlockNumber() and save to your contract.
3. Your contract request current random number using IDRNG(...).current() as seed and save to your contract.
4. Your contract increment claimId and save claimId associated with current block number and random number from step (2) and (3) in your contract.
5. Your contract call IDRNG(...).fillRandom() to prevent multiple same seed (and secure the network)
6. Emit some event and finish contract function calling.
7. Let user wait for around 2 minutes.
8. After waiting for 2 minutes, user call claim(claimId) in your contract.
9. Your contract request secured random number using IDRNG(...).getRandom(blockNumber[claimId], seed[claimId]).
10. Your contract mod random number from (7) to desired range (Raw random number will be in range 0 to 2^256 - 1).
11. Your contract use random number from (8) to give item(s) to the caller.
========== DEVELOPER READ: How to help secure the random number network ==========
You can help secure the random number network by always calling fillRandom() and nextRandom() in seperated function.
You can see the example of doing this in zerodevfee-contracts.
*/

contract DRNG is Ownable {
	// m is chosen from https://arxiv.org/abs/2001.05304
	uint128 public m = 264694175874436524573452841291911374949; //0xc7223e72fe1b3e831533bf46d655a865
	
	// c = 1 is commonly used
	uint128 public c = 1;
	
	// 1 Minute/block
	//uint256 public blockSize = 60;
	uint256 public blockSize = 2;
	
	// Some random number
	uint128 public current = 130497400866170025062990771042059518336;
	
	mapping(uint256 => uint128[]) blockRandom; // Use <blockSize> seconds as 1 block instead of native block
	
	function setConstants(uint128 _m, uint128 _c) external onlyOwner {
		m = _m;
		c = _c;
	}
	
	function nextRandom() public returns (uint128) {
		current = m * current + c;
		return current;
	}

	function fillRandom() public returns (uint128) {
		uint256 currentBlock = block.timestamp / blockSize;
		blockRandom[currentBlock-1].push(nextRandom());
		blockRandom[currentBlock].push(nextRandom());
		return nextRandom();
	}
	
	function getBlockNumber() public view returns (uint256) {
	    return block.timestamp / blockSize;
	}
	
	// Seed is sent from external contract which is a random number generated on requesting random
	function getRandom(uint256 blockNumber, uint128 seed) public view returns (uint128) {
		uint256 currentBlock = block.timestamp / blockSize;
		require(currentBlock - blockNumber > 1, 'Must wait for 2 blocks');
		
		if (blockRandom[blockNumber].length == 0) {
		    // In case of early stage before zerodevfee.finance success
			return uint128(block.timestamp) * current;
		} else {
		    // This will be much more secure after zerodevfee.finance success
			return blockRandom[blockNumber][seed % blockRandom[blockNumber].length];
		}
	}
	
	// For debug
	function getBlockRandomAtBlock(uint256 blockNumber) public view returns (uint128[] memory) {
		return blockRandom[blockNumber];
	}
}