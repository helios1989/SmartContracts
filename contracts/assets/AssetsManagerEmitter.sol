pragma solidity ^0.4.11;

import '../core/event/MultiEventsHistoryAdapter.sol';

contract AssetsManagerEmitter is MultiEventsHistoryAdapter {
    event Error(address indexed self, uint errorCode);
    event NewAssetRequested(address indexed self, bytes32 symbol, address platform, address owner, uint requestId);
    event AssetAdded(address indexed self, address asset, bytes32 symbol, address owner);
    event AssetCreated(address indexed self, bytes32 symbol, address token);
    event PlatformOwnerAdded(address indexed self, address platform, address owner, address addedBy);
    event PlatformOwnerRemoved(address indexed self, address platform, address owner, address removedBy);
    event PlatformAttached(address indexed self, address platform, address owner);
    event PlatformDetached(address indexed self, address platform, address to);

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }

    function emitAssetAdded(address asset, bytes32 symbol, address owner) {
        AssetAdded(_self(), asset, symbol, owner);
    }

    function emitAssetCreated(bytes32 symbol, address token) {
        AssetCreated(_self(), symbol, token);
    }

    function emitPlatformOwnerAdded(address platform, address owner, address addedBy) {
        PlatformOwnerAdded(_self(), platform, owner, addedBy);
    }

    function emitPlatformOwnerRemoved(address platform, address owner, address removedBy) {
        PlatformOwnerRemoved(_self(), platform, owner, removedBy);
    }

    function emitNewAssetRequested(bytes32 symbol, address platform, address owner, uint requestId) {
        NewAssetRequested(_self(), symbol, platform, owner, requestId);
    }

    function emitPlatformAttached(address platform, address owner) {
        PlatformAttached(_self(), platform, owner);
    }

    function emitPlatformDetached(address platform, address to) {
        PlatformDetached(_self(), platform, to);
    }
}