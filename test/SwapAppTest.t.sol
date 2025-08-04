pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SwapApp.sol";

// NOTA: forge coverage a secas es para local, no va a funcionar

contract SwapAppTest is Test {
    SwapApp app;
    address uniswapV2SwapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address uniswapV2SwapFactoryAddress = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    address user = 0xB45323118e29e3C33c4a906dD8ce9d9CF443D380; // Address with USDT in Arbitrum Mainnet
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT address in Arbitrum Mainnet
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI address in Arbitrum Mainnet

    function setUp() public {
        // Para imitar el estado de la red hay que hacer un fork test
        // Fork test: para cuando queremos testear la conexion con un tercero. Es una copia del estado actual de la red real que te la traes a local
        app = new SwapApp(uniswapV2SwapRouterAddress, uniswapV2SwapFactoryAddress, USDT, DAI);
    }

    function testDeployCorrectly() public view {
        assert(app.v2Router02Address() == uniswapV2SwapRouterAddress);

        // RPC: servicios intermediarios para conectarnos a la red
        // Elegimos uno de https://chainlist.org/
        // comando: forge test -vvvv --fork-url https://arb1.arbitrum.io/rpc [--match-test <nombre-del-test>]
        // coverage: forge coverage --fork-url https://arb1.arbitrum.io/rpc
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);

        // !!! OJO: USDT tiene 6 decimales, no 18. Y un mimso token puede tener distinos decimales en cada red
        // Hay que ir a Arbiscan y comprobarlo en "Read as proxy" y buscar la funcion que nos devuelve los decimales
        // https://www.arbiscan.io/token/0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9?a=0x6990e7e90ab50c12111f99b84183d3fe298bb3e4#readProxyContract#F9
        deal(USDT, user, 5 * 1e6); // to make sure the address has enough balance
        uint256 amountIn = 5 * 1e6; // USDT
        // DAI si que tiene 18 decimales
        uint256 amountOutMin = 4 * 1e18; // DAI

        IERC20(USDT).approve(address(app), amountIn);

        // timestmap actual: https://www.unixtimestamp.com/
        uint256 deadline = 1754311863 + 10000000;

        address[] memory path = new address[](2);

        path[0] = USDT;
        path[1] = DAI;

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        app.swapTokens(amountIn, amountOutMin, path, user, deadline);
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);

        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn);
        assert(daiBalanceAfter > daiBalanceBefore + 4);

        vm.stopPrank();
    }

    // Add Liquidity
    function testCanAddLiquidityCorrectly() public {
        deal(USDT, user, 6 * 1e6); // to make sure the address has enough balance

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

    function testRemoveLiquidity() public {
        deal(USDT, user, 6 * 1e6); // to make sure the address has enough balance

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

        assertEq(amountA, 2991105);
        assertEq(amountB, 2983978657583956475);

        vm.stopPrank();
    }
}
