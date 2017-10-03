pragma solidity ^0.4.14;


contract EtherBall {

    struct Ticket {
        address ticketOwner;
        uint256 blockNumber;
        bytes1[5] hexPicks;
    }

    address                     public host;
    mapping (bytes32 => Ticket) public ticketPile;

    uint256                     public ticketPrice;
    uint256                     public jackpot;
    bool                        public isGameOpen;
    
    address[]                   public winners;

    event FoundWinner(bytes32 referenceNumber);
    event ConfirmPayment(address, uint256);
    event MaliciousActivity(address);

    function EtherBall () public { 
        host = msg.sender;
    }

    // See if the ticket of some reference number exists.
    function doesExist(bytes32 referenceNumber) constant public returns (bool) {
        if ( ticketPile[referenceNumber].ticketOwner == address(0x0) ) {
            return false;
        } else {
            return true;
        }
    }

    //  Retrieve the ticket with the given referenceNumber.
    function getTicket(bytes32 referenceNumber) constant public returns (bool, address, uint256, bytes1[5]) {
        bool exists = doesExist(referenceNumber);
        return (exists,
                ticketPile[referenceNumber].ticketOwner,
                ticketPile[referenceNumber].blockNumber,
                ticketPile[referenceNumber].hexPicks);
    }

    //  This is called from the back-end.
    function registerTicket(address _ticketOwner,                                                                                        
                            bytes32 _referenceNumber, 
                            bytes1[5] _hexPicks) public returns (bool)
    {
        // Report Requests that did not originate from the back-end
        if ( msg.sender != host ) { 
            MaliciousActivity(msg.sender);
            revert(); 
            return false;
        }

        // Add the ticket to the ticketPile.
        ticketPile[_referenceNumber] = Ticket({ ticketOwner : _ticketOwner,
                                                blockNumber : block.number,
                                                hexPicks : _hexPicks });

    }

//  Pay the winner the award ether.
    function payWinner(bytes32 referenceNumber, bytes1[5] winningHexes, uint256 amount) public returns (bool) {                
        
        // Report Requests that did not originate from the back-end
        if ( msg.sender != host ) { 
            MaliciousActivity(msg.sender);
            revert(); 
            return false;
        }

        // Double check if this person actually won the lottery
        uint k = 0;    
        // loop for test hexes 
        for (uint i = 0; i < 5; i++) {
            // loop for solutions hexes
            for ( uint j = k; j < 5; j ++) {
                if ( winningHexes[j] == ticketPile[referenceNumber].hexPicks[i] ) {
                    k = k + 1;                    
                }
            }
        }

        if ( k == 5 ) {
            ticketPile[referenceNumber].ticketOwner.transfer(amount);
            return true;
        } else {
            return false;
        }

    }


// Destroy contract.
    function destroy() public {
        require(msg.sender == host);
        selfdestruct(host);
    }

    function getBalance() constant public returns (uint256) {
        return this.balance;
    }

    function () payable public {
        // Broadcast that payment was received.
        ConfirmPayment(msg.sender, msg.value);
        // Send tax to myself.
        // Blah()
    }

}