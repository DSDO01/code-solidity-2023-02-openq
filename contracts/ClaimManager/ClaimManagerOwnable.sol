// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

/// @title ClaimManagerOwnable
/// @author FlacoJones
/// @notice Restricts access for method calls to Oracle address
abstract contract ClaimManagerOwnable is ContextUpgradeable {
    /// INITIALIZATION

    /// @notice ClaimManagerProxy address
    address private _claimManager;


    /// @notice Returns the address of _claimManager
    function claimManager() external view virtual returns (address) {
        return _claimManager;
    }

    /// @notice Modifier to restrict access of methods to _claimManager address
    modifier onlyClaimManager() {
        require(
            _claimManager == _msgSender(),
            'ClaimManagerOwnable: caller is not the current OpenQ Claim Manager'
        );
        _;
    }
}
