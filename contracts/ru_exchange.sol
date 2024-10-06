// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import './interfaces/IERC20.sol';
import './interfaces/IExchange.sol';

contract RUExchange is IExchange {
    // State variables
    IERC20 private token; // ERC20 token used for the exchange
    uint256 private tokenReserve; // Reserve of the ERC20 token
    uint256 private ethReserve; // Reserve of ETH
    uint8 private feePercent; // Percentage fee for each trade
    mapping(address => uint256) private _balances; // Balances of liquidity tokens
    uint256 private _totalSupply; // Total supply of liquidity tokens

    function grade_exchange() pure public returns (bool) {
        return false;
    }

    constructor() {
        // TODO: implement
    }

    // Return the underlying token contract
    function getToken() external view override returns (IERC20) {
        return token;
    }


    // Initialize the exchange
    function initialize(IERC20 _RUXtoken, uint8 _feePercent, uint initialTOK, uint initialETH) external payable override returns (uint) {
        require(msg.value >= initialETH, "Not enough ETH");
        require(tokenReserve == 0 && ethReserve == 0, "Already initialized");

        token = _RUXtoken;
        feePercent = _feePercent;

        // Transfer the initial token supply from the sender to the exchange
        token.transferFrom(msg.sender, address(this), initialTOK);

        tokenReserve = initialTOK;
        ethReserve = initialETH;

        // Mint liquidity tokens
        uint liquidity = initialTOK; // Equal to the initial number of tokens
        _mint(msg.sender, liquidity);
        return liquidity;
    }


    /**
     * @dev Swap ETH for tokens.
     * Buy `amount` tokens as long as the total price is at most `maxPrice`. revert if this is impossible.
     * Note that the fee is taken in *both* tokens and ETH. The fee percentage is taken from `amount` tokens 
     * (rounded up) *after* they are bought, and taken from the ETH sent (rounded up) *before* the purchase.
     * @return Returns the actual total cost in ETH including fee.
     */
    // Buy tokens using ETH
    function buyTokens(uint amount, uint maxPrice) external payable override returns (uint, uint, uint) {
        require(amount > 0, "Must buy at least one token");
        require(msg.value > 0, "ETH required to buy tokens");



        uint ethFee = (msg.value * feePercent) / 100;

        uint ethForSwap = msg.value - ethFee;
        

        uint tokenAmount = (tokenReserve * ethForSwap) / (ethReserve + ethForSwap);
        require(tokenAmount >= amount, "Not enough liquidity");


        uint tokenFee = (amount * feePercent) / 100;
        uint tokensToTransfer = amount - tokenFee;

        require(maxPrice >= ethForSwap, "ETH exceeds max price");

        // Transfer the purchased tokens to the buyer
        token.transfer(msg.sender, tokensToTransfer);

        // Update reserves
        tokenReserve -= amount;
        ethReserve += ethForSwap;

        // Emit the fee details event
        emit FeeDetails(msg.value, ethFee, tokenFee);

        return (msg.value, ethFee, tokenFee);
    }

    /**
     * @dev Swap tokens for ETH
     * Sell `amount` tokens as long as the total price is at least `minPrice`. revert if this is impossible.
     * Note that the fee is taken in *both* tokens and ETH. The fee percentage is taken from `amount` tokens 
     * (rounded up) *before* selling, and taken from the ETH returned (rounded up) *after* selling.
     * @return Returns a tuple with the actual total value in ETH minus the fee, the eth fee and the token fee.
     */
    // Sell tokens for ETH
    function sellTokens(uint amount, uint minPrice) external override returns (uint, uint, uint) {
        require(amount > 0, "Must sell at least one token");

        uint tokenFee = (amount * feePercent) / 100;
        uint tokensForSwap = amount - tokenFee;

        uint ethAmount = (ethReserve * tokensForSwap) / (tokenReserve + tokensForSwap);
        uint ethFee = (ethAmount * feePercent) / 100;
        uint ethToTransfer = ethAmount - ethFee;

        require(ethToTransfer >= minPrice, "ETH below minimum price");

        // Transfer tokens to the contract
        token.transferFrom(msg.sender, address(this), amount);

        // Transfer ETH to the seller
        payable(msg.sender).transfer(ethToTransfer);

        // Update reserves
        tokenReserve += tokensForSwap;
        ethReserve -= ethAmount;

        // Emit the fee details event
        emit FeeDetails(ethAmount, ethFee, tokenFee);

        return (ethAmount, ethFee, tokenFee);
    }

   // Return the current number of tokens in the liquidity pool
    function tokenBalance() external view override returns (uint) {
        return tokenReserve;
    }

    
    /**
     * @dev mint `amount` liquidity tokens, as long as the total number of tokens spent is at most `maxTOK`
     * and the total amount of ETH spent is `maxETH`. The token allowance for the exchange address must be at least `maxTOK`,
     * and the msg value at least `maxETH`.
     * Unused funds will be returned to the sender.
     * @return returns a tuple consisting of (token_spent, eth_spent). 
     */
    function mintLiquidityTokens(uint amount, uint maxTOK, uint maxETH) external payable override returns (uint, uint) {
        require(msg.value >= maxETH, "Insufficient ETH");

        uint tokenAmount = (tokenReserve * amount) / _totalSupply;
        uint ethAmount = (ethReserve * amount) / _totalSupply;

        require(tokenAmount <= maxTOK && ethAmount <= msg.value, "Too much token or ETH");

        // Transfer tokens to the pool
        token.transferFrom(msg.sender, address(this), tokenAmount);

        // Mint liquidity tokens to the sender
        _mint(msg.sender, amount);

        // Update reserves
        tokenReserve += tokenAmount;
        ethReserve += msg.value;

        emit MintBurnDetails(tokenAmount, ethAmount);
        return (tokenAmount, ethAmount);
    }

    /**
     * @dev burn `amount` liquidity tokens, as long as this will result in at least minTOK tokens and at least minETH eth being generated.
     * The resulting tokens and ETH will be credited to the sender.
     * @return Returns a tuple consisting of (token_credited, eth_credited). 
     */
    function burnLiquidityTokens(uint amount, uint minTOK, uint minETH) external payable override returns (uint, uint) {
        require(_balances[msg.sender] >= amount, "Insufficient liquidity tokens");

        uint tokenAmount = (tokenReserve * amount) / _totalSupply;
        uint ethAmount = (ethReserve * amount) / _totalSupply;

        require(tokenAmount >= minTOK && ethAmount >= minETH, "Too little token or ETH");

        // Burn liquidity tokens from the sender
        _burn(msg.sender, amount);

        // Transfer ETH and tokens to the sender
        payable(msg.sender).transfer(ethAmount);
        token.transfer(msg.sender, tokenAmount);

        // Update reserves
        tokenReserve -= tokenAmount;
        ethReserve -= ethAmount;

        emit MintBurnDetails(tokenAmount, ethAmount);
        return (tokenAmount, ethAmount);
    }
    
     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return 0; // Liquidity tokens are not directly spendable by others in this version
    }

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
    function approve(address spender, uint256 amount) external override returns (bool) {
        return false; // Liquidity tokens are not directly approved in this version
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external override returns (bool) {
        return false; // Liquidity tokens are not directly transferable by others in this version
    }

    // Get ethReserve
    function getEthReserve() public view returns (uint256) {
        return ethReserve;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal function to burn liquidity tokens
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        require(_balances[account] >= amount, "Burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }
   
}
