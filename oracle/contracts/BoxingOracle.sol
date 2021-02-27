// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./DateLib.sol";

/*
TEST: 
- testConnection 
- getAddress
- matchExists(0) 
- matchExists(1)
- declareOutcome(0, 2)
- getPendingMatches()
- getAllMatches()
- getMatch(0)
- getMostRecentMatch(true)
- addTestData()
- matchExists(0) 
- matchExists(1)
- declareOutcome(0, 2)
- getPendingMatches()               
- getAllMatches()                   
- getMatch(0)
- getMostRecentMatch(true)
- getMostRecentMatch(false) 
- getMatch(0x...)                   
- declareOutcome(0x..., 2)              
- getMostRecentMatch(true)
- getMostRecentMatch(false)
- getMatch(0x...)              
- add duplicate match      
*/

/// @title BoxingOracle
/// @author John R. Kosinski
/// @notice Collects and provides information on boxing matches and their outcomes 
contract BoxingOracle is Ownable {
    Match[] matches; 
    mapping(bytes32 => uint) matchIdToIndex; 

    using DateLib for DateLib.DateTime;


    //defines a match along with its outcome
    struct Match {
        bytes32 id;
        string name;
        string participants;
        uint8 participantCount;
        uint date; 
        MatchOutcome outcome;
        int8 winner;
    }

    //possible match outcomes 
    enum MatchOutcome {
        Pending,    //match has not been fought to decision
        Underway,   //match has started & is underway
        Draw,       //anything other than a clear winner (e.g. cancelled)
        Decided     //index of participant who is the winner 
    }

    function _getMatchIndex(bytes32 _matchId) private view returns (uint) {
        return matchIdToIndex[_matchId]-1; 
    }

    function matchExists(bytes32 _matchId) public view returns (bool) {
        if (matches.length == 0)
            return false;
        uint index = matchIdToIndex[_matchId]; 
        return (index > 0); 
    }

    function addMatch(string memory _name, string memory _participants, uint8 _participantCount, uint _date) onlyOwner public returns (bytes32) {

        //hash the crucial info to get a unique id 
        bytes32 id = keccak256(abi.encodePacked(_name, _participantCount, _date)); 

        //require that the match be unique (not already added) 
        require(!matchExists(id));
        
        //add the match 
        uint newIndex = matches.push(Match(id, _name, _participants, _participantCount, _date, MatchOutcome.Pending, -1)) -1; 
        matchIdToIndex[id] = newIndex+1;
        
        //return the unique id of the new match
        return id;
    }

    function declareOutcome(bytes32 _matchId, MatchOutcome _outcome, int8 _winner) onlyOwner external {

        //require that it exists
        require(matchExists(_matchId)); 

        //get the match 
        uint index = _getMatchIndex(_matchId);
        Match storage theMatch = matches[index]; 

        if (_outcome == MatchOutcome.Decided) 
            require(_winner >= 0 && theMatch.participantCount > uint8(_winner)); 

        //set the outcome 
        theMatch.outcome = _outcome;
        
        //set the winner (if there is one)
        if (_outcome == MatchOutcome.Decided) 
            theMatch.winner = _winner;
    }

    function getPendingMatches() public view returns (bytes32[] memory) {
        uint count = 0; 

        //get count of pending matches 
        for (uint i = 0; i < matches.length; i++) {
            if (matches[i].outcome == MatchOutcome.Pending) 
                count++; 
        }

        //collect up all the pending matches
        bytes32[] memory output = new bytes32[](count); 

        if (count > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                if (matches[n-1].outcome == MatchOutcome.Pending) 
                    output[index++] = matches[n-1].id;
            }
        } 

        return output; 
    }

    
    function getAllMatches() public view returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](matches.length); 

        //get all ids 
        if (matches.length > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                output[index++] = matches[n-1].id;
            }
        }
        
        return output; 
    }

    
    function getMatch(bytes32 _matchId) public view returns (
        bytes32 id,
        string memory name, 
        string memory participants,
        uint8 participantCount,
        uint date, 
        MatchOutcome outcome, 
        int8 winner) {
        
        //get the match 
        if (matchExists(_matchId)) {
            Match storage theMatch = matches[_getMatchIndex(_matchId)];
            return (theMatch.id, theMatch.name, theMatch.participants, theMatch.participantCount, theMatch.date, theMatch.outcome, theMatch.winner); 
        }
        else {
            return (_matchId, "", "", 0, 0, MatchOutcome.Pending, -1); 
        }
    }

    
    function getMostRecentMatch(bool _pending) public view returns (
        bytes32 id,
        string memory name, 
        string memory participants,
        uint8 participantCount,
        uint date, 
        MatchOutcome outcome, 
        int8 winner) {

        bytes32 matchId = 0; 
        bytes32[] memory ids;

        if (_pending) {
            ids = getPendingMatches(); 
        } else {
            ids = getAllMatches();
        }
        if (ids.length > 0) {
            matchId = ids[0]; 
        }
        
        //by default, return a null match
        return getMatch(matchId); 
    }

    function testConnection() public pure returns (bool) {
        return true; 
    }

    function getAddress() public view returns (address) {
        return this.getAddress();
    }

    function addTestData() external onlyOwner {
        addMatch("Pacquiao vs. MayWeather", "Pacquiao|Mayweather", 2, DateLib.DateTime(2018, 8, 13, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Macquiao vs. Payweather", "Macquiao|Payweather", 2, DateLib.DateTime(2018, 8, 15, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Pacweather vs. Macarthur", "Pacweather|Macarthur", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Macarthur vs. Truman", "Macarthur|Truman", 2, DateLib.DateTime(2018, 9, 3, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Macaque vs. Pregunto", "Macaque|Pregunto", 2, DateLib.DateTime(2018, 9, 21, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Farsworth vs. Wernstrom", "Farsworth|Wernstrom", 2, DateLib.DateTime(2018, 9, 29, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Fortinbras vs. Hamlet", "Fortinbras|Hamlet", 2, DateLib.DateTime(2018, 10, 10, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Foolicle vs. Pretendo", "Foolicle|Pretendo", 2, DateLib.DateTime(2018, 11, 11, 0, 0, 0, 0, 0).toUnixTimestamp());
        addMatch("Parthian vs. Scythian", "Parthian|Scythian", 2, DateLib.DateTime(2018, 11, 12, 0, 0, 0, 0, 0).toUnixTimestamp());
    }
}
