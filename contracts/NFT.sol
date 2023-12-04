// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IMint {
    function getRewrdCode() external;
    function transferToken(address _from, address _to, uint _amount) external ;
    function decimals() external pure returns(uint8);
}


contract NFT is ERC1155("") {
    uint dec;
    address owner;
    IMint private token;

    struct Asset {
        uint id;
        uint idx;
        string name;
        string desc;
        string img;
        uint price;
        uint releasedAmount;
        uint dateCreate;
    }

    struct AssetSell {
        uint id;
        uint assetId;
        uint assetIdx;
        address seller;
        uint amount;
        uint price;
    }

    struct CollectionAsset {
        uint id;
        string name;
        string desc;
        uint[] ids;
        uint[] amounts;
    }

    struct ReferralCode {
        string name;
        address owner;
        uint discount;
    }

    struct Auction {
        uint id;
        uint collectionId;
        uint timeStart;
        uint timeEnd;
        uint maxPrice;
        uint minPrice;
        address leader;
        uint currentBet;
    }

    struct Bet {
        uint amount;
        address owner;
    }

    constructor(address _contractAddress) {
        token = IMint(_contractAddress);
        dec = 10 ** token.decimals();
        owner = msg.sender;

        createAsset(0, unicode"Комочек", unicode"Комочек слился с космосом", unicode"cat_nft1.png", 0, 1, block.timestamp);
        createAsset(0, unicode"Вкусняшка", unicode"Вкусняшка впервые пробует японскую кухню", unicode"cat_nft2.png", 0, 1, block.timestamp);
        createAsset(0, unicode"Пузырик", unicode"Пузырик похитил котика с Земли", unicode"cat_nft3.png", 0, 1, block.timestamp);
    }

    mapping (string => ReferralCode) referrals;
    mapping (address => bool) usedRef;
    mapping (uint => Asset) assets;
    mapping (address => Asset[]) userAssets;
    mapping (uint => CollectionAsset) collectionAssets;
    mapping (uint => Bet[]) betMap;


    AssetSell[] sells;
    ReferralCode[] referralArray;
    Asset[] assetArray;
    CollectionAsset[] collectionArray;
    Auction[] auctionArray;


    modifier OnlyOwner() {
        require(msg.sender == owner, unicode"Только владелец может это использовать");
        _;
    }

    modifier CheckAuc(uint maxPrice){
        require(maxPrice != 0, unicode"Аукцион завершён");
        _;
    }

    function createAsset(uint _id, string memory _name, string memory _desc, string memory _img, uint _price, uint _releasedAmount, uint _dateCreate) public OnlyOwner {
        require(assets[_id].price == 0, unicode"NFT с таким id уже есть в системе");
        _mint(msg.sender, _id, _releasedAmount, "");
        assets[_id] = Asset(_id, userAssets[msg.sender].length, _name, _desc, _img, _price, _releasedAmount, _dateCreate);
        userAssets[msg.sender].push(Asset(_id, userAssets[msg.sender].length, _name, _desc, _img, _price, _releasedAmount, _dateCreate));
    }

    function createCollection(uint _id, string memory _name, string memory _desc, uint[] memory _ids, uint[] memory _amounts) public OnlyOwner {
        require(collectionAssets[_id].id != _id, unicode"Коллекция с таким id уже существует");
        _mintBatch(msg.sender, _ids, _amounts, "");
        collectionAssets[_id] = CollectionAsset(_id, _name, _desc, _ids, _amounts);
        collectionArray.push(CollectionAsset(_id, _name, _desc, _ids, _amounts));
    }

    function createRef(string calldata _wallet) public returns(string memory) {
        require(referrals[string.concat("PROFI-", _wallet[2:6],"2024")].owner != msg.sender, unicode"Вы уже создали реферал");
        string memory name = string.concat("PROFI-", _wallet[2:6],"2024");
        referrals[name] = ReferralCode(name, msg.sender, 0);
        referralArray.push(ReferralCode(name,msg.sender, 0));
        return name;
    }

    function useReferral(string memory _referral) public {
        require(keccak256(abi.encodePacked(referrals[_referral].name)) == keccak256(abi.encodePacked(_referral)), unicode"Такого реферального кода нет в системе");
        require(usedRef[msg.sender] != true, unicode"Вы уже использовали код");
        token.getRewrdCode();
        usedRef[msg.sender] = true;
        referrals[_referral].discount = referrals[_referral].discount + 1; 
    }

    function sellAsset(uint _id, uint _AssetIdx, uint _amount, uint _price) external {
        require(userAssets[msg.sender][_AssetIdx].releasedAmount >= _amount, unicode"У вас недостаточно NFT");
        sells.push(AssetSell(sells.length, _id, _AssetIdx, msg.sender, _amount, _price));
    }

    function buyAsset(uint _id, uint _amount, uint _discount) external {
        uint totalPrice = sells[_id].price * _amount - (sells[_id].price * _amount * _discount / 100);
        require(sells[_id].amount >= _amount, unicode"Вы пытаетесь купить больше, чем есть");
        _safeTransferFrom(sells[_id].seller, msg.sender, sells[_id].assetId, _amount, "");
        token.transferToken(msg.sender, sells[_id].seller, totalPrice);
        sells[_id].amount -= _amount;
        userAssets[sells[_id].seller][sells[_id].assetId].releasedAmount -= _amount;
        userAssets[msg.sender].push(Asset(_id, userAssets[msg.sender].length, assets[sells[_id].assetId].name, assets[sells[_id].assetId].desc, assets[sells[_id].assetId].img, _amount, sells[_id].price, assets[sells[_id].assetId].dateCreate));

        if(userAssets[sells[_id].seller][sells[_id].assetId].releasedAmount == 0) {
            delete userAssets[sells[_id].seller];
        }

        if(sells[_id].amount == 0) {
            delete sells[_id];
        }
    }

    function transferAsset(uint _id, uint _idx, address _receiver, uint _amount) external {
        _safeTransferFrom(msg.sender, _receiver, _id, _amount, "");
        userAssets[msg.sender][_idx].releasedAmount -= _amount;
        userAssets[_receiver].push(Asset(_id, userAssets[_receiver].length, assets[_id].name, assets[_id].desc, assets[_id].img, _amount, userAssets[msg.sender][_idx].price, assets[_id].dateCreate));
        if(userAssets[msg.sender][_idx].releasedAmount == 0) {
            delete userAssets[msg.sender][_idx];
        }
    }

    function startAuc(uint _collectionId, uint _timeStart, uint _timeEnd, uint maxPrice, uint minPrice, address leader, uint currentBet) public OnlyOwner{
        for(uint i; i < auctionArray.length; i++) {
            require(auctionArray[i].collectionId != _collectionId, unicode"Аукцион с такой коллекцией уже запущен");
        }
        auctionArray.push(Auction(auctionArray.length, _collectionId, _timeStart, _timeEnd, maxPrice, minPrice, leader, currentBet));
    }

    function finishAuc(uint _idx) external OnlyOwner {
        _safeBatchTransferFrom(owner, auctionArray[_idx].leader, collectionArray[auctionArray[_idx].collectionId].ids, collectionArray[auctionArray[_idx].collectionId].amounts, "");
        for(uint i = 0; i < collectionArray[auctionArray[_idx].collectionId].ids.length; i++) {
            userAssets[auctionArray[_idx].leader].push(Asset(collectionArray[auctionArray[_idx].collectionId].ids[i], userAssets[auctionArray[_idx].leader].length, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].name, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].desc, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].img, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].releasedAmount, 1 * dec, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].dateCreate));
            delete userAssets[owner][assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].idx];
        }
        auctionArray[_idx].leader = address(0);
    }

    function takeNFT(uint _idx) public OnlyOwner CheckAuc(auctionArray[_idx].maxPrice){
        require(auctionArray[_idx].maxPrice == 0 || auctionArray[_idx].leader == address(0), unicode"Аукцион ещё не завершен");
        require(auctionArray[_idx].leader == msg.sender, unicode"Вы не победитель аукциона ");
        _safeBatchTransferFrom(owner, msg.sender, collectionArray[auctionArray[_idx].collectionId].ids, collectionArray[auctionArray[_idx].collectionId].amounts, "");
        for(uint i = 0; i < collectionArray[auctionArray[_idx].collectionId].ids.length; i++) {
            userAssets[msg.sender].push(Asset(collectionArray[auctionArray[_idx].collectionId].ids[i], userAssets[auctionArray[_idx].leader].length, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].name, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].desc, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].img, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].releasedAmount, 1 * dec, assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].dateCreate));
            delete userAssets[owner][assets[collectionAssets[auctionArray[_idx].collectionId].ids[i]].idx];
        }
        auctionArray[_idx].leader = address(0);
    }

    function bid(uint _idx, uint _bet) public CheckAuc(auctionArray[_idx].maxPrice) {
        require(auctionArray[_idx].currentBet < _bet, unicode"Текущая ставка выше вашей");
        token.transferToken(msg.sender, owner, _bet);
        auctionArray[_idx].currentBet = _bet;
        auctionArray[_idx].leader = msg.sender;
        betMap[_idx].push(Bet(_bet, msg.sender));
        if(_bet * dec >= auctionArray[_idx].maxPrice){
            auctionArray[_idx].maxPrice = 0;
            takeNFT(_idx);
        }
    }

    function upBid(uint _idx, uint _amount) public CheckAuc(auctionArray[_idx].maxPrice) {
        require(_amount >= 10, unicode"Минимальная ставка - 10 PROFI");
        require(auctionArray[_idx].leader != msg.sender, unicode"Вы уже лидер");
        for(uint i = 0; i < betMap[_idx].length; i++) {
            if(betMap[_idx][i].owner == msg.sender) {
                betMap[_idx][i].amount += _amount * dec;
                token.transferToken(msg.sender, owner, _amount);

                if(betMap[_idx][i].amount > auctionArray[_idx].currentBet){
                    auctionArray[_idx].currentBet = betMap[_idx][i].amount;
                    auctionArray[_idx].leader = msg.sender;
                }

                if(betMap[_idx][i].amount >= auctionArray[_idx].maxPrice) {
                    auctionArray[_idx].maxPrice = 0;
                    takeNFT(_idx);
                }
            }
        }
    }

    function changeSellPrice(uint _idx, uint _price) public {
        require(sells[_idx].seller == msg.sender, unicode"Это не ваш лот");
        sells[_idx].price = _price * dec;
    }

    function getReferrals() public view returns(ReferralCode[] memory) {
        return referralArray;
    }

    function getSells() public view returns(AssetSell[] memory) {
        return sells;
    }

    function getAsset() public view returns(Asset[] memory) {
        return assetArray;
    }

    function getCollectionAsset() public view returns(CollectionAsset[] memory) {
        return collectionArray;
    }

    function getAuction() public view returns(Auction[] memory) {
        return auctionArray;
    }


}
