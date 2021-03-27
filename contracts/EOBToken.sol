pragma solidity 0.6.12;

import "./libs/BEP20.sol";

// EOBToken with Governance.
contract EOBToken is BEP20('Estate-Onblock', 'EOB') {
    event EOBMinted(address indexed to, uint256 indexed firstMintId, uint256 amount);
    event EOBBurned(address indexed burner, uint256 amount, uint256 output);
    
    address public adminAddress;
    
    constructor() public {
        adminAddress = msg.sender;
    }
    
    struct AllowMintingData {
        bool allowed;
        uint256 timelock;
    }
    
    uint256 public allowMintingTimelock = 0; // in seconds, will be set later
    
    mapping(address => AllowMintingData) public allowMinting;
    
    modifier onlyAdmin {
        require(msg.sender == adminAddress, "Only admin");
        _;
    }
    
    struct mintingProfileStruct {
        uint256 totalMint;
        uint256 firstMintId;
        uint256 firstMintTimestamp;
    }
    
    mapping(address => mintingProfileStruct) public mintingProfile;
    uint256 public firstMintIdCounter = 0;
    uint256 public mintingMultiplier = 100;
    uint256 public adminShareDivider = 4;
    uint256 public mintingTotalSupply = 1e24;
    uint256 public mintingTotalCurrent = 0;
    
    function setMintingMultiplier(uint256 _multiplier) public onlyAdmin {
        require(_multiplier < mintingMultiplier, "Can only increase price");
        mintingMultiplier = _multiplier;
    }
    
    function setAdminShareDivider(uint256 _divider) public onlyAdmin {
        require(_divider > adminShareDivider, "Can only decrease admin share");
        adminShareDivider = _divider;
    }
    
    function setMintingTotalSupply(uint256 _supply) public onlyAdmin {
        require(_supply >= mintingTotalCurrent, "Not enough supply");
        mintingTotalSupply = _supply;
    }
    
    function setAllowMintingTimelock(uint256 _duration) public onlyAdmin {
        require(_duration > allowMintingTimelock, "Must be longer lock");
        allowMintingTimelock = _duration;
    }
    
    function getRealTotalSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(0x000000000000000000000000000000000000dEaD);
    }
    
    function setAllowMinting(address _address, bool _allowed) public onlyAdmin {
        if (_allowed) {
            if (allowMinting[_address].timelock > 0 && block.timestamp > allowMinting[_address].timelock) {
                allowMinting[_address].allowed = true;
            } else {
                allowMinting[_address].timelock = block.timestamp + allowMintingTimelock;
            }
        } else {
            allowMinting[_address].allowed = false;
            allowMinting[_address].timelock = 0;
        }
    }
    
    function setAdmin(address _adminAddress) public onlyAdmin {
        adminAddress = _adminAddress;
    }
    
    modifier onlyAllowedMinting(address _address) {
        require(allowMinting[_address].allowed, "Cannot mint");
        _;
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the app that is allowed minting Ex: MasterChef.
    function mint(address _to, uint256 _amount) public onlyAllowedMinting(msg.sender) {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    
	// Minting mechanism to be used in presale
	function mintUserTo(address _to) public payable {
	    uint256 _amount = msg.value * mintingMultiplier;
		_mint(_to, _amount);
		_moveDelegates(address(0), _delegates[_to], _amount);
		
		mintingProfile[_to].totalMint += _amount;
		mintingTotalCurrent += _amount;
		
		require(mintingTotalCurrent <= mintingTotalSupply, "Out of supply");
		
		if (mintingProfile[_to].firstMintId == 0) {
		    firstMintIdCounter++;
		    mintingProfile[_to].firstMintId = firstMintIdCounter;
		    mintingProfile[_to].firstMintTimestamp = block.timestamp;
		}
		
		payable(adminAddress).transfer(msg.value / adminShareDivider);
		emit EOBMinted(_to, mintingProfile[_to].firstMintId, _amount);
	}
	
	function mintUser() public payable {
	    mintUserTo(msg.sender);
	}

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EOB::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "EOB::delegateBySig: invalid nonce");
        require(now <= expiry, "EOB::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "EOB::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying EOBs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "EOB::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}