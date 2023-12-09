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
        tom = 0xB08DB82e25Eb6e50d2beEBA70626EfCeb0A5EeE9;
        max = 0x110CE84e8654D4970912246c754d633F8851A05D;
        jack = 0x7d0eADdF71C8264917f27B596cf6426f4360E3eb;

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
