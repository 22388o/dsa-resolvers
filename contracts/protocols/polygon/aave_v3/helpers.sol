//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract AaveV3Helper is DSMath {
    // ----------------------- USING LATEST ADDRESSES -----------------------------

    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     *@dev Returns WETH address
     */
    function getWMaticAddr() internal pure returns (address) {
        return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //Polygon mainnet WMatic Address
    }

    function getUiDataProvider() internal pure returns (address) {
        return 0x8F1AD487C9413d7e81aB5B4E88B024Ae3b5637D0; //polygon UiPoolDataProvider Address
    }

    /**
     *@dev Returns Pool AddressProvider Address
     */
    function getPoolAddressProvider() internal pure returns (address) {
        return 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb; //Polygon Mainnet PoolAddressesProvider address
    }

    /**
     *@dev Returns Pool DataProvider Address
     */
    function getPoolDataProvider() internal pure returns (address) {
        return 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654; //Polygon Mainnet PoolDataProvider address
    }

    /**
     *@dev Returns Aave Data Provider Address
     */
    function getAaveDataProvider() internal pure returns (address) {
        return 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654; //Polygon mainnet address
    }

    function getAaveIncentivesAddress() internal pure returns (address) {
        return 0xdA609ee88e40194803A27222b009FC9EbC75f725; //Polygon IncentivesProxyAddress
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0xb023e699F5a33916Ea823A16485e259257cA8Bd1; //Polygon address
    }

    /**
     *@dev Returns StableDebtToken Address
     */
    function getStableDebtToken() internal pure returns (address) {
        return 0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e; //Polygon address
    }

    function getChainLinkFeed() internal pure returns (address) {
        return 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    }

    function getUiIncetivesProvider() internal view returns (address) {
        return 0x05E309C97317d8abc0f7e78185FC966FfbD2CEC0;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        // uint256 baseInUSD;   //TODO
        string symbol;
    }

    struct Token {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    struct ReserveAddresses {
        Token aToken;
        Token stableDebtToken;
        Token variableDebtToken;
    }

    struct EmodeData {
        // uint256[] price;
        EModeCategory data;
    }

    struct AaveV3UserTokenData {
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        uint256 price; //price of token in base currency
        Flags flag;
    }

    struct AaveV3UserData {
        uint256 totalCollateralBase;
        uint256 totalBorrowsBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 eModeId;
        BaseCurrency base;
        // uint256 pendingRewards;
    }

    struct AaveV3TokenData {
        address asset;
        string symbol;
        uint256 decimals;
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        ReserveAddresses reserves;
        // TokenPrice tokenPrice;
        AaveV3Token token;
        // uint256 collateralEmission;
        // uint256 stableDebtEmission;
        // uint256 varDebtEmission;
    }

    struct Flags {
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
    }

    struct AaveV3Token {
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 eModeCategory;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        // uint256 isolationModeTotalDebt;
        bool isolationBorrowEnabled;
        bool isPaused;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    //Rewards details
    struct ReserveIncentiveData {
        address underlyingAsset;
        IncentivesData aIncentiveData;
        IncentivesData vIncentiveData;
        IncentivesData sIncentiveData;
    }

    struct IncentivesData {
        address token;
        RewardsInfo[] rewardsTokenInfo;
    }

    struct RewardsInfo {
        string rewardTokenSymbol;
        address rewardTokenAddress;
        uint256 emissionPerSecond;
        uint256 userUnclaimedRewards;
        uint256 rewardTokenDecimals;
        uint256 precision;
    }

    IPoolAddressesProvider internal provider = IPoolAddressesProvider(getPoolAddressProvider());
    IAaveOracle internal aaveOracle = IAaveOracle(getAaveOracle());
    IAaveProtocolDataProvider internal aaveData = IAaveProtocolDataProvider(provider.getPoolDataProvider());
    IPool internal pool = IPool(provider.getPool());
    IUiIncentiveDataProviderV3 internal uiIncentives = IUiIncentiveDataProviderV3(getUiIncetivesProvider());

    function getIncentivesInfo(address user) internal view returns (ReserveIncentiveData[] memory incentives) {
        AggregatedReserveIncentiveData[] memory _aggregateIncentive = uiIncentives.getReservesIncentivesData(provider);
        UserReserveIncentiveData[] memory _aggregateUserIncentive = uiIncentives.getUserReservesIncentivesData(
            provider,
            user
        );
        incentives = new ReserveIncentiveData[](_aggregateIncentive.length);
        for (uint256 i = 0; i < _aggregateIncentive.length; i++) {
            RewardsInfo[] memory _aRewards = getRewardInfo(
                _aggregateIncentive[i].aIncentiveData.rewardsTokenInformation,
                _aggregateUserIncentive[i].aTokenIncentivesUserData.userRewardsInformation
            );
            RewardsInfo[] memory _sRewards = getRewardInfo(
                _aggregateIncentive[i].sIncentiveData.rewardsTokenInformation,
                _aggregateUserIncentive[i].sTokenIncentivesUserData.userRewardsInformation
            );
            RewardsInfo[] memory _vRewards = getRewardInfo(
                _aggregateIncentive[i].vIncentiveData.rewardsTokenInformation,
                _aggregateUserIncentive[i].vTokenIncentivesUserData.userRewardsInformation
            );
            IncentivesData memory _aToken = IncentivesData(
                _aggregateIncentive[i].aIncentiveData.tokenAddress,
                _aRewards
            );
            IncentivesData memory _sToken = IncentivesData(
                _aggregateIncentive[i].sIncentiveData.tokenAddress,
                _sRewards
            );
            IncentivesData memory _vToken = IncentivesData(
                _aggregateIncentive[i].vIncentiveData.tokenAddress,
                _vRewards
            );
            incentives[i] = ReserveIncentiveData(_aggregateIncentive[i].underlyingAsset, _aToken, _vToken, _sToken);
        }
    }

    function getRewardInfo(RewardInfo[] memory rewards, UserRewardInfo[] memory userRewards)
        internal
        view
        returns (RewardsInfo[] memory rewardData)
    {
        // console.log(rewards.length);
        rewardData = new RewardsInfo[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            rewardData[i] = RewardsInfo(
                rewards[i].rewardTokenSymbol,
                rewards[i].rewardTokenAddress,
                rewards[i].emissionPerSecond,
                userRewards[i].userUnclaimedRewards,
                uint256(rewards[i].rewardTokenDecimals),
                uint256(rewards[i].precision)
            );
        }
    }

    function getTokensPrices(uint256 basePriceInUSD, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = aaveOracle.getAssetsPrices(tokens);
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());

        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                (_tokenPrices[i] * basePriceInUSD * 10**10) / ethPrice,
                wmul(_tokenPrices[i] * 10**10, basePriceInUSD * 10**10)
            );
        }
    }

    function getEmodePrices(address priceOracleAddr, address[] memory tokens)
        internal
        view
        returns (uint256[] memory tokenPrices)
    {
        tokenPrices = IPriceOracle(priceOracleAddr).getAssetsPrices(tokens);
    }

    function getPendingRewards(address user, address[] memory _tokens) internal view returns (uint256 rewards) {
        uint256 arrLength = 2 * _tokens.length;
        address[] memory _atokens = new address[](arrLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData.getReserveTokensAddresses(_tokens[i]);
        }
        rewards = IAaveIncentivesController(getAaveIncentivesAddress()).getRewardsBalance(_atokens, user);
    }

    function getIsolationDebt(address token) internal view returns (uint256 isolationDebt) {
        isolationDebt = uint256(pool.getReserveData(token).isolationModeTotalDebt);
    }

    function getUserData(address user) internal view returns (AaveV3UserData memory userData) {
        (
            userData.totalCollateralBase,
            userData.totalBorrowsBase,
            userData.availableBorrowsBase,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = pool.getUserAccountData(user);

        userData.base = getBaseCurrencyDetails();
        userData.eModeId = pool.getUserEMode(user);
        // userData.pendingRewards = getPendingRewards(tokens, user);
    }

    function getFlags(address token) internal view returns (Flags memory flag) {
        (
            ,
            ,
            ,
            ,
            ,
            flag.usageAsCollateralEnabled,
            flag.borrowEnabled,
            flag.stableBorrowEnabled,
            flag.isActive,
            flag.isFrozen
        ) = aaveData.getReserveConfigurationData(token);
    }

    function getV3Token(address token) internal view returns (AaveV3Token memory tokenData) {
        (
            (tokenData.borrowCap, tokenData.supplyCap),
            tokenData.eModeCategory,
            tokenData.debtCeiling,
            tokenData.debtCeilingDecimals,
            tokenData.liquidationFee,
            tokenData.isPaused
        ) = (
            aaveData.getReserveCaps(token),
            aaveData.getReserveEModeCategory(token),
            aaveData.getDebtCeiling(token),
            aaveData.getDebtCeilingDecimals(),
            aaveData.getLiquidationProtocolFee(token),
            aaveData.getPaused(token)
        );
        {
            (tokenData.isolationBorrowEnabled) = (aaveData.getDebtCeiling(token) == 0) ? false : true;
        }
        // (tokenData.isolationModeTotalDebt) = getIsolationDebt(token);
    }

    function getEthPrice() public view returns (uint256 ethPrice) {
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());
    }

    function getEmodeCategoryData(uint8 id, address[] memory tokens)
        external
        view
        returns (EmodeData memory eModeData)
    {
        EModeCategory memory data_ = pool.getEModeCategoryData(id);
        {
            eModeData.data = data_;
            // eModeData.price = getEmodePrices(data_.priceSource, tokens);     //TODO
        }
    }

    function reserveConfig(address token)
        internal
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 threshold,
            uint256 reserveFactor
        )
    {
        (decimals, ltv, threshold, , reserveFactor, , , , , ) = aaveData.getReserveConfigurationData(token);
    }

    function resData(address token)
        internal
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt
        )
    {
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = aaveData.getReserveData(token);
    }

    function getAaveTokensData(address token) internal view returns (ReserveAddresses memory reserve) {
        (
            reserve.aToken.tokenAddress,
            reserve.stableDebtToken.tokenAddress,
            reserve.variableDebtToken.tokenAddress
        ) = aaveData.getReserveTokensAddresses(token);
        reserve.aToken.symbol = IERC20Detailed(reserve.aToken.tokenAddress).symbol();
        reserve.stableDebtToken.symbol = IERC20Detailed(reserve.stableDebtToken.tokenAddress).symbol();
        reserve.variableDebtToken.symbol = IERC20Detailed(reserve.variableDebtToken.tokenAddress).symbol();
        reserve.aToken.decimals = IERC20Detailed(reserve.aToken.tokenAddress).decimals();
        reserve.stableDebtToken.decimals = IERC20Detailed(reserve.stableDebtToken.tokenAddress).decimals();
        reserve.variableDebtToken.decimals = IERC20Detailed(reserve.variableDebtToken.tokenAddress).decimals();
    }

    function userCollateralData(address token) internal view returns (AaveV3TokenData memory aaveTokenData) {
        aaveTokenData.asset = token;
        aaveTokenData.symbol = IERC20Detailed(token).symbol();
        (
            aaveTokenData.decimals,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            aaveTokenData.reserveFactor
        ) = reserveConfig(token);

        {
            (
                aaveTokenData.availableLiquidity,
                aaveTokenData.totalStableDebt,
                aaveTokenData.totalVariableDebt
            ) = resData(token);
        }

        aaveTokenData.token = getV3Token(token);
        // aaveTokenData.tokenPrice = assetPrice;

        //-------------INCENTIVE DETAILS---------------

        aaveTokenData.reserves = getAaveTokensData(token);

        // (, aaveTokenData.collateralEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.aToken.tokenAddress
        // );
        // (, aaveTokenData.varDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.variableDebtToken.tokenAddress
        // );
        // (, aaveTokenData.stableDebtEmission, ) = IAaveIncentivesController(getAaveIncentivesAddress()).assets(
        //     aaveTokenData.reserves.stableDebtToken.tokenAddress
        // );
    }

    function getUserTokenData(address user, address token)
        internal
        view
        returns (AaveV3UserTokenData memory tokenData)
    {
        uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
            .getAssetPrice(token);
        tokenData.price = basePrice;
        (
            tokenData.supplyBalance,
            tokenData.stableBorrowBalance,
            tokenData.variableBorrowBalance,
            ,
            ,
            tokenData.userStableBorrowRate,
            tokenData.supplyRate,
            ,
            tokenData.isCollateral
        ) = aaveData.getUserReserveData(token, user);

        {
            tokenData.flag = getFlags(token);
            (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = aaveData.getReserveData(
                token
            );
        }
    }

    function getPrices(bytes memory data) internal view returns (uint256) {
        (, BaseCurrencyInfo memory baseCurrency) = abi.decode(data, (AggregatedReserveData[], BaseCurrencyInfo));
        return uint256(baseCurrency.marketReferenceCurrencyPriceInUsd);
    }

    function getBaseCurrencyDetails() internal view returns (BaseCurrency memory baseCurr) {
        if (aaveOracle.BASE_CURRENCY() == address(0)) {
            baseCurr.symbol = "USD";
        } else {
            baseCurr.symbol = IERC20Detailed(aaveOracle.BASE_CURRENCY()).symbol();
        }

        baseCurr.baseUnit = aaveOracle.BASE_CURRENCY_UNIT();
        baseCurr.baseAddress = aaveOracle.BASE_CURRENCY();

        //TODO
        //     (, bytes memory data) = getUiDataProvider().staticcall(
        //         abi.encodeWithSignature("getReservesData(address)", IPoolAddressesProvider(getPoolAddressProvider()))
        //     );
        //     baseCurr.baseInUSD = getPrices(data);
        // }
    }

    function getList() public view returns (address[] memory data) {
        data = pool.getReservesList();
    }

    function isUsingAsCollateralOrBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 3 != 0;
    }

    function isUsingAsCollateral(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2 + 1)) & 1 != 0;
    }

    function isBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 1 != 0;
    }

    function getConfig(address user) public view returns (UserConfigurationMap memory data) {
        data = pool.getUserConfiguration(user);
    }
}
