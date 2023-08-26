pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo; // address for protocol fee
    address public feeToSetter; // the address allowed to change feeTo to a different address.

    mapping(address => mapping(address => address)) public getPair; /*
 a mapping that identifies a pair exchange contract based on the two ERC-20 tokens it exchanges. 
ERC-20 tokens are identified by the addresses of the contracts that implement them, so the keys and the value are all addresses.
To get the address of the pair exchange that lets you convert from tokenA to tokenB, 
you use getPair[<tokenA address>][<tokenB address>] (or the other way around).
*/
    address[] public allPairs; // to store all pairs.In Ethereum you cannot iterate over the content of a mapping, 
            //or get a list of all the keys, so this variable is the only way to know which exchanges this factory manages.
            //The reason you cannot iterate over all the keys of a mapping is that contract data storage is expensive, 
            //so the less of it we use the better, and the less often we change it the better.

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
//uint here is total number of exchanges managed by the factory

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;//specifying feeToSetter. Factories start without a fee, and only feeSetter can change that 
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;//returns the number of all pairs
    }

    // * this function is for creating new pools/pair
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); //checking the pair from the array ,if the result is equal to zero address, 
                                                     //then pair can be created, otherwise revert with PAIR_EXISTS    
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // * `bytecode` --> to create contract we need code of the contract
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // * enconding tokens
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            // * creating contract with opcodes
        }
        IUniswapV2Pair(pair).initialize(token0, token1); // using `initialize` function in IUniswapV2Pair
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

//The following two functions allow feeSetter to control the fee recipient (if any), and to change feeSetter to a new address.
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
        /* uniswap v2 includes 0.05% protocol fee that can be turned on and off
         * if the fee address is set, the protocol can earn 1/6 cut of 0.3%,
         * it means traders still have to pay 0.3% but liquidity providers will receive 0.25% and 0.05% will be earned by protocol 
         * collecting 0.05% on every trade will impose additional gas cost 
         * that's why uniswap collects accumulated fees when liquidity is deposited or withdrawn.
         */
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
