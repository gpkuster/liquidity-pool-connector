// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./interfaces/IV2Router02.sol";
import "./interfaces/IFactory.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapApp {
    // SafeERC20 es una libreria, hay que indicar que la vamos a usar y para qué la vamos a usar
    // Gracias a esto podemos usar "safeTransferFrom" en IERC20
    using SafeERC20 for IERC20;

    address public v2Router02Address;
    address public uniswapFactoryAddress;
    address public USDT;
    address public DAI;

    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address tokenA, address tokenB, uint256 lpTokenAmount);

    constructor(address v2Router02Address_, address uniswapFactoryAddress_, address USDT_, address DAI_) {
        v2Router02Address = v2Router02Address_;
        uniswapFactoryAddress = uniswapFactoryAddress_;
        USDT = USDT_;
        DAI = DAI_;
    }
    /**
     * ARBITRAJE: Comprar tokens en un exchange y venderlos en otro
     *     por ejemplo: tenemos uniswap y sushiswap, distintos exhanges pero con la misma pool
     *         -> en sushiswap tienes 5USDT <=> 5DAI, mientras que en uniswap tienes 7USDT <=> 5DAI
     *         -> voy a sushiswap y vendo 5 USDT para obtener 5 DAI, y luego voy a uniswap y cmabio 5 DAI por 7 USDT.
     *         -> gananacia = 2 USDT
     */

    function swapTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        address to_,
        uint256 deadline_
    ) public returns (uint256) {
        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        IERC20(path_[0]).approve(v2Router02Address, amountIn_);
        // amountOutMin: Cantidad minima que estamos dispuestos a recibir. si ponemos 0, podriamos poner 5 USDT y recibir 0.
        //              Si ponemos 3, ese será el minimo a recibir. Si no se cumple, se revierte la transaccion
        // amountIn:
        // path: El camino de pools que tienen que seguir los tokens para hacer el swap
        //          - Ejemplo: queremos cambiar USDT -> WBTC... pool1(USDT -> DAI) -> pool2(DAI -> WETH) -> pool3(WETH -> WBTC)
        //          - Esto se conoce como path de hoops
        //          - La operacion es compleja, pero la gestionan los smart contracts de uniswap
        // to:
        // deadline: Cuando ejecutamos una tx, no se incluye directamente a un bloque de la red blockchain, se queda pendiente en una piscina de txs (mempool)
        //              Luego un validador coge una tx de la mempool y ya la incluye en la red
        //              La deadline es el tiempo que le damos para esperar a que se ejecute la tx
        uint256[] memory amountsOut =
            IV2Router02(v2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, to_, deadline_);

        emit SwapTokens(path_[0], path_[path_.length - 1], amountIn_, amountsOut[amountsOut.length - 1]);

        return amountsOut[amountsOut.length - 1];
    }

    function addLiquidity(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_
    ) external payable returns (uint256) {
        // 1st Swapp Tokens
        uint256 splittedAmountIn = amountIn_ / 2;
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), splittedAmountIn);
        uint256 swappedAmount = swapTokens(splittedAmountIn, amountOutMin_, path_, address(this), deadline_);

        // 2nd Add Liquidity
        IERC20(USDT).approve(v2Router02Address, splittedAmountIn);
        IERC20(DAI).approve(v2Router02Address, swappedAmount);

        (,, uint256 lpTokenAmount) = IV2Router02(v2Router02Address).addLiquidity(
            USDT, DAI, splittedAmountIn, swappedAmount, amountAMin_, amountBMin_, msg.sender, deadline_
        );

        emit AddLiquidity(USDT, DAI, lpTokenAmount);

        return lpTokenAmount;
    }

    function removeLiquidity(
        uint256 liquidityAmount_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        address to_,
        uint256 deadline_
    ) external returns (uint256, uint256) {
        address lpTokenAddress = IFactory(uniswapFactoryAddress).getPair(USDT, DAI);

        // Transfer LP tokens del usuario al contrato
        IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidityAmount_);

        // Aprobar al router para gastar los LP tokens
        IERC20(lpTokenAddress).approve(v2Router02Address, liquidityAmount_);

        // Llamar al router para remover liquidez
        return IV2Router02(v2Router02Address).removeLiquidity(
            USDT, DAI, liquidityAmount_, amountAMin_, amountBMin_, to_, deadline_
        );
    }
}
