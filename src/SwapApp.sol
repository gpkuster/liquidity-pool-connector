// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/IV2Router02.sol";
import "./interfaces/IV3SwapRouter.sol";
import "./interfaces/IFactory.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SwapApp
/// @author
/// @notice A contract for token swaps and liquidity management using a Uniswap-like protocol
contract SwapApp {
    using SafeERC20 for IERC20;

    address public v2Router02Address;
    address public uniswapFactoryAddress;
    address public swapRouterV3Address;
    address public USDT;
    address public DAI;

    /// @notice Emitted when a token swap is executed
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The amount of input tokens
    /// @param amountOut The amount of output tokens received
    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    /// @notice Emitted when liquidity is added
    /// @param tokenA First token of the pair
    /// @param tokenB Second token of the pair
    /// @param lpTokenAmount Amount of LP tokens received
    event AddLiquidity(address tokenA, address tokenB, uint256 lpTokenAmount);

    /// @param v2Router02Address_ Address of the router contract
    /// @param uniswapFactoryAddress_ Address of the factory contract
    /// @param USDT_ Address of the USDT token
    /// @param DAI_ Address of the DAI token
    constructor(
        address v2Router02Address_,
        address swapRouterV3Address_,
        address uniswapFactoryAddress_,
        address USDT_,
        address DAI_
    ) {
        v2Router02Address = v2Router02Address_;
        uniswapFactoryAddress = uniswapFactoryAddress_;
        swapRouterV3Address = swapRouterV3Address_;
        USDT = USDT_;
        DAI = DAI_;
    }

    /// @notice Swaps tokens using a given path
    /// @dev Assumes approval has been given beforehand
    /// @param amountIn_ The amount of input tokens to swap
    /// @param amountOutMin_ Minimum amount of output tokens expected
    /// @param path_ An array of token addresses defining the swap path
    /// @param to_ Recipient of the output tokens
    /// @param deadline_ Time by which the transaction must be mined
    /// @return The amount of output tokens received
    function swapTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        address to_,
        uint256 deadline_
    ) public returns (uint256) {
        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        IERC20(path_[0]).approve(v2Router02Address, amountIn_);

        uint256[] memory amountsOut =
            IV2Router02(v2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, to_, deadline_);

        emit SwapTokens(path_[0], path_[path_.length - 1], amountIn_, amountsOut[amountsOut.length - 1]);

        return amountsOut[amountsOut.length - 1];
    }

    /// @notice Swaps tokens through Uniswap V3 using a specified path
    /// @dev The caller must approve this contract to spend `amountIn_` of the input token beforehand
    /// @param amountIn_ The amount of input tokens to swap
    /// @param amountOutMin_ The minimum acceptable amount of output tokens (slippage protection)
    /// @param path_ The path of tokens to swap through (at least two addresses)
    /// @param to_ The address to receive the output tokens
    /// @param deadline_ The timestamp by which the swap must be completed
    /// @return amountOut The amount of output tokens received from the swap
    /// @custom:require `path_` length must be at least 2, otherwise it reverts with "Path too short"
    function swapTokensV3(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_, // e.g. [USDT, DAI]
        address to_,
        uint256 deadline_
    ) public returns (uint256 amountOut) {
        require(path_.length >= 2, "Path too short");

        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        IERC20(path_[0]).approve(swapRouterV3Address, amountIn_);

        bytes memory encodedPath = _encodePath(path_);

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
            path: encodedPath,
            recipient: to_,
            deadline: deadline_,
            amountIn: amountIn_,
            amountOutMinimum: amountOutMin_
        });

        amountOut = IV3SwapRouter(swapRouterV3Address).exactInput(params);

        emit SwapTokens(path_[0], path_[path_.length - 1], amountIn_, amountOut);
    }

    /// @notice Encodes a Uniswap V3 multihop swap path
    /// @dev Assumes a fixed fee tier of 0.3% (3000) between each hop
    /// @param path An array of token addresses representing the swap path (at least two tokens)
    /// @return encoded The bytes-encoded path used by the V3 router
    /// @custom:require The path length must be at least 2, otherwise it reverts with "Invalid path"
    function _encodePath(address[] memory path) internal pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(path[0]);
        for (uint256 i = 1; i < path.length; i++) {
            // For simplicity, we hardcode a 0.3% fee tier (3000)
            encoded = bytes.concat(encoded, bytes3(uint24(3000)), bytes20(path[i]));
        }
    }

    /// @notice Swaps tokens and adds liquidity to the USDT/DAI pool
    /// @param amountIn_ Total amount of USDT to use (half will be swapped to DAI)
    /// @param amountOutMin_ Minimum output amount for the swap
    /// @param path_ Path used for the swap
    /// @param amountAMin_ Minimum amount of USDT to add as liquidity
    /// @param amountBMin_ Minimum amount of DAI to add as liquidity
    /// @param deadline_ Transaction deadline
    /// @return lpTokenAmount Amount of LP tokens received
    function addLiquidity(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_
    ) external payable returns (uint256) {
        uint256 splittedAmountIn = amountIn_ / 2;

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), splittedAmountIn);
        uint256 swappedAmount = swapTokens(splittedAmountIn, amountOutMin_, path_, address(this), deadline_);

        IERC20(USDT).approve(v2Router02Address, splittedAmountIn);
        IERC20(DAI).approve(v2Router02Address, swappedAmount);

        (,, uint256 lpTokenAmount) = IV2Router02(v2Router02Address).addLiquidity(
            USDT, DAI, splittedAmountIn, swappedAmount, amountAMin_, amountBMin_, msg.sender, deadline_
        );

        emit AddLiquidity(USDT, DAI, lpTokenAmount);

        return lpTokenAmount;
    }

    /// @notice Removes liquidity from the USDT/DAI pool
    /// @param liquidityAmount_ Amount of LP tokens to burn
    /// @param amountAMin_ Minimum amount of USDT expected
    /// @param amountBMin_ Minimum amount of DAI expected
    /// @param to_ Recipient of the withdrawn tokens
    /// @param deadline_ Transaction deadline
    /// @return amountA Amount of USDT received
    /// @return amountB Amount of DAI received
    function removeLiquidity(
        uint256 liquidityAmount_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        address to_,
        uint256 deadline_
    ) external returns (uint256 amountA, uint256 amountB) {
        address lpTokenAddress = IFactory(uniswapFactoryAddress).getPair(USDT, DAI);

        IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidityAmount_);
        IERC20(lpTokenAddress).approve(v2Router02Address, liquidityAmount_);

        return IV2Router02(v2Router02Address).removeLiquidity(
            USDT, DAI, liquidityAmount_, amountAMin_, amountBMin_, to_, deadline_
        );
    }
}
