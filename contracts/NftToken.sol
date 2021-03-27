// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./EOBToken.sol";
import "./libs/IDRNG.sol";

contract NftToken is ERC1155("https://chom.dev") {
    // 0000000000000000001 = Box for land
    // 1000001000000000001 = Box for THAI
    // 1000002000000000001 = Box for JAPAN
    // 1000003000000000001 = Box for FRANCE
    // 1000004000000000001 = Box for USA
    
    EOBToken token;
    IDRNG drng;
    uint256 pricePerLandBox = 1e22;
    
    mapping(address => mapping(uint256 => uint256)) randomBlockNumber;
    mapping(address => mapping(uint256 => uint128)) randomSeed;
    
    constructor(
        EOBToken _token,
        IDRNG _drng
    ) public {
        token = _token;
        drng = _drng;
    }
    
    function mintUserLandBox(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), pricePerLandBox * amount);
        _mint(msg.sender, 1, amount, "");
        
        randomBlockNumber[msg.sender][1] = drng.getBlockNumber();
        randomSeed[msg.sender][1] = drng.nextRandom();
    }
    
    function _mintUserSNftBox(address _to, uint256 countryId, uint256 amount) internal {
        uint256 tokenId = 1000000000000000000 + countryId * 1000000000000 + 1;
        token.transferFrom(_to, address(this), pricePerLandBox * amount);
        _mint(_to, countryId * tokenId, amount, "");
        
        randomBlockNumber[_to][tokenId] = drng.getBlockNumber();
        randomSeed[_to][tokenId] = drng.nextRandom();
    }
    
    function openLandBox(uint256 amount) public {
        
    }
    
    
}