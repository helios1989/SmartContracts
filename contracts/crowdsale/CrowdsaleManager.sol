pragma solidity ^0.4.11;

import "../core/common/BaseManager.sol";
import "../assets/AssetsManagerInterface.sol";
import "../assets/PlatformRegistryInterface.sol";
import "./base/BaseCrowdsale.sol";
import "./CrowdsaleFactory.sol";
import "./CrowdsaleManagerEmitter.sol";

/**
 *  @title CrowdsaleManager
 *
 *  Is not designed for direct crowdsale management via external calls
 *  from web application.
 *
 *  Only AssetsManager is authorised to execute CrowdsaleManager's methods.
 */
contract CrowdsaleManager is CrowdsaleManagerEmitter, BaseManager {
    uint constant ERROR_CROWDFUNDING_INVALID_INVOCATION = 3000;
    uint constant ERROR_CROWDFUNDING_ADD_CONTRACT = 3001;
    uint constant ERROR_CROWDFUNDING_NOT_ASSET_OWNER = 3002;
    uint constant ERROR_CROWDFUNDING_DOES_NOT_EXIST = 3003;

    StorageInterface.AddressesSet compains;
    StorageInterface.Bytes32AddressMapping factories;

    modifier onlyAssetsPlatformRegistry() {
        if (msg.sender ==  AssetsManagerInterface(lookupManager("AssetsManager")).getPlatformRegistry()) {
            _;
        }
    }

    /**
    *  Constructor
    */
    function CrowdsaleManager(Storage _store, bytes32 _crate) BaseManager(_store, _crate) {
        compains.init('compains');
        factories.init("factories");
    }

    /**
    *  Initialize
    */
    function init(address _contractsManager) onlyContractOwner returns (uint) {
        BaseManager.init(_contractsManager, "CrowdsaleManager");

        return OK;
    }

    /**
    *  Creates Crowdsale with a type produced by CrowdsaleFactory with given _factoryName.
    */
    function createCrowdsale(address _creator, bytes32 _symbol, bytes32 _factoryName) onlyAssetsPlatformRegistry returns (address, uint) {
        if (!lookupAssetsPlatformRegistry().isAssetOwner(_symbol, _creator)) {
            return (0x0, _emitError(ERROR_CROWDFUNDING_NOT_ASSET_OWNER));
        }

        address crowdsale = getCrowdsaleFactory(_factoryName).createCrowdsale(_symbol);

        if (!BaseCrowdsale(crowdsale).claimContractOwnership()) {
            return (0x0, _emitError(ERROR_CROWDFUNDING_INVALID_INVOCATION));
        }

        store.add(compains, crowdsale);
        _emitCrowdsaleCreated(_creator, _symbol, crowdsale);

        return (crowdsale, OK);
    }

    /**
    *  Deletes Crowdsale if It is allowed.
    */
    function deleteCrowdsale(address crowdsale) onlyAssetsPlatformRegistry returns (uint) {
        if (!lookupAssetsPlatformRegistry().isAssetOwner(BaseCrowdsale(crowdsale).getSymbol(), crowdsale)) {
            return _emitError(ERROR_CROWDFUNDING_NOT_ASSET_OWNER);
        }

        if (!store.includes(compains, crowdsale)) {
            return _emitError(ERROR_CROWDFUNDING_DOES_NOT_EXIST);
        }

        if (!BaseCrowdsale(crowdsale).hasEnded()) {
            return _emitError(ERROR_CROWDFUNDING_INVALID_INVOCATION);
        }

        store.remove(compains, crowdsale);

        BaseCrowdsale(crowdsale).destroy(); // TODO: @ahiatsevich refund to CrowdsaleManager??

        _emitCrowdsaleDeleted(crowdsale);
        return OK;
    }

    /**
    *  Returns CrowdsaleFactory by given _factoryName.
    */
    function getCrowdsaleFactory(bytes32 _factoryName) constant returns (CrowdsaleFactory) {
        return CrowdsaleFactory(lookupManager(_factoryName));
    }

    /**
    *  Returns AssetsManager.
    */
    function lookupAssetsPlatformRegistry() internal constant returns (PlatformRegistryInterface) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(lookupManager("AssetsManager"));
        return PlatformRegistryInterface(assetsManager.getPlatformRegistry());
    }

    function _emitCrowdsaleCreated(address creator, bytes32 symbol, address crowdsale) internal {
        CrowdsaleManager(getEventsHistory()).emitCrowdsaleCreated(creator, symbol, crowdsale);
    }

    function _emitCrowdsaleDeleted(address crowdsale) internal {
        CrowdsaleManager(getEventsHistory()).emitCrowdsaleDeleted(crowdsale);
    }

    function _emitError(uint error) internal returns (uint) {
        CrowdsaleManager(getEventsHistory()).emitError(error);
        return error;
    }
}