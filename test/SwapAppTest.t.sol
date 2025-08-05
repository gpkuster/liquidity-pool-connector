// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SwapApp.sol";

/// @title SwapAppTest
/// @notice Test suite for the SwapApp contract using a forked Arbitrum mainnet
contract SwapAppTest is Test {
    SwapApp app;

    address uniswapV2SwapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address uniswapV2SwapFactoryAddress = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    address user = 0xB45323118e29e3C33c4a906dD8ce9d9CF443D380; // Address with USDT on Arbitrum Mainnet
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    /// @notice Deploys the SwapApp contract before each test using a forked network
    function setUp() public {
        app = new SwapApp(uniswapV2SwapRouterAddress, uniswapV2SwapFactoryAddress, USDT, DAI);
    }

    /// @notice Verifies that the contract is deployed with the correct router address
    function testDeployCorrectly() public view {
        assert(app.v2Router02Address() == uniswapV2SwapRouterAddress);
    }

    /// @notice Tests the `swapTokens` function to ensure it executes correctly
    function testSwapTokensCorrectly() public {
        vm.startPrank(user);

        deal(USDT, user, 5 * 1e6); // USDT has 6 decimals on Arbitrum

        uint256 amountIn = 5 * 1e6;
        uint256 amountOutMin = 4 * 1e18; // DAI has 18 decimals on Arbitrum

        IERC20(USDT).approve(address(app), amountIn);

        uint256 deadline = 1754311863 + 10000000;

        address[] memory path = new address[](2);

        path[0] = USDT;
        path[1] = DAI;

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);

        app.swapTokens(amountIn, amountOutMin, path, user, deadline);

        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);

        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn, "Balance not increased");
        assert(daiBalanceAfter > daiBalanceBefore + 4); // Sanity check that some DAI was received

        vm.stopPrank();
    }

    /// @notice Tests adding liquidity using USDT and a swapped DAI half
    function testCanAddLiquidityCorrectly() public {
        deal(USDT, user, 6 * 1e6);

        vm.startPrank(user);

        uint256 amountIn_ = 6 * 1e6;
        uint256 amountOutMin_ = 2 * 1e18;
        address[] memory path_ = new address[](2);
        path_[0] = USDT;
        path_[1] = DAI;

        uint256 amountAMin_ = 0;
        uint256 amountBMin_ = 0;
        uint256 deadline_ = 1754311863 + 100000000;

        IERC20(USDT).approve(address(app), amountIn_);

        app.addLiquidity(amountIn_, amountOutMin_, path_, amountAMin_, amountBMin_, deadline_);

        vm.stopPrank();
    }

    /// @notice Tests removing liquidity after adding it to the USDT/DAI pool
    function testRemoveLiquidity() public {
        deal(USDT, user, 6 * 1e6);

        vm.startPrank(user);

        uint256 amountIn_ = 6 * 1e6;
        uint256 amountOutMin_ = 2 * 1e18;
        address[] memory path_ = new address[](2);
        path_[0] = USDT;
        path_[1] = DAI;

        uint256 amountAMin_ = 0;
        uint256 amountBMin_ = 0;
        uint256 deadline_ = 1754311863 + 100000000;

        IERC20(USDT).approve(address(app), amountIn_);

        uint256 lpTokenAdded = app.addLiquidity(amountIn_, amountOutMin_, path_, amountAMin_, amountBMin_, deadline_);

        address lpTokenAddress = IFactory(uniswapV2SwapFactoryAddress).getPair(USDT, DAI);
        IERC20(lpTokenAddress).approve(address(app), lpTokenAdded);

        (uint256 amountA, uint256 amountB) =
            app.removeLiquidity(lpTokenAdded, amountAMin_, amountBMin_, user, deadline_);

        uint256 expectedA = 2991105;
        uint256 expectedB = 2983978657583956475;

        uint256 toleranceA = 1e4; // 0.01 USDT (has 6 decimals)
        uint256 toleranceB = 1e16; // 0.01 DAI (has 18 decimals)

        assertApproxEqAbs(amountA, expectedA, toleranceA, "amountA out of range");
        assertApproxEqAbs(amountB, expectedB, toleranceB, "amountB out of range");


        vm.stopPrank();
    }
}
