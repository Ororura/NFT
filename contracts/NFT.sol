// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ERC20.sol";

interface IMint is IERC20 {
    function getRewrdCode() external;

    function transferToken(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function decimals() external pure returns (uint8);
}

contract NFT is ERC1155("") {
    uint256 dec;
    address owner;
    IMint private token;
    // Добавить id коллекции в структуру нфт

    struct AssetNFT {
        uint256 id;
        uint256 idx;
        string name;
        string desc;
        string img;
        uint256 price;
        uint256 releasedAmount;
        uint256 dateCreate;
    }

    struct AssetSell {
        uint256 id;
        uint256 assetId;
        uint256 assetIdx;
        address seller;
        uint256 amount;
        uint256 price;
    }

    struct CollectionAsset {
        uint256 id;
        string name;
        string desc;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ReferralCode {
        string name;
        address owner;
        uint256 discount;
        address[] users;
    }

    struct Auction {
        uint256 id;
        uint256 collectionId;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 maxPrice;
        address leader;
        uint256 currentBet;
    }

    struct Bet {
        uint256 amount;
        address owner;
    }

    constructor(address _contractAddress) {
        token = IMint(_contractAddress);
        dec = 10**token.decimals();
        owner = msg.sender;

        createNFT(
            unicode"Комочек",
            unicode"Комочек слился с космосом",
            unicode"cat_nft1.png",
            0,
            1
        );
        createNFT(
            unicode"Вкусняшка",
            unicode"Вкусняшка впервые пробует японскую кухню",
            unicode"cat_nft2.png",
            0,
            1
        );
        createNFT(
            unicode"Пузырик",
            unicode"Пузырик похитил котика с Земли",
            unicode"cat_nft3.png",
            0,
            1
        );
        createNFT(
            unicode"Баскетболист",
            unicode"Он идет играть в баскетбол",
            unicode"walker_nft1.png",
            0,
            1
        );
        createNFT(
            unicode"Волшебник",
            unicode"Он идет колдовать",
            unicode"walker_nft2.png",
            0,
            1
        );
    }

    mapping(string => ReferralCode) referralsMap;
    mapping(address => bool) usedRefMap;
    mapping(uint256 => AssetNFT) assetsNFTMap;
    mapping(address => AssetNFT[]) userAssetsMap;
    mapping(uint256 => CollectionAsset) collectionAssetsMap;
    mapping(uint256 => Bet[]) betMap;
    mapping(address => string) usersReferralMap;

    AssetSell[] sellsArray;
    ReferralCode[] referralArray;
    AssetNFT[] assetArray;
    CollectionAsset[] collectionArray;
    Auction[] auctionArray;

    modifier OnlyOwner() {
        require(
            msg.sender == owner,
            unicode"Только владелец может это использовать"
        );
        _;
    }

    modifier CheckAuc(uint256 maxPrice) {
        require(maxPrice != 0, unicode"Аукцион завершён");
        _;
    }

    function checkAucTime(uint256 _idx) public {
        if (
            (block.timestamp - auctionArray[_idx].timeStart) <=
            (block.timestamp - auctionArray[_idx].timeEnd)
        ) {
            takeNFT(_idx);
        }
    }

    function createNFT(
        string memory _name,
        string memory _desc,
        string memory _img,
        uint256 _price,
        uint256 _releasedAmount
    ) public OnlyOwner {
        _mint(msg.sender, assetArray.length, _releasedAmount, "");
        assetsNFTMap[assetArray.length] = AssetNFT(
            assetArray.length,
            userAssetsMap[msg.sender].length,
            _name,
            _desc,
            _img,
            _price,
            _releasedAmount,
            block.timestamp
        );
        userAssetsMap[msg.sender].push(
            AssetNFT(
                assetArray.length,
                userAssetsMap[msg.sender].length,
                _name,
                _desc,
                _img,
                _price,
                _releasedAmount,
                block.timestamp
            )
        );
        assetArray.push(
            AssetNFT(
                assetArray.length,
                userAssetsMap[msg.sender].length,
                _name,
                _desc,
                _img,
                _price,
                _releasedAmount,
                block.timestamp
            )
        );
    }

    function createCollection(
        uint256 _id,
        string memory _name,
        string memory _desc,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public OnlyOwner {
        require(
            collectionAssetsMap[_id].id != _id,
            unicode"Коллекция с таким id уже существует"
        );
        collectionAssetsMap[_id] = CollectionAsset(
            _id,
            _name,
            _desc,
            _ids,
            _amounts
        );
        collectionArray.push(
            CollectionAsset(_id, _name, _desc, _ids, _amounts)
        );
    }

    function createRef(string calldata _wallet) public {
        require(
            referralsMap[string.concat("PROFI-", _wallet[2:6], "2024")].owner !=
                msg.sender,
            unicode"Вы уже создали реферал"
        );
        address[] memory mas;
        string memory name = string.concat("PROFI-", _wallet[2:6], "2024");
        referralsMap[name] = ReferralCode(name, msg.sender, 0, mas);
        referralArray.push(ReferralCode(name, msg.sender, 0, mas));
        usersReferralMap[msg.sender] = name;
    }

    function addUsersRef(address _users) public {
        referralsMap[usersReferralMap[msg.sender]].users.push(_users);
    }

    function useReferral(string memory _referral) public {
        for (uint256 i; i < referralsMap[_referral].users.length; i++) {
            require(
                msg.sender == referralsMap[_referral].users[i],
                unicode"Вы не можете использовать этот код"
            );
        }
        require(
            referralsMap[_referral].owner != msg.sender,
            unicode"Вы не можете использовать свой же код"
        );
        require(
            keccak256(abi.encodePacked(referralsMap[_referral].name)) ==
                keccak256(abi.encodePacked(_referral)),
            unicode"Такого реферального кода нет в системе"
        );
        require(
            usedRefMap[msg.sender] != true,
            unicode"Вы уже использовали код"
        );
        token.getRewrdCode();
        usedRefMap[msg.sender] = true;
        if (referralsMap[_referral].discount < 3) {
            referralsMap[_referral].discount =
                referralsMap[_referral].discount +
                1;
        }
    }

    function sellNFT(
        uint256 _id,
        uint256 _AssetIdx,
        uint256 _amount,
        uint256 _price
    ) external {
        require(
            userAssetsMap[msg.sender][_AssetIdx].releasedAmount >= _amount,
            unicode"У вас недостаточно NFT"
        );
        // Ограничение на продажу коллекций
        // require(condition);
        sellsArray.push(
            AssetSell(
                sellsArray.length,
                _id,
                _AssetIdx,
                msg.sender,
                _amount,
                _price
            )
        );
    }

    function buyNFT(
        uint256 _id,
        uint256 _amount,
        uint256 _discount
    ) external {
        uint256 totalPrice = sellsArray[_id].price *
            _amount -
            ((sellsArray[_id].price * _amount * _discount) / 100);
        require(
            sellsArray[_id].amount >= _amount,
            unicode"Вы пытаетесь купить больше, чем есть"
        );
        _safeTransferFrom(
            sellsArray[_id].seller,
            msg.sender,
            sellsArray[_id].assetId,
            _amount,
            ""
        );
        token.transferToken(msg.sender, sellsArray[_id].seller, totalPrice);
        sellsArray[_id].amount -= _amount;
        userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetId]
            .releasedAmount -= _amount;
        userAssetsMap[msg.sender].push(
            AssetNFT(
                _id,
                userAssetsMap[msg.sender].length,
                assetsNFTMap[sellsArray[_id].assetId].name,
                assetsNFTMap[sellsArray[_id].assetId].desc,
                assetsNFTMap[sellsArray[_id].assetId].img,
                _amount,
                sellsArray[_id].price,
                assetsNFTMap[sellsArray[_id].assetId].dateCreate
            )
        );

        if (
            userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetId]
                .releasedAmount == 0
        ) {
            delete userAssetsMap[sellsArray[_id].seller];
        }

        if (sellsArray[_id].amount == 0) {
            delete sellsArray[_id];
        }
    }

    function transferNFT(
        uint256 _id,
        uint256 _idx,
        address _receiver,
        uint256 _amount
    ) external {
        _safeTransferFrom(msg.sender, _receiver, _id, _amount, "");
        userAssetsMap[msg.sender][_idx].releasedAmount -= _amount;
        userAssetsMap[_receiver].push(
            AssetNFT(
                _id,
                userAssetsMap[_receiver].length,
                assetsNFTMap[_id].name,
                assetsNFTMap[_id].desc,
                assetsNFTMap[_id].img,
                _amount,
                userAssetsMap[msg.sender][_idx].price,
                assetsNFTMap[_id].dateCreate
            )
        );
        if (userAssetsMap[msg.sender][_idx].releasedAmount == 0) {
            delete userAssetsMap[msg.sender][_idx];
        }
    }

    function startAuc(
        uint256 _collectionId,
        uint256 _timeStart,
        uint256 _timeEnd,
        uint256 _maxPrice,
        uint256 _minPrice
    ) public OnlyOwner {
        for (uint256 i; i < auctionArray.length; i++) {
            require(
                auctionArray[i].collectionId != _collectionId,
                unicode"Аукцион с такой коллекцией уже запущен"
            );
        }
        auctionArray.push(
            Auction(
                auctionArray.length,
                _collectionId,
                _timeStart,
                _timeEnd,
                _maxPrice,
                owner,
                _minPrice
            )
        );
    }

    function finishAuc(uint256 _idx) external OnlyOwner {
        _safeBatchTransferFrom(
            owner,
            auctionArray[_idx].leader,
            collectionArray[auctionArray[_idx].collectionId].ids,
            collectionArray[auctionArray[_idx].collectionId].amounts,
            ""
        );
        for (
            uint256 i = 0;
            i < collectionArray[auctionArray[_idx].collectionId].ids.length;
            i++
        ) {
            userAssetsMap[auctionArray[_idx].leader].push(
                AssetNFT(
                    collectionArray[auctionArray[_idx].collectionId].ids[i],
                    userAssetsMap[auctionArray[_idx].leader].length,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].name,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].desc,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].img,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].releasedAmount,
                    1 * dec,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].dateCreate
                )
            );
            delete userAssetsMap[owner][
                assetsNFTMap[
                    collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
                ].idx
            ];
        }
        auctionArray[_idx].leader = address(0);
    }

    function takeNFT(uint256 _idx)
        public
        OnlyOwner
        CheckAuc(auctionArray[_idx].maxPrice)
    {
        require(
            auctionArray[_idx].maxPrice == 0 ||
                auctionArray[_idx].leader == address(0),
            unicode"Аукцион ещё не завершен"
        );
        require(
            auctionArray[_idx].leader == msg.sender,
            unicode"Вы не победитель аукциона "
        );
        _safeBatchTransferFrom(
            owner,
            msg.sender,
            collectionArray[auctionArray[_idx].collectionId].ids,
            collectionArray[auctionArray[_idx].collectionId].amounts,
            ""
        );
        for (
            uint256 i = 0;
            i < collectionArray[auctionArray[_idx].collectionId].ids.length;
            i++
        ) {
            userAssetsMap[msg.sender].push(
                AssetNFT(
                    collectionArray[auctionArray[_idx].collectionId].ids[i],
                    userAssetsMap[auctionArray[_idx].leader].length,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].name,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].desc,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].img,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].releasedAmount,
                    1 * dec,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].dateCreate
                )
            );
            delete userAssetsMap[owner][
                assetsNFTMap[
                    collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
                ].idx
            ];
        }
        auctionArray[_idx].leader = address(0);
    }

    function bet(uint256 _idx, uint256 _bet)
        public
        CheckAuc(auctionArray[_idx].maxPrice)
    {
        require(
            auctionArray[_idx].currentBet < _bet,
            unicode"Текущая ставка выше вашей"
        );
        token.transferToken(msg.sender, owner, _bet);
        auctionArray[_idx].currentBet = _bet;
        auctionArray[_idx].leader = msg.sender;
        betMap[_idx].push(Bet(_bet, msg.sender));
        if (_bet * dec >= auctionArray[_idx].maxPrice) {
            auctionArray[_idx].maxPrice = 0;
            takeNFT(_idx);
        }
    }

    function upBet(uint256 _idx, uint256 _amount)
        public
        CheckAuc(auctionArray[_idx].maxPrice)
    {
        require(_amount >= 10, unicode"Минимальная ставка - 10 PROFI");
        require(auctionArray[_idx].leader != msg.sender, unicode"Вы уже лидер");
        for (uint256 i = 0; i < betMap[_idx].length; i++) {
            if (betMap[_idx][i].owner == msg.sender) {
                betMap[_idx][i].amount += _amount * dec;
                token.transferToken(msg.sender, owner, _amount);

                if (betMap[_idx][i].amount > auctionArray[_idx].currentBet) {
                    auctionArray[_idx].currentBet = betMap[_idx][i].amount;
                    auctionArray[_idx].leader = msg.sender;
                }

                if (betMap[_idx][i].amount >= auctionArray[_idx].maxPrice) {
                    auctionArray[_idx].maxPrice = 0;
                    takeNFT(_idx);
                }
            }
        }
    }

    function changeSellPrice(uint256 _idx, uint256 _price) public {
        require(sellsArray[_idx].seller == msg.sender, unicode"Это не ваш лот");
        sellsArray[_idx].price = _price * dec;
    }

    function getReferrals() public view returns (ReferralCode[] memory) {
        return referralArray;
    }

    function getsellsArray() public view returns (AssetSell[] memory) {
        return sellsArray;
    }

    function getCollectionAsset()
        public
        view
        returns (CollectionAsset[] memory)
    {
        return collectionArray;
    }

    function getAuction() public view returns (Auction[] memory) {
        return auctionArray;
    }

    function getAsset(uint256 _idx) public view returns (AssetNFT memory) {
        return assetsNFTMap[_idx];
    }

    function getUserReferral() public view returns (string memory) {
        return usersReferralMap[msg.sender];
    }

    function _balanceOf() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }
}
