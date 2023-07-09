//accounting
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../lib/math-lib.sol";
import "../lib/erc20.sol";

/**
 a base contract with accounting functionality for ETH and ERC20 tokens
 */

abstract contract Modifiers {
    bool internal _in;

    modifier noReentrance() {
        require(!_in, "Reentrance not allowed!");
        _in = true;
        _;
        _in = false;
    }
}

abstract contract Accounting is Modifiers {
    using DSMath for uint256;
    uint public totalETH;
    mapping(address => uint) public totalTokenBalances;

    struct Account {
        bytes32 name;
        uint balanceETH;
        mapping(address => uint) tokenBalances;
    }

    Account base;

    event ETHDeposited(
        bytes32 indexed account,
        address indexed from,
        uint value
    );
    event ETHSent(bytes32 indexed account, address indexed to, uint value);
    event ETHTransferred(
        bytes32 indexed fromAccount,
        bytes32 indexed toAccount,
        uint value
    );
    event TokenTransferred(
        bytes32 indexed fromAccount,
        bytes32 indexed toAccount,
        address indexed token,
        uint value
    );
    event TokenDeposited(
        bytes32 indexed account,
        address indexed token,
        address indexed from,
        uint value
    );
    event TokenSent(
        bytes32 indexed account,
        address indexed token,
        address indexed to,
        uint value
    );

    constructor() {
        base.name = "Base";
    }

    function baseETHBalance() public view returns (uint256) {
        return base.balanceETH;
    }

    function baseTokenBalance(address token) public view returns (uint256) {
        return base.tokenBalances[token];
    }

    function depositETH(
        Account storage a,
        address _from,
        uint _value
    ) internal {
        a.balanceETH = a.balanceETH.add(_value);
        totalETH = totalETH.add(_value);
        emit ETHDeposited(a.name, _from, _value);
    }

    function depositToken(
        Account storage a,
        address _token,
        address _from,
        uint _value
    ) internal noReentrance {
        require(
            ERC20(_token).transferFrom(_from, address(this), _value),
            "Token transfer not possible!"
        );
        totalTokenBalances[_token] = totalTokenBalances[_token].add(_value);
        a.tokenBalances[_token] = a.tokenBalances[_token].add(_value);
        emit TokenDeposited(a.name, _token, _from, _value);
    }

    function sendETH(
        Account storage a,
        address payable _to,
        uint _value
    ) internal noReentrance {
        require(a.balanceETH >= _value, "Insufficient ETH balance!");
        require(_to != address(0), "Invalid recipient address!");
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);
        _to.transfer(_value);
        emit ETHSent(a.name, _to, _value);
    }

    function transact(
        Account storage a,
        address payable _to,
        uint _value,
        bytes memory data
    ) internal noReentrance {
        require(a.balanceETH >= _value);
        require(_to != address(0));
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);
        (bool success, ) = _to.call{value: _value}(data);
        require(success);
        emit ETHSent(a.name, _to, _value);
    }

    function sendToken(
        Account storage a,
        address _token,
        address _to,
        uint _value
    ) internal noReentrance {
        require(a.tokenBalances[_token] >= _value);
        require(_to != address(0));
        a.tokenBalances[_token] = a.tokenBalances[_token].sub(_value);
        totalTokenBalances[_token] = totalTokenBalances[_token].sub(_value);
        require(ERC20(_token).transfer(_to, _value));
        emit TokenSent(a.name, _token, _to, _value);
    }

    function transferETH(
        Account storage _from,
        Account storage _to,
        uint _value
    ) internal {
        require(_from.balanceETH >= _value);
        _from.balanceETH = _from.balanceETH.sub(_value);
        _to.balanceETH = _to.balanceETH.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    function transferToken(
        Account storage _from,
        Account storage _to,
        address _token,
        uint _value
    ) internal {
        require(_from.tokenBalances[_token] >= _value);
        _from.tokenBalances[_token] = _from.tokenBalances[_token].sub(_value);
        _to.tokenBalances[_token] = _to.tokenBalances[_token].add(_value);
        emit TokenTransferred(_from.name, _to.name, _token, _value);
    }
}
