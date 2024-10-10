// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

interface IMarketFactory {
    function _tokenIds() external view returns (uint256);

    function uri(uint256 tokenId) external view returns (string memory);

    function setSize(uint256 _size) external;

    function setCollectionInfo(string memory _uri) external;

    function setMarketplace(address _marketplace) external;

    function setFNFTMarketplace(address _marketplace) external;

    function setServiceMarketplace(address _marketplace) external;

    function transferOwnership(address newOwner) external;

    function initialize(address newOnwer) external;

    //function userInfo(uint256 tokenId) external view returns(uint8, uint8, address, uint, address);

    function setTier0(address _tier0) external;

    function fNFTMarketplace() external view returns (address);

    function serviceMarketplace() external view returns (address);

    function tier0Contract() external view returns (address);

    function getUserInfo(uint256 tokenId)
        external
        view
        returns (
            uint8 royaltyFee,
            uint8 royaltyShare,
            uint8 nftType,
            address tier0,
            address admin
        );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function getUserInfo(uint256 tokenId)
        external
        view
        returns (
            uint8 royaltyFee,
            uint8 royaltyShare,
            uint8 nftType,
            uint256 tier0Cnt,
            address admin
        );
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Detective {
    function isERC721(address _contract) public view returns (uint256) {
        if (IERC165(_contract).supportsInterface(type(IERC1155).interfaceId)) {
            return 1;
        } else if (
            IERC165(_contract).supportsInterface(type(IERC721).interfaceId)
        ) {
            return 2;
        } else {
            return 3;
        }
    }
}

interface IOwnerable {
    function owner() external view returns (address);
}

interface IRedeemAndFee {
    function accumulateTransactionFee(
        address user,
        uint256 royaltyFee,
        uint256 amount
    )
        external
        returns (
            uint256 transactionFee,
            uint256,
            uint256 income
        );

    function unCliamedReward(address user)
        external
        view
        returns (uint256 amount);

    function claim(address user) external;

    function getBlackList(address user) external view returns (bool);

    function unclassifiedList(address user) external view returns (bool);

    function flatFee() external view returns (uint256);

    function ableToViewALLPrivateMetadata(address user)
        external
        view
        returns (bool);
}

contract Main is Ownable, CloneFactory {
    using SafeERC20 for IERC20;
    address public authorizer;
    bool public isAuthorizedEnable;
    address public key;
    address public marketFactory;
    address public redeemAndFee;
    Detective detect;
    address immutable WAVAX; // = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;     // for test
    address public treasury;

    struct PutOnSaleInfo {
        address maker;
        address collectionId;
        uint256 tokenId;
        uint256 amount;
        uint8 royaltyFee;
        uint8 royaltyShare;
        address admin;
        address coin;
        uint256 price;
        AuctionInfo[] auctionInfo;
        bool isAlive;
        uint256 expirate;
        uint256 nftType;
    }

    struct AuctionInfo {
        address taker;
        uint256 price;
        uint256 amount;
    }


    enum EscrowStateType {
        ES_OPEN,
        ES_PROCESS,
        ES_RELEASED,
        ES_CLAIMED,
        ES_DISPUTE_OPEN,
        ES_DISPUTE_PROCESS,
        ES_DISPUTE_SOLVED,
        ES_DISPUTE_DECLINED
    }

    struct EscrowInfo {
        bytes32 key;
        uint256 amount;
        uint256 price;
        address buyer;
        EscrowStateType state;
        uint256 createdAt;
    }

    mapping(address => address[]) public userCollectionInfo;

    mapping(bytes32 => PutOnSaleInfo) listInfo;
    mapping(address => uint8) royaltyFeeForExternal;
    // bytes32[] public hashList;

    mapping(uint256 => EscrowInfo) public escrowList;
    mapping(address => uint256[]) public userEscrowList;
    uint256 public escrowIndex = 0;
    uint256 public disputeDuration = 86400;

    mapping(address => bool) private _manageAccess;

    enum ContractType {
        ERC1155,
        ERC721,
        Unknown
    }

    event CreateCollection(address indexed collectionId);
    event PutOnSaleEvent(
        bytes32 _key,
        uint256 amount,
        uint8 royaltyFee,
        uint8 royaltyShare,
        address admin,
        address coin,
        uint256 price,
        uint256 exp
    );
    // event TradingNFT(uint256 amount, uint256 price, uint256 income, address maker, address taker, uint256 remain);
    event TradingNFT(
        uint256 amount,
        uint256 price,
        uint256 income,
        address maker,
        address taker
    );
    event RoyaltyHistory(uint256 royaltyFee, address admin, uint256 remain);

    event EscrowCreated(
        uint256 id,
        bytes32 key,
        uint256 amount,
        uint256 price,
        address buyer
    );
    event EscrowReleased(uint256 id);
    event EscrowDisputeOpened(uint256 id);
    event EscrowDisputeSolved(uint256 id);
    event EscrowDisputeDeclined(uint256 id);

    modifier isBlackList() {
        require(
            false == IRedeemAndFee(redeemAndFee).getBlackList(msg.sender),
            "Main:blackLiser"
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == owner() || _manageAccess[msg.sender],
            "!manager"
        );
        _;
    }

    bool isEntered;

    modifier reentrancyGurd() {
        require(isEntered == false, "Main: Reentrancy");
        isEntered = true;
        _;
        isEntered = false;
    }

    mapping(bytes => bool) inValidSig;
    modifier onlySigAuth(bytes32 message, bytes memory sig) {
        if(isAuthorizedEnable){
        require(inValidSig[sig] == false && recoverSigner(message, sig));
        inValidSig[sig] = true;
        }
        _;
    }

    constructor(address _WAVAX) {
        detect = new Detective();
        WAVAX = _WAVAX;
    }

    // function _makeHash(
    //     address user,
    //     address collectionId,
    //     uint256 tokenId
    // ) private pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(user, collectionId, tokenId));
    // }

    function setTreasury(address wallet, address _key) external onlyOwner {
        treasury = wallet;
         key = _key;
    }

    function setMarketFactory(address factory, address _reddem) external onlyOwner {
        marketFactory = factory;
        redeemAndFee = _reddem;
    }

    function setDisputeDuration(uint256 _duration) public onlyManager {
        disputeDuration = _duration;
    }

    function setManager(address usraddress, bool access) public onlyOwner {
        if (access == true) {
            if (!_manageAccess[usraddress]) {
                _manageAccess[usraddress] = true;
            }
        } else {
            if (_manageAccess[usraddress]) {
                delete _manageAccess[usraddress];
            }
        }
    }

    function creatCollection(
        string memory collectionMetadata,
        uint256 size,
        bytes32 massage,
        bytes calldata sig
    ) external payable isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        if (msg.sender != owner())
            require(
                msg.value == IRedeemAndFee(redeemAndFee).flatFee(),
                "Main: insur flat fee"
            );
        address subFactory = createClone(marketFactory);
        userCollectionInfo[msg.sender].push(subFactory);
        IMarketFactory(subFactory).initialize(address(this));
        IMarketFactory(subFactory).setSize(size);
        IMarketFactory(subFactory).setCollectionInfo(collectionMetadata);
        IMarketFactory(subFactory).setMarketplace(address(this));
        IMarketFactory(subFactory).setFNFTMarketplace(
            IMarketFactory(marketFactory).fNFTMarketplace()
        );
        IMarketFactory(subFactory).setServiceMarketplace(
            IMarketFactory(marketFactory).serviceMarketplace()
        );
        IMarketFactory(subFactory).setTier0(
            IMarketFactory(marketFactory).tier0Contract()
        );
        IMarketFactory(subFactory).transferOwnership(msg.sender);
        payable(treasury).transfer(msg.value);
        emit CreateCollection(subFactory);
    }

    function putOnSale(
        address collectionId,
        uint256 tokenId,
        address coin,
        uint256 amount,
        uint256 price,
        uint8 royaltyFee,
        bool setRoyaltyFee,
        address user,
        uint256 exp, // expirate time (unit days)
        bytes32 massage,
        bytes calldata sig
    ) external payable isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        {
            //to avoiding stack too deep err.........
            address _collectionId = collectionId;
            uint256 _id = tokenId;
            address _coin = coin;
            uint256 _amount = amount;
            uint256 _price = price;
            uint8 _royaltyFee = royaltyFee;
            bool _setRoyaltyFee = setRoyaltyFee;
            address _user = user;
            uint256 _exp = exp;
            _putOnSell(
                _user,
                _collectionId,
                _id,
                _coin,
                _amount,
                _price,
                _royaltyFee,
                _setRoyaltyFee,
                _exp
            );
        }
        
    }

    function _putOnSell(
        address user,
        address _collectinId,
        uint256 _id,
        address coin,
        uint256 amount,
        uint256 price,
        uint8 royaltyFee,
        bool setRoyaltyFee,
        uint256 exp
    ) private {
        if (user != msg.sender)
            require(
                IRedeemAndFee(redeemAndFee).ableToViewALLPrivateMetadata(
                    msg.sender
                ),
                "Main:no angel"
            );
        address collectionOwner = detectOwner(_collectinId);
        if (user != collectionOwner)
            require(
                msg.value == IRedeemAndFee(redeemAndFee).flatFee(),
                "Main:wrong flatfee"
            );
        require(_detect(_collectinId) != ContractType.Unknown, "Main: No nft");
        bytes32 _key = keccak256(abi.encodePacked(user, _collectinId, _id));
        require(
            !listInfo[_key].isAlive ||
                (listInfo[_key].isAlive &&
                    listInfo[_key].expirate < block.timestamp &&
                    listInfo[_key].expirate != 0),
            "Main: alreay listed"
        );
        if (
            listInfo[_key].maker == address(0) &&
            listInfo[_key].collectionId == address(0)
        ) {
            // hashList.push(_key);
            listInfo[_key].maker = user;
            listInfo[_key].collectionId = _collectinId;
            listInfo[_key].tokenId = _id;
        }
        listInfo[_key].coin = coin;
        listInfo[_key].amount = amount;
        listInfo[_key].price = price;
        listInfo[_key].isAlive = true;
        listInfo[_key].expirate = exp > 0 ? block.timestamp + exp * 1 days : 0;

        // (, , uint256 nftType, , ) = IMarketFactory(marketFactory).getUserInfo(
        //     tokenId
        // );
        // listInfo[_key].nftType = nftType;
        if (setRoyaltyFee) {
            // if (_detect(collectionId) == ContractType.ERC721)
            require(collectionOwner == user, "Main:721-no owner");
            // else if(_detect(collectionId) == ContractType.ERC1155)
            //     require(IERC1155(collectionId).balanceOf(user, tokenId) >= amount, "Main:1155-no owner");
            royaltyFeeForExternal[user] = royaltyFee;
            // listInfo[_key].royaltyFee = royaltyFee;
            // if(msg.sender == user)
            //     listInfo[_key].royaltyShare = royaltyShare;
            // else listInfo[_key].royaltyShare = 50;
            // listInfo[_key].admin = msg.sender;
        }

        if (collectionOwner != address(0) && royaltyFeeForExternal[user] != 0) {
            // But when the original contract owner will come and verify and set the roatlity fee...
            listInfo[_key].admin = collectionOwner;
            listInfo[_key].royaltyFee = royaltyFeeForExternal[user];
        }
        _putonSaleFor1155(_key, _collectinId, _id); //when not our own marketfactory or this is from external ERC721, default royaltyFee is 5%
        if (msg.sender != user) {
            // lazy mode
            listInfo[_key].royaltyShare = 50; // 50% will go treasury and the other %50 fee will go to the nft angel
            listInfo[_key].admin = msg.sender; // NFT angel
        }
        if (msg.value > 0) payable(treasury).transfer(msg.value);
        emit PutOnSaleEvent(
            _key,
            listInfo[_key].amount,
            listInfo[_key].royaltyFee,
            listInfo[_key].royaltyShare,
            listInfo[_key].admin,
            listInfo[_key].coin,
            listInfo[_key].price,
            listInfo[_key].expirate
        );
    }

    function _putonSaleFor1155(
        bytes32 _key,
        address collectionId,
        uint256 tokenId
    ) private {
        try IERC1155(collectionId).getUserInfo(tokenId) returns (
            uint8 _royaltyFee,
            uint8 _royaltyShare,
            uint8 nftType,
            uint256,
            address admin
        ) {
            require(nftType != 2 && nftType != 1, "Main:Invalid trade");
            //require(nftType != 1, "Main:FNFT no trade here");
            listInfo[_key].royaltyFee = _royaltyFee;
            listInfo[_key].royaltyShare = _royaltyShare;
            listInfo[_key].admin = admin;
            listInfo[_key].nftType = nftType;
        } catch {
            listInfo[_key].royaltyFee = 5;
            listInfo[_key].royaltyShare = 100;
        }
    }

    function cancelList(
        bytes32 _key,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList onlySigAuth(massage, sig) {
        require(
            listInfo[_key].maker == msg.sender && listInfo[_key].isAlive,
            "Main:not owner"
        );
        listInfo[_key].isAlive = false;
        listInfo[_key].expirate = 0;
    }

    function _detect(address _contract)
        private
        view
        returns (ContractType _type)
    {
        try (detect).isERC721(_contract) returns (uint256 result) {
            if (result == 1) return _type = ContractType.ERC721;
            else if (result == 2) return _type = ContractType.ERC1155;
        } catch {
            return _type = ContractType.Unknown;
        }
    }

    function detectOwner(address _contract) public view returns (address) {
        try IOwnerable(_contract).owner() returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }

    function auction(
        bytes32 _key,
        uint256 price,
        uint256 amount,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        require(listInfo[_key].maker != msg.sender && amount * price > 0,"Main:IV user or amount");
        //require(amount * price > 0, "Main:IV amount");
        require(
            listInfo[_key].isAlive &&
                listInfo[_key].expirate >= block.timestamp,
            "Main:IV hash id"
        );
        require(listInfo[_key].amount >= amount, "Main:overflow");

        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        bool isExist;
        uint256 oldValue;
        for (uint256 i = 0; i < auctionInfoList.length; i++) {
            if (auctionInfoList[i].taker == msg.sender) {
                oldValue = auctionInfoList[i].price * auctionInfoList[i].amount;
                auctionInfoList[i].price = price;
                auctionInfoList[i].amount = amount;
                isExist = true;
                break;
            }
        }
        if (!isExist) {
            AuctionInfo memory auctionInfo = AuctionInfo({
                taker: msg.sender,
                price: price,
                amount: amount
            });
            listInfo[_key].auctionInfo.push(auctionInfo);
        }

        address coin = listInfo[_key].coin;
        if (amount * price > oldValue) {
            IERC20(coin).safeTransferFrom(
                msg.sender,
                address(this),
                amount * price - oldValue
            );
        } else if (amount * price < oldValue) {
            IERC20(coin).safeTransfer(msg.sender, oldValue - amount * price);
        }
    }

    function cancelAuction(
        bytes32 _key,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        uint256 amount = 0;
        uint256 price = 0;
        for (uint256 i = 0; i < auctionInfoList.length; i++) {
            if (auctionInfoList[i].taker == msg.sender) {
                amount = auctionInfoList[i].amount;
                price = auctionInfoList[i].price;
                auctionInfoList[i] = auctionInfoList[
                    auctionInfoList.length - 1
                ];
                auctionInfoList.pop();
                break;
            }
        }
        require(amount > 0, "Main:invalid user"); 
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransfer(msg.sender, amount * price);
    }

    function buyNow(
        bytes32 _key,
        uint256 _amount,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList reentrancyGurd onlySigAuth(massage, sig) {      
        require(listInfo[_key].maker != address(this), "Main:unlisted");
        require(
            listInfo[_key].maker != msg.sender &&
                listInfo[_key].isAlive &&
                listInfo[_key].expirate >= block.timestamp,
            "Main:IV maker"
        );
        require(listInfo[_key].amount >= _amount, "Main:overflow");
        require(listInfo[_key].nftType != 3, "Main:Buy pri.Nft  via Escrow");
        _trading(_key, _amount, listInfo[_key].price, msg.sender, true, false);
    }

    function buyViaEscrow(
        bytes32 _key,
        uint256 _amount,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        require(listInfo[_key].maker != address(this), "Main:unlisted");
        require(
            listInfo[_key].maker != msg.sender &&
                listInfo[_key].isAlive &&
                listInfo[_key].expirate >= block.timestamp,
            "Main:IV maker"
        );
        require(listInfo[_key].amount >= _amount, "Main:overflow");
        require(listInfo[_key].nftType == 3, "Main: only private nft");
        _trading(_key, _amount, listInfo[_key].price, msg.sender, true, true);
    }

    function releaseEscrow(uint256 id) external isBlackList {
        require(
            msg.sender == escrowList[id].buyer ||
                msg.sender == owner() ||
                _manageAccess[msg.sender],
            "Main: IV buyer or manager"
        );
        escrowList[id].state = EscrowStateType.ES_RELEASED;
    }

    function claimEscrow(uint256 id) external isBlackList reentrancyGurd {
        require(
            escrowList[id].state == EscrowStateType.ES_RELEASED || 
            escrowList[id].createdAt + disputeDuration < block.timestamp && 
            escrowList[id].state == EscrowStateType.ES_DISPUTE_OPEN,
            "Main: IV escrow is not released yet"
        );
        bytes32 _key = escrowList[id].key;
        require(
            msg.sender == listInfo[_key].maker ||
                msg.sender == owner() ||
                _manageAccess[msg.sender],
            "Main: IV maker or manager"
        );

        address user = escrowList[id].buyer;
        uint256 amount = escrowList[id].amount;
        uint256 price = escrowList[id].price;
        address coin = listInfo[_key].coin;
        (, uint256 royaltyAmount, uint256 income) = IRedeemAndFee(redeemAndFee)
            .accumulateTransactionFee(
                user,
                listInfo[_key].royaltyFee,
                amount * price
            );
        IERC20(coin).safeTransfer(listInfo[_key].maker, income);
        if (
            listInfo[_key].admin != address(0) &&
            100 > listInfo[_key].royaltyShare
        ) {
            IERC20(coin).safeTransfer(
                listInfo[_key].admin,
                (royaltyAmount * (100 - listInfo[_key].royaltyShare)) / 100
            );
        }
        IERC20(coin).safeTransfer(
            treasury,
            (royaltyAmount * listInfo[_key].royaltyShare) / 100
        );
        // emit TradingNFT(amount, price, income, listInfo[_key].maker, user, listInfo[_key].amount);
        emit TradingNFT(amount, price, income, listInfo[_key].maker, user);
        emit RoyaltyHistory(
            royaltyAmount,
            listInfo[_key].admin,
            listInfo[_key].amount
        );
        escrowList[id].state = EscrowStateType.ES_CLAIMED;
    }

    function openDisputEscrow(uint256 id) external isBlackList {
        require(msg.sender == escrowList[id].buyer, "Main: IV buyer");
        require(
            escrowList[id].createdAt + disputeDuration >= block.timestamp,
            "Main: IV dispute is late"
        );
        escrowList[id].state = EscrowStateType.ES_DISPUTE_OPEN;
    }

    function declineDisputEscrow(uint256 id) external {
        require(
            msg.sender == escrowList[id].buyer ||
                msg.sender == owner() ||
                _manageAccess[msg.sender],
            "Main: IV not buyer or manager"
        );
        escrowList[id].state = EscrowStateType.ES_DISPUTE_DECLINED;
    }

    function solveDisputEscrow(
        uint256 id,
        uint256 percent,
        bool refundNFT
    ) external onlyManager reentrancyGurd {
        bytes32 _key = escrowList[id].key;
        address user = escrowList[id].buyer;
        uint256 amount = escrowList[id].amount;
        uint256 price = escrowList[id].price;
        uint256 totalAmount = amount * price;
        uint256 refundAmout = (totalAmount * percent) / 10000;
        uint256 releaseAmout = totalAmount - refundAmout;
        address coin = listInfo[_key].coin;
        (, uint256 royaltyAmount, uint256 income) = IRedeemAndFee(redeemAndFee)
            .accumulateTransactionFee(
                user,
                listInfo[_key].royaltyFee,
                releaseAmout
            );
        IERC20(coin).safeTransfer(listInfo[_key].maker, income);
        if (
            listInfo[_key].admin != address(0) &&
            100 > listInfo[_key].royaltyShare
        ) {
            IERC20(coin).safeTransfer(
                listInfo[_key].admin,
                (royaltyAmount * (100 - listInfo[_key].royaltyShare)) / 100
            );
        }
        IERC20(coin).safeTransfer(
            treasury,
            (royaltyAmount * listInfo[_key].royaltyShare) / 100
        );
        IERC20(coin).safeTransfer(user, refundAmout);

        if (refundNFT) {
            if (_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
                IERC721(listInfo[_key].collectionId).safeTransferFrom(
                    user,
                    listInfo[_key].maker,
                    listInfo[_key].tokenId
                );
            } else if (
                _detect(listInfo[_key].collectionId) == ContractType.ERC1155
            ) {
                IERC1155(listInfo[_key].collectionId).safeTransferFrom(
                    user,
                    listInfo[_key].maker,
                    listInfo[_key].tokenId,
                    amount,
                    ""
                );
            }
        }

        escrowList[id].state = EscrowStateType.ES_DISPUTE_SOLVED;
    }

    function _trading(
        bytes32 _key,
        uint256 _amount,
        uint256 _price,
        address user,
        bool isBuyNow,
        bool isEscrow
    ) private {
        if (_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
            require(
                IERC721(listInfo[_key].collectionId).ownerOf(
                    listInfo[_key].tokenId
                ) == listInfo[_key].maker,
                "Main:no721 owner"
            );
            _exchangeDefaultNFT(
                _key,
                _amount,
                _price,
                user,
                isBuyNow,
                isEscrow
            );
        } else if (
            _detect(listInfo[_key].collectionId) == ContractType.ERC1155
        ) {
            try
                IERC1155(listInfo[_key].collectionId).getUserInfo(
                    listInfo[_key].tokenId
                )
            returns (uint8, uint8, uint8 nftType, uint256, address) {
                require(nftType != 2, "Main:cant trade");
                require(nftType != 1, "Main:cant trade here");
                // if(nftType == 0 || nftType == 3 || nftType == 4) {      // default NFT or Tier0 NFT or PRIVATE NFT
                //     _amount = _dealwithOverflowAmount(_key, _amount, _price, user, isBuyNow, isEscrow);
                // } else if (nftType == 1) { // FNFT
                //     _tradingFNFT(_key, user);
                //     return;
                // }

                _amount = _dealwithOverflowAmount(
                    _key,
                    _amount,
                    _price,
                    user,
                    isBuyNow,
                    isEscrow
                );
            } catch {
                _amount = _dealwithOverflowAmount(
                    _key,
                    _amount,
                    _price,
                    user,
                    isBuyNow,
                    isEscrow
                );
            }
        }

        listInfo[_key].amount -= _amount;
        // if(listInfo[_key].amount == 0) {
        //     listInfo[_key].maker = address(0);
        //     listInfo[_key].collectionId = address(0);
        //     listInfo[_key].tokenId = 0;
        // }
    }

    function _dealwithOverflowAmount(
        bytes32 _key,
        uint256 _amount,
        uint256 _price,
        address user,
        bool isBuyNow,
        bool isEscrow
    ) private returns (uint256) {
        uint256 balance = IERC1155(listInfo[_key].collectionId).balanceOf(
            listInfo[_key].maker,
            listInfo[_key].tokenId
        );
        if (balance < _amount) {
            _amount = balance;
            listInfo[_key].amount = _amount;
        }
        _exchangeDefaultNFT(_key, _amount, _price, user, isBuyNow, isEscrow);
        return _amount;
    }

    function _exchangeDefaultNFT(
        bytes32 _key,
        uint256 amount,
        uint256 price,
        address user,
        bool isBuyNow,
        bool isEscrow
    ) private {
        require(amount * price > 0, "Main:insuf 1155");
        address coin = listInfo[_key].coin;
        if (isBuyNow)
            IERC20(coin).safeTransferFrom(user, address(this), amount * price);

        (, uint256 royaltyAmount, uint256 income) = IRedeemAndFee(redeemAndFee)
            .accumulateTransactionFee(
                user,
                listInfo[_key].royaltyFee,
                amount * price
            );

        if (isEscrow) {
            escrowList[escrowIndex] = EscrowInfo(
                _key,
                amount,
                price,
                user,
                EscrowStateType.ES_OPEN,
                block.timestamp
            );
            userEscrowList[user].push(escrowIndex);
            emit EscrowCreated(escrowIndex, _key, amount, price, user);
            emit TradingNFT(amount, price, income, listInfo[_key].maker, user);
            emit RoyaltyHistory(
                royaltyAmount,
                listInfo[_key].admin,
                listInfo[_key].amount
            );
            escrowIndex = escrowIndex + 1;
        } else {
            IERC20(coin).safeTransfer(listInfo[_key].maker, income);
            if (
                listInfo[_key].admin != address(0) &&
                100 > listInfo[_key].royaltyShare
            ) {
                // if royalty admin has been set
                IERC20(coin).safeTransfer(
                    listInfo[_key].admin,
                    (royaltyAmount * (100 - listInfo[_key].royaltyShare)) / 100
                );
            }
            IERC20(coin).safeTransfer(
                treasury,
                (royaltyAmount * listInfo[_key].royaltyShare) / 100
            ); //
            // emit TradingNFT(amount, price, income, listInfo[_key].maker, user, listInfo[_key].amount);
            emit TradingNFT(amount, price, income, listInfo[_key].maker, user);
            emit RoyaltyHistory(
                royaltyAmount,
                listInfo[_key].admin,
                listInfo[_key].amount
            );
        }
        if (_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
            IERC721(listInfo[_key].collectionId).safeTransferFrom(
                listInfo[_key].maker,
                user,
                listInfo[_key].tokenId
            );
        } else if (
            _detect(listInfo[_key].collectionId) == ContractType.ERC1155
        ) {
            IERC1155(listInfo[_key].collectionId).safeTransferFrom(
                listInfo[_key].maker,
                user,
                listInfo[_key].tokenId,
                amount,
                ""
            );
        }
    }

    function makeOffer(
        bytes32 _key,
        address taker,
        bytes32 massage,
        bytes calldata sig
    ) external isBlackList reentrancyGurd onlySigAuth(massage, sig) {
        require(
            listInfo[_key].isAlive && msg.sender == listInfo[_key].maker,
            "Main:not maker"
        );
        bool isExist = false;
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        for (uint256 i = 0; i < auctionInfoList.length; i++) {
            if (auctionInfoList[i].taker == taker) {
                uint256 _amount = auctionInfoList[i].amount;
                uint256 _price = auctionInfoList[i].price;
                if(listInfo[_key].nftType == 3) _trading(_key, _amount, _price, taker, false, true);
                else _trading(_key, _amount, _price, taker, false, false);
                auctionInfoList[i] = auctionInfoList[
                    auctionInfoList.length - 1
                ];
                auctionInfoList.pop();
                isExist = true;
                break;
            }
        }
        require(isExist, "Main:no user");
    }

    function claim() external isBlackList reentrancyGurd{
        uint256 reward = IRedeemAndFee(redeemAndFee).unCliamedReward(
            msg.sender
        );
        require(reward > 0, "Main:no reward");
        IRedeemAndFee(redeemAndFee).claim(msg.sender);
        IERC20(WAVAX).safeTransfer(msg.sender, reward);
    }

    function _unClassifiedList(address user) private view returns (bool) {
        return IRedeemAndFee(redeemAndFee).unclassifiedList(user);
    }

    function ListInfo(bytes32 _key)
        external
        view
        returns (
            PutOnSaleInfo memory info,
            AuctionInfo[] memory auctionInfo,
            bool isValid
        )
    {
        if (_unClassifiedList(listInfo[_key].maker)) {
            return (info, auctionInfo, false);
        }
        auctionInfo = new AuctionInfo[](listInfo[_key].auctionInfo.length);
        auctionInfo = listInfo[_key].auctionInfo;
        return (listInfo[_key], auctionInfo, true);
    }

    function withdrawTokens(
        address coin,
        address user,
        uint256 amount
    ) external onlyOwner {
        IERC20(coin).safeTransfer(user, amount);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        view
        returns (bool)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        address _recoveredAdd = ecrecover(message, v, r, s);
        require(_recoveredAdd != address(0), "recovered signer fail");
        return _recoveredAdd == authorizer;
    }

    function setAuthorizer(address _auth, bool enable) external onlyManager {
        authorizer = _auth;
        isAuthorizedEnable = enable;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
