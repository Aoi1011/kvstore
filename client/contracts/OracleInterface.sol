// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OracleInterface {
    mapping(bytes32 => uint256) matchIdToIndex;

    Match[] matches;

    struct Match {
        bytes32 id;
        string name;
        string particlepants;
        uint8 participantCount;
        uint256 date;
        MatchOutcome outcome;
        int8 winner;
    }

    enum MatchOutcome {Pending, Underway, Draw, Decided}

    function _getMatchIndex(bytes32 _matchId) private view returns (uint256) {
        return matchIdToIndex[_matchId];
    }

    function getPendingMatches() public view returns (bytes32[] memory) {
        uint256 count = 0;

        //get count of pending matches
        for (uint256 i = 0; i < matches.length; i++) {
            if (matches[i].outcome == MatchOutcome.Pending) {
                count++;
            }
        }

        //collect up all the pending matches
        bytes32[] memory output = new bytes32[](count);

        if (count > 0) {
            uint256 index = 0;
            for (uint256 n = matches.length; n > 0; n--) {
                if (matches[n - 1].outcome == MatchOutcome.Pending) {
                    output[index++] = matches[n - 1].id;
                }
            }
        }

        return output;
    }

    function getAllMatches() public view returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](matches.length);

        //get all ids
        if (matches.length > 0) {
            uint256 index = 0;
            for (uint256 n = matches.length; n > 0; n--) {
                output[index++] = matches[n - 1].id;
            }
        }

        return output;
    }

    function matchExists(bytes32 _matchId) public view returns (bool) {
        if (matches.length == 0) {
            return false;
        }
        uint256 index = matchIdToIndex[_matchId];
        return (index > 0);
    }

    function getMatch(bytes32 _matchId)
        public
        view
        returns (
            bytes32 id,
            string memory name,
            string memory participants,
            uint8 participantCount,
            uint256 date,
            MatchOutcome outcome,
            int8 winner
        )
    {
        //get the match
        if (matchExists(_matchId)) {
            Match storage theMatch = matches[_getMatchIndex(_matchId)];
            return (
                theMatch.id,
                theMatch.name,
                theMatch.particlepants,
                theMatch.participantCount,
                theMatch.date,
                theMatch.outcome,
                theMatch.winner
            );
        } else {
            return (_matchId, "", "", 0, 0, MatchOutcome.Pending, -1);
        }
    }

    function getMostRecentMatch(bool _pending)
        public
        view
        returns (
            bytes32 id,
            string memory name,
            string memory participants,
            uint8 participantCount,
            uint256 date,
            MatchOutcome outcome,
            int8 winner
        )
    {
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

    function testConnection() public pure returns (bool);

    function addTestData() public;
}
