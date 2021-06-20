/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract Solid is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) public balances;
    mapping (address => uint256) public reward;
    mapping (address => uint256) public stakedBalanceOf;
    mapping(bytes32 => bytes32) public solutionForChallenge;

    uint public stakedBalanceTotal;
    uint public difficulty=1000000000;
    uint public last_update=block.timestamp;
    mapping (address => mapping (address => uint256)) private _allowances;
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
    uint256 public _totalSupply;
    uint public miningTarget;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        //_mint(0x,1000000000*10**18);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function wrap(address recipient, uint256 amount) public {
    //address TITAN = 0x;
    IERC20(TITAN).transferFrom(msg.sender,address(this),amount);
    _mint(recipient,amount);
    }
    function unwrap(address recipient, uint256 amount) public {
    //address TITAN = 0x;
    IERC20(TITAN).transfer(recipient,amount);
    _burn(msg.sender,amount);
    }
    function stake(address recipient, uint256 amount) public {
         //address TITAN = 0x;
         claim(recipient);
         balances[msg.sender] = balances[msg.sender]-amount;
         stakedBalanceOf[recipient] = stakedBalanceOf[recipient]+amount;
         stakedBalanceTotal = stakedBalanceTotal+amount;
    
    }
    
    function unstake(address recipient, uint256 amount) public {
         //address TITAN = 0x;
         claim(recipient);
         balances[msg.sender] = balances[msg.sender]+amount;
         stakedBalanceOf[recipient] = stakedBalanceOf[recipient]-amount;
         stakedBalanceTotal = stakedBalanceTotal-amount;


         
    }
    function claim(address recipient) public{
        //address NEW_TITAN = 0x;
        uint time = (block.timestamp-reward[recipient]);
        uint round = time/1800;
        uint unclaimable = stakedBalanceOf[recipient];
        for (uint i=0;i<round;i++){
            unclaimable = unclaimable*9997626490007817/10000000000000000; //.5^(1/365/24/2*6) 2 months to melt half
        }
        uint claimable = stakedBalanceOf[recipient]-unclaimable;
        stakedBalanceOf[recipient] = stakedBalanceOf[recipient]-claimable;
        stakedBalanceTotal = stakedBalanceTotal-claimable;
        uint reward_calculated = claimable*(10**46)/25276517119618/stakedBalanceTotal/difficulty;
        checkDiff();
        IERC20(NEW_TITAN).transfer(recipient,reward_calculated);
        _resetReward(recipient);
    }
     function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


            //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
            bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce);

            //the challenge digest must match the expected
            if (digest != challenge_digest) revert();

            //the digest must be smaller than the target
            if(uint256(digest) > miningTarget) revert();


            //only allow one reward for each challenge
             bytes32 solution = solutionForChallenge[challengeNumber];
             solutionForChallenge[challengeNumber] = digest;
             if(solution != 0x0) revert();  //prevent the same answer from awarding twice


  

            balances[msg.sender] = balances[msg.sender].add(reward_amount);


  

           return true;

        }
    function redeem(address recipient,uint amount) public{
        //address NEW_TITAN = 0x;
        //address TITAN = 0x;
        IERC20(NEW_TITAN).transferFrom(msg.sender,address(this),amount);
        uint claimable = amount*difficulty*stakedBalanceTotal/(10**46)*25276517119618;
        IERC20(TITAN).transfer(recipient,claimable);
    }
    
    function _resetReward(address to) internal{
        reward[to]=block.timestamp;

    }
    function checkDiff() internal{
        if (block.timestamp-last_update>1800){
        last_update=block.timestamp;
        difficulty = difficulty*1000039563977871/1000000000000000;
        }
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
     function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn to the zero address");

        _beforeTokenTransfer(account, address(0),amount);

        _totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account,address(0), amount);
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}