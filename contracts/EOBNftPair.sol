pragma solidity 0.6.12;

import "./libs/BEP20.sol";
import "./EOBToken.sol";
import "./EOBNftToken.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

contract EOBNftPair is BEP20, ERC1155Holder {
    event EOBNftPairMinted(address indexed to, uint256 amount);
    event EOBNftPairBurned(address indexed burner, uint256 amount, uint256 output);
    
    EOBToken public eob;
    EOBNftToken public nft;
    uint256 public eobMultiplier;
    uint256 public tokenId;
    
    constructor(
        EOBToken _eob,
        EOBNftToken _nft,
        uint256 _eobMultiplier,
        uint256 _tokenId,
        string memory _name,
        string memory _symbol
    ) public BEP20(_name, _symbol) {
        eob = _eob;
        nft = _nft;
        eobMultiplier = _eobMultiplier;
        tokenId = _tokenId;
    }
    
	// Minting mechanism to mint pair of EOB and ERC1155 NFT
	function mintUserTo(address _to, uint256 _amount) public {
        nft.safeTransferFrom(_to, address(this), tokenId, _amount, "");
        eob.transferFrom(_to, address(this), _amount * eobMultiplier);
	    
		_mint(_to, _amount * 1e18);
		
		emit EOBNftPairMinted(_to, _amount);
	}
	
	function mintUser(uint256 _amount) public {
	    mintUserTo(msg.sender, _amount);
	}
	
	// Burning mechanism
	function burn(uint256 _amount) public {
	    nft.safeTransferFrom(address(this), msg.sender, tokenId, _amount, "");
	    
	    // Prevent rouding error
	    uint256 eobToSend = _amount * eobMultiplier;
	    if (eobToSend > eob.balanceOf(address(this))) {
	        eobToSend = eob.balanceOf(address(this));
	    }
	    
	    _burn(msg.sender, _amount * 1e18);
	    
	    eob.transfer(msg.sender, eobToSend);
	    
	    emit EOBNftPairBurned(msg.sender, _amount, eobToSend);
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