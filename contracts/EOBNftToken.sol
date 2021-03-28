// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EOBToken.sol";
import "./libs/IDRNG.sol";

contract EOBNftToken is ERC1155("https://chom.dev"), Ownable {
    // 0000000000000000001 = Box for land
    // 1000001000000000001 = Box for THAI
    // 1000002000000000001 = Box for JAPAN
    // 1000003000000000001 = Box for FRANCE
    // 1000004000000000001 = Box for USA
    
    // 1000001000000000000 = Country THAI
    // 1000002000000000000 = Country JAPAN
    // 1000003000000000000 = Country FRANCE
    // 1000004000000000000 = Country USA
    
    EOBToken token;
    IDRNG drng;
    uint256 pricePerLandBox = 1e22;
    mapping(uint256 => uint256) public itemLength;
    mapping(uint256 => uint256) public itemMaxSupply;
    mapping(uint256 => uint256) public itemSupplyCurrent;
    
    mapping(address => mapping(uint256 => uint256)) public randomBlockNumber;
    mapping(address => mapping(uint256 => uint128)) public randomSeed;
    
    address public SNftMinter;
    
    constructor(
        EOBToken _token,
        IDRNG _drng
    ) public {
        token = _token;
        drng = _drng;
        
        itemLength[1]       = 4;
        itemLength[1000001] = 3;
        itemLength[1000002] = 3;
        itemLength[1000003] = 3;
        itemLength[1000004] = 3;
        
        itemMaxSupply[1]       = 10000;
        itemMaxSupply[1000001] = 10000;
        itemMaxSupply[1000002] = 10000;
        itemMaxSupply[1000003] = 10000;
        itemMaxSupply[1000004] = 10000;
        
        SNftMinter = msg.sender;
    }
    
    function setPricePerLandBox(uint256 _price) public onlyOwner {
        pricePerLandBox = _price;
    }
    
    // Set without timelock is bad practice, but we do it for fast in competition
    function setSNftMinter(address _address) public onlyOwner {
        SNftMinter = _address;
    }
    
    modifier onlySNftMinter {
        require(msg.sender == SNftMinter, "only snft minter");
        _;
    }
    
    function mintUserLandBox(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), pricePerLandBox * amount);
        _mint(msg.sender, 1, amount, "");
        
        randomBlockNumber[msg.sender][1] = drng.getBlockNumber();
        randomSeed[msg.sender][1] = drng.fillRandom();
    }
    
    function _mintUserSNftBox(address _to, uint256 countryId, uint256 amount) internal {
        uint256 tokenId = 1000000000000000000 + countryId * 1000000000000 + 1;
        token.transferFrom(_to, address(this), pricePerLandBox * amount);
        _mint(_to, countryId * tokenId, amount, "");
        
        randomBlockNumber[_to][tokenId] = drng.getBlockNumber();
        randomSeed[_to][tokenId] = drng.fillRandom();
    }
    
    function mintUserSNftBox(address _to, uint256 countryId, uint256 amount) public onlySNftMinter {
        _mintUserSNftBox(_to, countryId, amount);
    }
    
    function openLandBox(uint256 amount) public {
        require(amount > 0, "Cannot open 0 block");
        _burn(msg.sender, 1, amount);
        
        uint256 currentBlockNumber = randomBlockNumber[msg.sender][1];
        uint128 currentSeed = randomSeed[msg.sender][1];
        
        for (uint256 i = 0; i < amount; i++) {
            uint256 rand = drng.getRandom(currentBlockNumber, currentSeed);
            _mint(msg.sender, 1000000000000000000 + (rand % itemLength[1] + 1) * 1000000000000, 1, "");
            currentSeed = drng.fillRandom();
        }
        
        randomBlockNumber[msg.sender][1] = drng.getBlockNumber();
        randomSeed[msg.sender][1] = drng.nextRandom();
    }
    
    function openSNftBox(uint256 _tokenId, uint256 amount) public {
        require(amount > 0, "Cannot open 0 block");
        
        uint256 header = _tokenId / 1000000000000;
        
        require(header > 0, "Must use openLandBox");
        require(header * 1000000000000 + 1 == _tokenId, "Not random box");
        require(itemLength[header] > 0, "Box type not exists");
        require(itemSupplyCurrent[header] < itemMaxSupply[header], "Out of stock");
        
        _burn(msg.sender, _tokenId, amount);
        
        uint256 currentBlockNumber = randomBlockNumber[msg.sender][_tokenId];
        uint128 currentSeed = randomSeed[msg.sender][_tokenId];
        
        for (uint256 i = 0; i < amount; i++) {
            uint256 rand = drng.getRandom(currentBlockNumber, currentSeed);
            _mint(msg.sender, header * 1000000000000 + 2 + (rand % itemLength[header]), 1, "");
            currentSeed = drng.fillRandom();
        }
        
        randomBlockNumber[msg.sender][_tokenId] = drng.getBlockNumber();
        randomSeed[msg.sender][_tokenId] = drng.nextRandom();
    }
    
    
}