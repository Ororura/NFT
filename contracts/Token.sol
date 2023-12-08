// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20("Proffesional", "PROFI") {
    address public owner;
    address public tom;
    address public max;
    address public jack;

    constructor() {
        owner = msg.sender;
        tom = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        max = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        jack = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

        _mint(owner, 100_000 * 10**decimals());
        _mint(tom, 200_000 * 10**decimals());
        _mint(max, 300_000 * 10**decimals());
        _mint(jack, 400_000 * 10**decimals());
    }

    function getRewardCode() public {
        _mint(msg.sender, 100 * 10 * decimals());
    }

    function transferToken(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        _transfer(_from, _to, _amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
