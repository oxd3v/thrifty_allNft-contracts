// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract Gift20 {
    using SafeMath for uint256;
    //event
    event gifted(
        bytes32 key,
        address[] receivers,
        uint256[] amount,
        address token,
        address sender
    );

    address public owner;
    //auth
    address public authorizer;
    bool public auth;
    mapping(bytes => bool) validSig;

    //taxes
    uint256 public senderTax;
    uint256 public claimtax;
    uint256 decimals = 1000000;

    //re-entrancy
    bool isEntered;

    //angles
    mapping(address => bool) public isAngles;
    mapping(address => bool) public isTaxExempt;

    struct Gift {
        address sender;
        uint256 amount;
        uint256 expireAt;
        address token;
    }

    struct giftBox {
        uint256 amount;
        uint256 index;
    }
   
    mapping(bytes32 => Gift) public gift;
    mapping(address => mapping(bytes32 => giftBox)) public giftBalance;
    mapping(address => bytes32[]) public gifts;
    

    struct ClaimStruct{
        uint claimed;
        uint claimable;
    }
    mapping(address => mapping(address => ClaimStruct)) tokenClaimBal;

    //expiration
    uint256 public exp = 2 * 1 days;

    modifier onlyOwner() {
        require(msg.sender == owner, "GIFT20: OnlyOwner");
        _;
    }

    modifier onlyAngles() {
        require(isAngles[msg.sender], "GIFT20: OnlyAngles");
        _;
    }

    modifier verifySig(bytes32 hash, bytes memory signature) {
        require(validateSig(hash, signature), "Invalid sig");
        _;
    }

    modifier rentrancyGurd() {
        require(!isEntered, "GIFT20: rentrancy err");
        isEntered = true;
        _;
        isEntered = false;
    }

    constructor(){
        owner = msg.sender;
    }

    function validateSig(bytes32 message, bytes memory sig)
        internal
        returns (bool)
    {
        if(auth){
        require( sig.length == 65 && !validSig[sig]);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        address _recoveredAdd = ecrecover(message, v, r, s);
        bool valid = (_recoveredAdd != address(0)) &&
            (_recoveredAdd == authorizer);
        if (valid) {
            validSig[sig] = true;
        }
        return valid;
        }else return true;
    }

    function setAuth(address _authorizer, bool _auth) external onlyOwner {
        authorizer = _authorizer;
        auth = _auth;
    }

    function setAngles(address[] calldata angles, bool permit)
        external
        onlyOwner
    {
        for (uint256 i; i < angles.length; i++) {
            isAngles[angles[i]] = permit;
        }
    }

    function wrapGift(
        address[] calldata receivers,
        uint256[] calldata amounts,
        address token,
        bool tax,
        bytes32 hash,
        bytes memory signature
    ) external rentrancyGurd verifySig(hash, signature) {
        require(receivers.length == amounts.length, "GIFT20: length not match");
        uint256 _spentAmount;
        bytes32 _key = keccak256(
            abi.encodePacked(msg.sender, token, signature)
        );
        gift[_key].sender = msg.sender;
        gift[_key].token = token;
        for (uint256 i; i < receivers.length; i++) {
            giftBalance[receivers[i]][_key].amount = amounts[i];
            //giftBalance[receivers[i]][_key].index = gifts[receivers[i]].length;
            _spentAmount += amounts[i];
        }
        gift[_key].expireAt = block.timestamp.add(exp);
        gift[_key].amount = _spentAmount;
        if (tax && !isTaxExempt[msg.sender]) {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                owner,
                (_spentAmount.mul(senderTax)).div(decimals)
            );
        }
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            _spentAmount
        );
        emit gifted(_key, receivers, amounts, token, msg.sender);
    }

    function claimGiftByKey(
        bytes32 _key,
        bool tax,
        bytes32 hash,
        bytes memory signature
    ) external rentrancyGurd verifySig(hash, signature) {
        uint256 _bal = giftBalance[msg.sender][_key].amount;
        require(
            gift[_key].expireAt > block.timestamp && _bal > 0 && gift[_key].amount >= _bal,
            "GIFt20: Invalid Or expire Gift"
        );
        gift[_key].amount -= _bal;
        delete giftBalance[msg.sender][_key];
        if (tax && !isTaxExempt[msg.sender]) {
            uint256 _tax = (_bal.mul(claimtax)).div(decimals);
            if (_tax > 0)
                TransferHelper.safeTransfer(gift[_key].token, owner, _tax);
            _bal -= _tax;
        }
        TransferHelper.safeTransfer(gift[_key].token, msg.sender, _bal);
    }

    function extendDefaultGift(uint nDays) external onlyOwner  {
        exp = nDays * 1 days;
    }

    function setTaxExempt(address[] calldata _holders, bool action) external onlyOwner {
        for(uint i ; i < _holders.length; i++){
            isTaxExempt[_holders[i]] = action;
        }
    }

    // function claimAll(
    //     bytes32[] calldata _keys,
    //     address[] calldata tokens,
    //     uint[] calldata amounts,
    //     bool tax,
    //     bytes32 hash,
    //     bytes memory signature
    // ) external rentrancyGurd verifySig(hash, signature) {
    //     require(tokens.length == amounts.length)
    //     if(tax && !isTaxExempt[msg.sender]){
    //     for(uint j; j < tokens.length; j++){
    //         uint _tax = ((tokenClaimBal[msg.sender][tokens[j]].claimable).mul(claimtax)).div(decimals);
    //         if(_tax > 0) TransferHelper.safeTransfer(tokens[j], owner, _tax);
    //         TransferHelper.safeTransfer(tokens[j], msg.sender, (tokenClaimBal[msg.sender][tokens[j]].claimable).sub(_tax));
    //         tokenClaimBal[msg.sender][tokens[j]].claimed += tokenClaimBal[msg.sender][tokens[j]].claimable;
    //         tokenClaimBal[msg.sender][tokens[j]].claimable = 0;
    //     }
    //     }else{
    //     for(uint j; j < tokens.length; j++){
    //         TransferHelper.safeTransfer(tokens[j], msg.sender, tokenClaimBal[msg.sender][tokens[j]].claimable);
    //         tokenClaimBal[msg.sender][tokens[j]].claimed += tokenClaimBal[msg.sender][tokens[j]].claimable;
    //         tokenClaimBal[msg.sender][tokens[j]].claimable = 0;
    //     }
    //     }
    //      delete gifts[msg.sender];
    // }

    function extendedGift(
        bytes32 _key,
        uint256 _giftExp,
        bytes32 hash,
        bytes memory signature
    ) external rentrancyGurd verifySig(hash, signature) {
        require(gift[_key].sender == msg.sender, "GIFT20: Invalid Caller");
        gift[_key].expireAt += _giftExp * 1 days;
    }

    function cancelGift(
        bytes32 _key,
        bytes32 hash,
        bool tax,
        bytes memory signature
    ) external rentrancyGurd verifySig(hash, signature) {
        uint256 _bal = gift[_key].amount;
        require(
            gift[_key].sender == msg.sender &&
                _bal > 0,
            "GIFT20: INvalid Caller"
        );
        address coin = gift[_key].token;
        delete gift[_key];
        if (tax) {
            uint256 _tax = (_bal.mul(senderTax)).div(decimals);
            TransferHelper.safeTransfer(coin, owner, _tax);
            _bal -= _tax;
        }
        
        TransferHelper.safeTransfer(coin, msg.sender, _bal);
        
    }

    function setTaxes(uint _senderTax, uint _claimTax, uint _decimals) external onlyOwner {
        decimals = _decimals;
        senderTax = _senderTax;
        claimtax = _claimTax;
    }
}
