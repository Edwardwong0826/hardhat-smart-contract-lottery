// Raffle

// Enter the lottery (paying some amount)

// Pick a random winner (verifiably random)

// Winner to be selected every X minutes -> completly automated

// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/* Errors */
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffe__NotEnoughETHEntered();
error Raffe__TransferFailed();
error Raffle__RaffleNotOpen();

/**
 * @notice This contract is for creating decentralized smart contract
 * @dev This implements Chainlink VRF V2 and Chainlink Automation
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {

    /* Type declarations */
    // uint256 0 = OPEN, 1 = CALCULATING
    enum RaffleState {
        OPEN,
        CALCULATING
    }


    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // VRFConsumerBaseV2 is the super constructor
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN; // or RaffleState(0)
        s_lastTimeStamp = block.timestamp;
        i_callBackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable{
        // require msg.value > i_entranceFee
        if(msg.value < i_entranceFee){
            revert Raffe__NotEnoughETHEntered();
        }

        // Events - whenever we update a dynamic object, like an array or a mapping
        // we always want to omit an event, in this case s_players
    
        // EVM will log when things happen on blockchain and stored to structure called logs
        // We can read these logs from our blockchain nodes when run
        // Inside logs is an important piece of logging called events
        // Events allow we to "print" stuff to this log in a way more gas efficient than saving in storage variable
        // These events and logs live special data structure that isn't accessible to smart contracts
        // Each one of these events is tied to the smart contract or account address emitted this event in these transactions 
    
        // event storeNumber{
        //      uint256 indexed oldNumber,
        //      uint256 indexed newNumber,
        //      uint 256 addedNumber,
        //      address sender
        // );
        //

        // emit storedNumber(
        //      favoriteNumber,
        //      _favoriteNumber,
        //      _favoriteNumber + favoriteNumber,
        //      msg.sender
        // );

        // when we omint one of these events, there are two kinds of parameters
        // The indexed parameters and the non indexed parameters, we can have up to three index parameters
        // Indexed parameters also known as = Topics, its much easier to search and query than non index parameters
        // Non indexed parameters are harder to search because they are ABI encoded and have to know the API in order to decode them
   
        // Named events with the function name reversed
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable( msg.sender));
        emit RaffleEnter(msg.sender);
    }   
    /**
     * @dev This is the function that the Chainlink Automation nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The contract has ETH.
     * 3. Implicity, your subscription is funded with LINK.
     * 4. The lottery is an "OPEN" state.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    // Chain Links VRF 2, Chain Links keeper now called Chain Link Automation
    // This function will called by the chain link keepers network so that can auto run without interact
    // External function cheaper than public, use external because solidity know our own contract can call this
    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     *
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedRaffleWinner(requestId);
    }


    // This requestRandomWinner function is change to above performUpkeep, is the same logic
    // function requestRandomWinner() external{
    //     // Request the random number
    //     // Once we get it, do something with it
    //     // 2 transaction process, this is to avoid brute froce manipulation
    //     s_raffleState = RaffleState.CALCULATING;
    //     uint256 requestId =  i_vrfCoordinator.requestRandomWords(
    //         i_gasLane, // gasLane
    //         i_subscriptionId,
    //         REQUEST_CONFIRMATIONS,
    //         i_callBackGasLimit,
    //         NUM_WORDS
    //     );

    //     emit RequestedRaffleWinner(requestId);
    // }

    // We will override the virtual function fulfillRandomWords in chainlink VRFConsumerBaseV2.sol one
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) 
        internal 
        override
    {
        // s_players size 10
        // randomNumber 202
        // 202 % 10 = 2
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        // sent all the money in this contract to this address
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(sucess)
        if(!success) {
          revert Raffe__TransferFailed();
        }

        emit WinnerPicked(recentWinner);
    }


    // View is Pure functions
    function getEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    } 

    
    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    } 

    function getRaffleState() public view returns (RaffleState){
        return s_raffleState;
    }

    function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }

}
