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
        tom = 0xcB3a5467756F86692FB3336c58EC41c16B9BEBdF;
        max = 0xbD0233D4cb7abE917F79f0E80DC7676F4cb818e1;
        jack = 0x7CE4B5D0504EdF27ec43610F8679E84BDF81a0b8;

        _mint(owner, 100_000 * 10 ** decimals());
        _mint(tom, 200_000 * 10 ** decimals());
        _mint(max, 300_000 * 10 ** decimals());
        _mint(jack, 400_000 * 10 ** decimals());
    }

    function getRewrdCode() public {
        _mint(msg.sender, 100 * 10 * decimals());
    }
    
    function transferToken(address _from, address _to, uint _amount) public {
        _transfer(_from, _to, _amount);
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }
}