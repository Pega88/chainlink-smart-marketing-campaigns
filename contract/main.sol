pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm/contracts/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm/contracts/vendor/Ownable.sol";


/**
* Contract will payout marketing agency once agreed upon threshold for unique visitors is reached.
* utilize Ownable helper functions to manage ownership and transfer thereof with the onlyOwner modifier.
**/
contract MarketingROI is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    string constant APPENGINE_ENDPOINT = "https://chainlink-marketing-roi.appspot.com/?campaignId=";

    //ROPSTEN VALUES
    address constant private CHAINLINK_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    string constant private HTTP_GET_INT_JOB_ID = "46a7c3f9852e46e09350ad5af92ce86f";
    string constant private HTTP_GET_UINT_JOB_ID = "3cff0a3524694ff8834bda9cf9c779a1";
    string constant private HTTP_GET_BYTE32_JOB_ID = "76ca51361e4e444f8a9b18ae350a5725";

    //todo better to have struct be max 256 bits?
    struct Campaign {
        string campaignId;
        uint256 amount;
        uint256 visitorsRequired;
        address agency;
    }


    event RequestCampaignPayoutFullfilled(
        bytes32 indexed requestId,
        uint256 indexed visitors);

    uint256 public uniqueVisitors;

    //maps campaignId to campaign details
    mapping(string => Campaign) campaigns;
    //maps the payout request id to the campaign it was requested for
    mapping(bytes32 => string) payoutRequests;

    constructor() public Ownable(){
        setPublicChainlinkToken();
        setChainlinkOracle(CHAINLINK_ORACLE);
    }


    function registerCampaign(string _campaignId, uint256 _visitorsRequired, address _agency) public payable {
        assert(bytes(_campaignId).length > 0);
        assert(_visitorsRequired > 0);
        //register the amount to be paid to the campaign id.
        campaigns[_campaignId] = Campaign(_campaignId, msg.value, _visitorsRequired, _agency);
    }

    function requestCampaignPayout(string campaignId) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(HTTP_GET_UINT_JOB_ID), this, this.fulfillCampaignPayout.selector);
        req.add("get", append(APPENGINE_ENDPOINT,campaignId));
        req.add("path", "uniqueVisitors");
        req.addInt("times", 1);
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);

        //persist the fact that this request was made for the given campaignId so fulfillment knows what campaign to validate.
        payoutRequests[requestId] = campaignId;
    }

    function fulfillCampaignPayout(bytes32 _requestId, uint256 _uniqueVisitors) public recordChainlinkFulfillment(_requestId) {
        uniqueVisitors = _uniqueVisitors;
        string storage campaignId = payoutRequests[_requestId];
        Campaign storage c = campaigns[campaignId];

        //check if threshold has been reached
        if (_uniqueVisitors >= c.visitorsRequired) {
            //send money to agency
            c.agency.transfer(c.amount);
        }
        emit RequestCampaignPayoutFullfilled(_requestId, _uniqueVisitors);
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
    function append(string a, string b) internal pure returns (string) {

        return string(abi.encodePacked(a, b));

    }
}