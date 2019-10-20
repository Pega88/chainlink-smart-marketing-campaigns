pragma solidity ^0.4.24;

import "github.com/smartcontractkit/chainlink/blob/master/evm/contracts/Chainlinked.sol";


contract MarketingROI{
    
    event gotPaid(uint);
    address private owner;
    
    modifier isOwner{
        require(owner == msg.sender);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    function() payable public{
        emit gotPaid(msg.value);
    }
    
    function payTo(uint amount) public{
        msg.sender.transfer(amount);
    }
}