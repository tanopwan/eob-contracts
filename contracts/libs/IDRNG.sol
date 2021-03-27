pragma solidity >=0.5.0;

/*
========== DEVELOPER READ: Decentralized random number generator flow ==========
1. User request random number in your contract (Ex: Opening nftbox).
2. Your contract request current block number using IDRNG(...).getBlockNumber() and save to your contract.
3. Your contract request current random number using IDRNG(...).nextRandom() as seed and save to your contract.
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


interface IDRNG {
	function nextRandom() external returns (uint128);
	function fillRandom() external;
	function getBlockNumber() external view returns (uint256);
	
	// Seed is sent from external contract which is a random number generated on requesting random
	function getRandom(uint256 blockNumber, uint128 seed) external view returns (uint256);
}