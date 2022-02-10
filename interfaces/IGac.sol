/// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
interface IGac {
    function paused() external view returns (bool);

    function transferFromDisabled() external view returns (bool);

    function unpause() external;

    function pause() external;

    function enableTransferFrom() external;

    function disableTransferFrom() external;

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMember(bytes32 role, uint index) external view returns (address);
}