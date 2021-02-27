// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./OracleInterface.sol";
import "./Ownable.sol";

contract BoxingBets is Ownable {
    //mapping
    mapping(address => bytes32[]) private userToBets;
    mapping(bytes32 => Bet[]) private matchToBets;

    //boxing results oracle
    address internal boxingOracleAddr;
    OracleInterface internal boxingOracle = OracleInterface(boxingOracleAddr);

    //constants
    uint256 internal minimumBet = 1000000000000;

    struct Bet {
        address user;
        bytes32 matchId;
        uint256 amount;
        uint8 choseWinner;
    }

    enum BettableOutcome {Fighter1, Fighter2}

    function _betIsValid(
        address _user,
        bytes32 _matchId,
        uint8 _choseWinner
    ) private view returns (bool) {
        return true;
    }

    function _matchOpenForBetting(bytes32 _matchId)
        private
        view
        returns (bool)
    {
        return true;
    }

    function getBettableMatches() public view returns (bytes32[] memory) {
        return boxingOracle.getPendingMatches();
    }

    function placeBet(bytes32 _matchId, uint8 _chosenWinner) public payable {
        //bet must be above a certain minimum
        require(msg.value >= minimumBet, "Bet amount must be >= minimum bet");

        //make sure that match exists
        require(
            boxingOracle.matchExists(_matchId),
            "specified match not found"
        );

        //require that chosen winner falls within the defined number of participants for match
        require(
            _betIsValid(msg.sender, _matchId, _chosenWinner),
            "Bet is not valid"
        );

        //match must still be open for betting
        require(_matchOpenForBetting(_matchId), "Match not open for betting");

        //transfer the money into the account
        //address(this).transfer(msg.value);

        //add the new bet
        Bet[] storage bets = matchToBets[_matchId];
        bets.push(Bet(msg.sender, _matchId, msg.value, _chosenWinner))-1;

        //add the mapping
        bytes32[] storage userBets = userToBets[msg.sender];
        userBets.push(_matchId);
    }

    function test(uint256 a, uint256 b) public pure returns (uint256) {
        return (a + b);
    }

    function setOracleAddress(address _oracleAddress) external onlyOwner returns (bool) {
        boxingOracleAddr = _oracleAddress;
        boxingOracle = OracleInterface(boxingOracleAddr);
        return boxingOracle.testConnection();
    }

    function getOracleAddress() external view returns (address) {
        return boxingOracleAddr;
    }
}
