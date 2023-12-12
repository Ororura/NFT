// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ERC20.sol";

interface IMint is IERC20 {
    function getRewardCode() external;

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

    struct AssetNFT {
        uint256 idx;
        string name;
        string desc;
        string img;
        uint256 price;
        uint256 amount;
        uint256 releasedAmount;
        uint256 dateCreate;
        int256 collectionId;
    }

    struct AssetSell {
        uint256 assetIdx;
        address seller;
        uint256 amount;
        uint256 price;
    }

    struct CollectionAsset {
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
    mapping(uint256 => bool) assetsInCollectionMap;

    AssetSell[] sellsArray;
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
            userAssetsMap[msg.sender].length,
            _name,
            _desc,
            _img,
            _price,
            _releasedAmount,
            _releasedAmount,
            block.timestamp,
            -1
        );
        userAssetsMap[msg.sender].push(
            AssetNFT(
                userAssetsMap[msg.sender].length,
                _name,
                _desc,
                _img,
                _price,
                _releasedAmount,
                _releasedAmount,
                block.timestamp,
                -1
            )
        );
        assetArray.push(
            AssetNFT(
                assetsNFTMap[assetArray.length].idx,
                _name,
                _desc,
                _img,
                _price,
                _releasedAmount,
                _releasedAmount,
                block.timestamp,
                -1
            )
        );
    }

    function createCollection(
        string memory _name,
        string memory _desc,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external OnlyOwner {
        collectionAssetsMap[collectionArray.length] = CollectionAsset(
            _name,
            _desc,
            _ids,
            _amounts
        );

        collectionArray.push(CollectionAsset(_name, _desc, _ids, _amounts));

        for (uint256 i; i < _ids.length; i++) {
            assetsInCollectionMap[_ids[i]] = true;
        }
    }

    function createRef(string calldata _wallet) external {
        require(
            referralsMap[string.concat("PROFI-", _wallet[2:6], "2024")].owner !=
                msg.sender,
            unicode"Вы уже создали реферал"
        );
        address[] memory mas;
        string memory name = string.concat("PROFI-", _wallet[2:6], "2024");
        referralsMap[name] = ReferralCode(name, msg.sender, 0, mas);
        usersReferralMap[msg.sender] = name;
    }

    function addUsersRef(address _users) external {
        require(
            bytes(usersReferralMap[msg.sender]).length != 0,
            unicode"У вас нет реферала"
        );
        referralsMap[usersReferralMap[msg.sender]].users.push(_users);
    }

    function useReferral(string memory _referral) external {
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
        token.getRewardCode();
        usedRefMap[msg.sender] = true;
        if (referralsMap[_referral].discount < 3) {
            referralsMap[_referral].discount =
                referralsMap[_referral].discount +
                1;
        }
    }

    function sellNFT(
        uint256 _AssetIdx,
        uint256 _amount,
        uint256 _price
    ) external {
        require(
            userAssetsMap[msg.sender][_AssetIdx].releasedAmount >= _amount,
            unicode"У вас недостаточно NFT"
        );
        require(
            assetsInCollectionMap[_AssetIdx] == false,
            unicode"Вы не можете продать NFT из коллекции"
        );
        sellsArray.push(
            AssetSell(_AssetIdx, msg.sender, _amount, _price * dec)
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
            sellsArray[_id].assetIdx,
            _amount,
            ""
        );
        token.transferToken(msg.sender, sellsArray[_id].seller, totalPrice);
        sellsArray[_id].amount -= _amount;
        userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetIdx]
            .releasedAmount -= _amount;
        userAssetsMap[msg.sender].push(
            AssetNFT(
                userAssetsMap[msg.sender].length,
                assetsNFTMap[sellsArray[_id].assetIdx].name,
                assetsNFTMap[sellsArray[_id].assetIdx].desc,
                assetsNFTMap[sellsArray[_id].assetIdx].img,
                _amount,
                _amount,
                sellsArray[_id].price,
                assetsNFTMap[sellsArray[_id].assetIdx].dateCreate,
                assetsNFTMap[sellsArray[_id].assetIdx].collectionId
            )
        );

        if (
            userAssetsMap[sellsArray[_id].seller][sellsArray[_id].assetIdx]
                .releasedAmount == 0
        ) {
            delete userAssetsMap[sellsArray[_id].seller][_id];
        }

        if (sellsArray[_id].amount == 0) {
            delete sellsArray[_id];
        }
    }

    function transferNFT(
        uint256 _id,
        address _receiver,
        uint256 _amount
    ) external {
        safeTransferFrom(msg.sender, _receiver, _id, _amount, "");
        userAssetsMap[msg.sender][_id].amount =
            userAssetsMap[msg.sender][_id].amount -
            _amount;
        userAssetsMap[_receiver].push(
            AssetNFT(
                _id,
                assetsNFTMap[_id].name,
                assetsNFTMap[_id].desc,
                assetsNFTMap[_id].img,
                _amount,
                assetsNFTMap[_id].releasedAmount,
                assetsNFTMap[_id].price,
                assetsNFTMap[_id].dateCreate,
                assetsNFTMap[_id].collectionId
            )
        );
        if (userAssetsMap[msg.sender][_id].amount == 0) {
            delete userAssetsMap[msg.sender][_id];
        }
    }

    function startAuc(
        uint256 _collectionId,
        uint256 _timeStart,
        uint256 _timeEnd,
        uint256 _maxPrice
    ) external OnlyOwner {
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
                _timeStart + block.timestamp,
                _timeEnd + block.timestamp,
                _maxPrice * dec,
                owner,
                10 * dec
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
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].releasedAmount,
                    1 * dec,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].dateCreate,
                    int256(auctionArray[_idx].collectionId)
                )
            );
            assetsInCollectionMap[
                collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
            ] = false;

            delete userAssetsMap[owner][
                assetsNFTMap[
                    collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
                ].idx
            ];
        }
        auctionArray[_idx].leader = address(0);
    }

    function takeNFT(uint256 _idx) public {
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
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].releasedAmount,
                    1 * dec,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].dateCreate,
                    assetsNFTMap[
                        collectionAssetsMap[auctionArray[_idx].collectionId]
                            .ids[i]
                    ].collectionId
                )
            );

            assetsInCollectionMap[
                collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
            ] = false;

            delete userAssetsMap[owner][
                assetsNFTMap[
                    collectionAssetsMap[auctionArray[_idx].collectionId].ids[i]
                ].idx
            ];
        }
        auctionArray[_idx].leader = address(0);
    }

    function bet(uint256 _idx, uint256 _bet)
        external
        CheckAuc(auctionArray[_idx].maxPrice)
    {
        _bet = _bet * dec;
        for (uint256 i = 0; i < betMap[_idx].length; i++) {
            require(
                betMap[_idx][i].owner != msg.sender,
                unicode"Вы уже сделали ставку, вы можете её повысить"
            );
        }
        require(
            auctionArray[_idx].currentBet < _bet,
            unicode"Текущая ставка выше вашей"
        );
        require(_bet >= 10, unicode"Минимальная ставка - 10 PROFI");

        token.transferToken(msg.sender, owner, _bet);
        auctionArray[_idx].currentBet = _bet;
        auctionArray[_idx].leader = msg.sender;
        betMap[_idx].push(Bet(_bet, msg.sender));
        if (_bet >= auctionArray[_idx].maxPrice) {
            auctionArray[_idx].maxPrice = 0;
            takeNFT(_idx);
        }
    }

    function upBet(uint256 _idx, uint256 _amount)
        external
        CheckAuc(auctionArray[_idx].maxPrice)
    {
        _amount = _amount * dec;
        require(_amount >= 10 * dec, unicode"Минимальная ставка - 10 PROFI");
        require(auctionArray[_idx].leader != msg.sender, unicode"Вы уже лидер");
        for (uint256 i = 0; i < betMap[_idx].length; i++) {
            if (betMap[_idx][i].owner == msg.sender) {
                betMap[_idx][i].amount += _amount;
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

    function changeSellPrice(uint256 _idx, uint256 _price) external {
        require(sellsArray[_idx].seller == msg.sender, unicode"Это не ваш лот");
        sellsArray[_idx].price = _price * dec;
    }

    function getSellsArray() public view returns (AssetSell[] memory) {
        return sellsArray;
    }

    function getCollectionAsset()
        external
        view
        returns (CollectionAsset[] memory)
    {
        return collectionArray;
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function getUserReferral() external view returns (string memory) {
        return usersReferralMap[msg.sender];
    }

    function getDiscount(string memory ref) external view returns (uint256) {
        return referralsMap[ref].discount;
    }

    function getUserAssets() external view returns (AssetNFT[] memory) {
        return userAssetsMap[msg.sender];
    }

    function getArrayAsset() public view returns (AssetNFT[] memory) {
        return assetArray;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getBet(uint256 _id) public view returns (Bet[] memory) {
        return betMap[_id];
    }

    function getAuctionArray(uint256 _idx)
        public
        view
        returns (Auction memory)
    {
        return auctionArray[_idx];
    }
}
