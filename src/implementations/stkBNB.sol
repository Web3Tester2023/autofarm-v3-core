// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import "../libraries/Uniswap.sol";

import "../StratX4_Masterchef.sol";
import {LP1EarnConfig, StratX4LibEarn} from "../libraries/StratX4LibEarn.sol";

import "../../constants/tokens.sol";

address constant LP_TOKEN = 0xaA2527ff1893e0D40d4a454623d362B79E8bb7F1; // WBNB-stkBNB
address constant TOKEN_BASE = WBNB;
address constant TOKEN_OTHER = 0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16; // stkBNB
address constant REWARD = CAKE;
address constants REWARD_BASE_PAIR = CAKE_BNB_PAIR;
bytes4 constant pendingRewardSelector =
  bytes4(keccak256(abi.encodePacked("pendingCake(uint256,address)")));

address constant dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
address constant dexFarm = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
uint256 constant pcsV2SwapFee = 9975;
uint256 constant PID = 114;

contract StratX4_WBNB_stkBNB is StratX4_Masterchef {
  using SafeTransferLib for ERC20;

  constructor(FeeConfig memory _feeConfig, Authority _authority)
    StratX4_Masterchef(
      LP_TOKEN,
      REWARD,
      dexFarm,
      PID,
      pendingRewardSelector,
      _feeConfig,
      _authority
    )
  {}

  function compound(uint256 earnedAmt)
    internal
    override
    returns (uint256 assets)
  {
    ERC20(earnedAddress).safeTransfer(REWARD_BASE_PAIR, earnedAmt);
    uint256 baseAmount = Uniswap._swap(
      REWARD_BASE_PAIR, pcsV2SwapFee, CAKE, TOKEN_BASE, earnedAmt, address(this)
    );
    uint256 zapSwapAmount;
    uint256 tokenOtherAmountOut;
    (zapSwapAmount, tokenOtherAmountOut) =
      Uniswap.calcSimpleZap(LP_TOKEN, pcsV2SwapFee, baseAmount, TOKEN_BASE, TOKEN_OTHER);

    assets = Uniswap.oneSidedSwap(
      LP_TOKEN,
      zapSwapAmount,
      tokenOtherAmountOut,
      TOKEN_BASE,
      TOKEN_OTHER,
      baseAmount,
      address(this)
    );
  }
TOKEN_BASE  /*
   * Oracles
   */
  function ethToWant() public view override returns (uint256) {
    address[] memory baseToEthPath = new address[](0);

    return StratX4LibEarn._ethToWantLP1(
      asset, TOKEN_BASE, TOKEN_OTHER, dexRouter, baseToEthPath
    );
  }

  function rewardToWant() public view override returns (uint256) {
    address[] memory baseToRewardPath = new address[](2);
    baseToRewardPath[0] = TOKEN_BASE;
    baseToRewardPath[1] = REWARD;

    return StratX4LibEarn._rewardToWantLP1(
      asset, TOKEN_BASE, TOKEN_OTHER, dexRouter, baseToRewardPath
    );
  }
}
