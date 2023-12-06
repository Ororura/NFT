// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ERC20.sol";

interface IMint is IERC20 {
    function getRewrdCode() external;
    function transferToken(address _from, address _to, uint _amount) external ;
    function decimals() external pure returns(uint8);
}


contract NFT is ERC1155("") {
    uint dec;
    address owner;
    IMint private token;
    // Добавить id коллекции в структуру нфт

    struct AssetNFT {
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
        address[] users;
    }

    struct Auction {
        uint id;
        uint collectionId;
        uint timeStart;
        uint timeEnd;
        uint maxPrice;
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

        createNFT(1, unicode"Комочек", unicode"Комочек слился с космосом", unicode"cat_nft1.png", 0, 1);
        createNFT(2, unicode"Вкусняшка", unicode"Вкусняшка впервые пробует японскую кухню", unicode"cat_nft2.png", 0, 1);
        createNFT(3, unicode"Пузырик", unicode"Пузырик похитил котика с Земли", unicode"cat_nft3.png", 0, 1);
        createNFT(4, unicode"Баскетболист", unicode"Он идет играть в баскетбол", unicode"walker_nft1.png", 0, 1);
        createNFT(5, unicode"Волшебник", unicode"Он идет колдовать", unicode"walker_nft2.png", 0, 1);
    }

    mapping (string => ReferralCode) referralsMap;
    mapping (address => bool) usedRefMap;
    mapping (uint => AssetNFT) assetsNFTMap;
    mapping (address => AssetNFT[]) userAssetsMap;
    mapping (uint => CollectionAsset) collectionAssetsMap;
    mapping (uint => Bet[]) betMap;
    mapping (address => string) usersReferralMap;


    AssetSell[] sellsArray;
    ReferralCode[] referralArray;
    AssetNFT[] assetArray;
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

    function checkAucTime(uint _idx) public {
        if((block.timestamp - auctionArray[_idx].timeStart) <= (block.timestamp - auctionArray[_idx].timeEnd)) {
            takeNFT(_idx);
        }
    }

    function createNFT(uint _id, string memory _name, string memory _desc, string memory _img, uint _price, uint _releasedAmount) public OnlyOwner {
        require(assetsNFTMap[_id].price == 0, unicode"NFT с таким id уже есть в системе");
        _mint(msg.sender, _id, _releasedAmount, "");
        assetsNFTMap[_id] = AssetNFT(_id, userAssetsMap[msg.sender].length, _name, _desc, _img, _price, _releasedAmount, block.timestamp);
        userAssetsMap[msg.sender].push(AssetNFT(_id, userAssetsMap[msg.sender].length, _name, _desc, _img, _price, _releasedAmount, block.timestamp));
    }

    function createCollection(uint _id, string memory _name, string memory _desc, uint[] memory _ids, uint[] memory _amounts) public OnlyOwner {
        require(collectionAssetsMap[_id].id != _id, unicode"Коллекция с таким id уже существует");
        collectionAssetsMap[_id] = CollectionAsset(_id, _name, _desc, _ids, _amounts);
        collectionArray.push(CollectionAsset(_id, _name, _desc, _ids, _amounts));
    }

    function createRef(string calldata _wallet) public {
        require(referralsMap[string.concat("PROFI-", _wallet[2:6],"2024")].owner != msg.sender, unicode"Вы уже создали реферал");
        address[] memory mas;
        string memory name = string.concat("PROFI-", _wallet[2:6],"2024");
        referralsMap[name] = ReferralCode(name, msg.sender, 0, mas);
        referralArray.push(ReferralCode(name,msg.sender, 0, mas));
        usersReferralMap[msg.sender] = name;
    }

    function addUsersRef(address _users) public {
        referralsMap[usersReferralMap[msg.sender]].users.push(_users);
    }

    function useReferral(string memory _referral) public {
        for(uint i; i < referralsMap[_referral].users.length; i++) {
            require(msg.sender == referralsMap[_referral].users[i], unicode"Вы не можете использовать этот код");
        }
        require(referralsMap[_referral].owner != msg.sender, unicode"Вы не можете использовать свой же код");
        require(keccak256(abi.encodePacked(referralsMap[_referral].name)) == keccak256(abi.encodePacked(_referral)), unicode"Такого реферального кода нет в системе");
        require(usedRefMap[msg.sender] != true, unicode"Вы уже использовали код");
        token.getRewrdCode();
        usedRefMap[msg.sender] = true;
        if(referralsMap[_referral].discount < 3) {
            referralsMap[_referral].discount = referralsMap[_referral].discount + 1; 
        }
    }

    function sellNFT(uint _id, uint _AssetIdx, uint _amount, uint _price) external {
        require(userAssetsMap[msg.sender][_AssetIdx].releasedAmount >= _amount, unicode"У вас недостаточно NFT");
        // Ограничение на продажу коллекций
        // require(condition); 
        sellsArray.push(AssetSell(sellsArray.length, _id, _AssetIdx, msg.sender, _amount, _price));
    }

    function buyNFT(uint _id, uint _amount, uint _discount) external {
        uint totalPrice = sellsArray[_id].price * _amount - (sellsArray[_id].price * _amount * _discount / 100);
        require(sellsArray[_id].amount >= _amount, unicode"Вы пытаетесь купить больше, чем есть");
        _safeTransferFrom(sellsArray[_id].seller, msg.sender, sellsArray[_id].assetId, _amount, "");
        token.transferToken(msg.sender, sellsArray[_id].seller, totalPrice);
        sellsArray[_id].amount -= _amount;
        userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetId].releasedAmount -= _amount;
        userAssetsMap[msg.sender].push(AssetNFT(_id, userAssetsMap[msg.sender].length, assetsNFTMap[sellsArray[_id].assetId].name, assetsNFTMap[sellsArray[_id].assetId].desc, assetsNFTMap[sellsArray[_id].assetId].img, _amount, sellsArray[_id].price, assetsNFTMap[sellsArray[_id].assetId].dateCreate));

        if(userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetId].releasedAmount == 0) {
            delete userAssetsMap[sellsArray[_id].seller];
        }

        if(sellsArray[_id].amount == 0) {
            delete sellsArray[_id];
        }
    }

    function transferNFT(uint _id, uint _idx, address _receiver, uint _amount) external {
        _safeTransferFrom(msg.sender, _receiver, _id, _amount, "");
        userAssetsMap[msg.sender][_idx].releasedAmount -= _amount;
        userAssetsMap[_receiver].push(AssetNFT(_id, userAssetsMap[_receiver].length, assetsNFTMap[_id].name, assetsNFTMap[_id].desc, assetsNFTMap[_id].img, _amount, userAssetsMap[msg.sender][_idx].price, assetsNFTMap[_id].dateCreate));
        if(userAssetsMap[msg.sender][_idx].releasedAmount == 0) {
            delete userAssetsMap[msg.sender][_idx];
        }
    }

    function startAuc(uint _collectionId, uint _timeStart, uint _timeEnd, uint _maxPrice, uint _minPrice) public OnlyOwner{
        for(uint i; i < auctionArray.length; i++) {
            require(auctionArray[i].collectionId != _collectionId, unicode"Аукцион с такой коллекцией уже запущен");
        }
        auctionArray.push(Auction(auctionArray.length, _collectionId, _timeStart, _timeEnd, _maxPrice, owner, _minPrice));
    }

    function finishAuc(uint _idx) external OnlyOwner {
        _safeBatchTransferFrom(owner, auctionArray[_idx].leader, collectionArray[auctionArray[_idx].collectionId].ids, collectionArray[auctionArray[_idx].collectionId].amounts, "");
        for(uint i = 0; i < collectionArray[auctionArray[_idx].collectionId].ids.length; i++) {
            userAssetsMap[auctionArray[_idx].leader].push(AssetNFT(collectionArray[auctionArray[_idx].collectionId].ids[i], userAssetsMap[auctionArray[_idx].leader].length, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].name, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].desc, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].img, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].releasedAmount, 1 * dec, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].dateCreate));
            delete userAssetsMap[owner][assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].idx];
        }
        auctionArray[_idx].leader = address(0);
    }

    function takeNFT(uint _idx) public OnlyOwner CheckAuc(auctionArray[_idx].maxPrice){
        require(auctionArray[_idx].maxPrice == 0 || auctionArray[_idx].leader == address(0), unicode"Аукцион ещё не завершен");
        require(auctionArray[_idx].leader == msg.sender, unicode"Вы не победитель аукциона ");
        _safeBatchTransferFrom(owner, msg.sender, collectionArray[auctionArray[_idx].collectionId].ids, collectionArray[auctionArray[_idx].collectionId].amounts, "");
        for(uint i = 0; i < collectionArray[auctionArray[_idx].collectionId].ids.length; i++) {
            userAssetsMap[msg.sender].push(AssetNFT(collectionArray[auctionArray[_idx].collectionId].ids[i], userAssetsMap[auctionArray[_idx].leader].length, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].name, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].desc, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].img, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].releasedAmount, 1 * dec, assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].dateCreate));
            delete userAssetsMap[owner][assetsNFTMap[collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]].idx];
        }
        auctionArray[_idx].leader = address(0);
    }

    function bet(uint _idx, uint _bet) public CheckAuc(auctionArray[_idx].maxPrice) {
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

    function upBet(uint _idx, uint _amount) public CheckAuc(auctionArray[_idx].maxPrice) {
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
        require(sellsArray[_idx].seller == msg.sender, unicode"Это не ваш лот");
        sellsArray[_idx].price = _price * dec;
    }

    function getReferrals() public view returns(ReferralCode[] memory) {
        return referralArray;
    }

    function getsellsArray() public view returns(AssetSell[] memory) {
        return sellsArray;
    }

    function getCollectionAsset() public view returns(CollectionAsset[] memory) {
        return collectionArray;
    }

    function getAuction() public view returns(Auction[] memory) {
        return auctionArray;
    }

    function getAsset(uint _idx) public view returns(AssetNFT memory) {
        return assetsNFTMap[_idx];
    }

    function getUserReferral() public view returns(string memory) {
        return usersReferralMap[msg.sender];
    }


}
