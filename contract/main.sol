pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm/contracts/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm/contracts/vendor/Ownable.sol";


/**
* Contract will payout marketing agency once agreed upon threshold for unique visitors is reached.
* utilize Ownable helper functions to manage ownership and transfer thereof with the onlyOwner modifier.
**/
contract MarketingROI is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    string constant APPENGINE_ENDPOINT = "https://chainlink-marketing-roi.appspot.com";

    //ROPSTEN VALUES
    address constant private CHAINLINK_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    string constant private HTTP_GET_INT_JOB_ID = "46a7c3f9852e46e09350ad5af92ce86f";
    string constant private HTTP_GET_UINT_JOB_ID = "3cff0a3524694ff8834bda9cf9c779a1";
    string constant private HTTP_GET_BYTE32_JOB_ID = "76ca51361e4e444f8a9b18ae350a5725";


    event RequestGetVisitorsFullfilled(
        bytes32 indexed requestId,
        uint256 indexed visitors);

    uint256 public uniqueVisitors;

    constructor() public Ownable(){
        setPublicChainlinkToken();
        setChainlinkOracle(CHAINLINK_ORACLE);
    }

    function checkVisitors() public returns (bytes32 requestId) {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(HTTP_GET_UINT_JOB_ID), this, this.fulfillUniqueVisitors.selector);
        req.add("get", APPENGINE_ENDPOINT);
        req.add("path", "uniqueVisitors");
        req.addInt("times", 1);
        // Sends the request with 1 LINK to the oracle contract
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    function fulfillUniqueVisitors(bytes32 _requestId, uint256 _uniqueVisitors) public recordChainlinkFulfillment(_requestId) {
        uniqueVisitors = _uniqueVisitors;
        emit RequestGetVisitorsFullfilled(_requestId, _uniqueVisitors);
    }

    /**
    * HELPER FUNCTIONS
    **/

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    //allows the owner to get back the LINK that funded the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    //allows the owner to cancel an outstanding request
    function cancelRequest(bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public onlyOwner {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    //avoid having to pass byte32
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {// solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}