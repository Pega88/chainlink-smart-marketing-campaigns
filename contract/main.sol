pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm/contracts/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm/contracts/vendor/Ownable.sol";


/**
* Contract will payout marketing agency once agreed upon threshold for unique visitors is reached.
* utilize Ownable helper functions to manage ownership and transfer thereof with the onlyOwner modifier.
**/

//TODO multiple oracles --> https://github.com/smartcontractkit/chainlink/blob/master/evm/contracts/Aggregator.sol
contract MarketingROI is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    string constant APPENGINE_ENDPOINT = "https://chainlink-marketing-roi.appspot.com/?campaignId=";

    //ROPSTEN VALUES
    //TODO pass oracle + jobId as param instead of hardcoded
    address constant private CHAINLINK_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    string constant private HTTP_GET_INT_JOB_ID = "46a7c3f9852e46e09350ad5af92ce86f";
    string constant private HTTP_GET_UINT_JOB_ID = "3cff0a3524694ff8834bda9cf9c779a1";
    string constant private HTTP_GET_BYTE32_JOB_ID = "76ca51361e4e444f8a9b18ae350a5725";

    //todo better to have struct be max 256 bits?
    struct Campaign {
        string campaignId;
        uint256 amount;
        uint256 payoutSize;
        uint256 visitorsRequired;
        uint256 visitorsIncrement;
        uint256 uniqueVisitors;
        address agency;
        address client;
        //epoch in seconds of expiry of deadline to reach target - creator can ask refund after this date
        uint256 expiry;
    }

    //maps campaignId to campaign details
    mapping(string => Campaign) campaigns;
    //maps the payout request id to the campaign it was requested for
    mapping(bytes32 => string) payoutRequests;

    event CampaignThresholdReached(bytes32 indexed requestId, string indexed campaignid, uint256 indexed visitors);
    event CampaignThresholdNotReached(bytes32 indexed requestId, string indexed campaignid, uint256 indexed visitors);


    constructor() public Ownable(){
        setPublicChainlinkToken();
        setChainlinkOracle(CHAINLINK_ORACLE);
    }


    //retrieve current state for campaign
    function registeredVisitors(string _campaignId) public view returns (uint256){
        return campaigns[_campaignId].uniqueVisitors;
    }


    //todo pass array of strings of oracles to use and a max number of oracles to use
    //TODO add timestamp of registration and deadline time

    /**
    ** Registers a new campaign
    **
    ** @Param _requestId the chainlink request
    ** @Param _uniqueVisitors the amount of unique visitors on the page according to the oracle
    **
    **/
    function registerCampaign(string _campaignId, uint256 _visitorsRequired, uint256 _visitorsIncrement, address _agency, uint256 _expiry) public payable {
        assert(_visitorsRequired.length > 0, "Required visitors not set");
        assert(_visitorsIncrement.length > 0, "Visitors increment not set");
        assert(bytes(_campaignId).length > 0, "empty campaignId");
        assert(bytes(_agency).length > 0, "empty agency address");
        assert(bytes(campaigns[_campaignId]) == 0, "Campaign already exists"); //prevent overwriting after creation to hack the system

        campaigns[_campaignId] = Campaign(_campaignId, msg.value, _visitorsRequired, _visitorsIncrement, _agency, msg.sender, _expiry);
    }


    /**
    ** Caller creates request for the next partial payout of the given campaign.
    **
    ** @Param _campaignId the campaign to request next partial payout for
    **
    ** @Return the requestId for the oracle request
    **
    **/
    function requestCampaignPayout(string campaignId) public returns (bytes32 requestId) {
        //TODO understand memory usage here
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(HTTP_GET_UINT_JOB_ID), this, this.fulfillCampaignPayout.selector);
        req.add("get", append(APPENGINE_ENDPOINT, campaignId));
        req.add("path", "uniqueVisitors");
        req.addInt("times", 1);
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);

        //persist the fact that this request was made for the given campaignId so fulfillment knows what campaign to validate.
        payoutRequests[requestId] = campaignId;
    }

    /**
    ** Callback function for the Oracles when the amount of unique visitors have been retrieved
    ** Rely on recordChainlinkFulfillment Modifier to ensure that the caller and requestId are valid
    **
    ** @Param _requestId the chainlink request
    ** @Param _uniqueVisitors the amount of unique visitors on the page according to the oracle
    **
    **/
    function fulfillCampaignPayout(bytes32 _requestId, uint256 _uniqueVisitors) public recordChainlinkFulfillment(_requestId) {

        string storage campaignId = payoutRequests[_requestId];
        Campaign storage c = campaigns[campaignId];
        c.uniqueVisitors = _uniqueVisitors;

        //check if threshold has been reached
        if (c.uniqueVisitors >= c.visitorsRequired) {
            assert(c.amount > 0, "Funds fully paid");
            if (c.amount >= payoutSize) {
                //transfer an increment
                c.agency.transfer(payoutSize);
                //deduct outstanding amount
                c.amount -= payoutSize;
                //set the next target
                c.visitorsRequired += c.visitorsRequiredIncrement;
            } else {
                //if lower balance, transfer what's left
                c.agency.transfer(c.amount);
                //fee fully paid
                c.amount = 0;
                //no next target
            }
            //store updates
            campaigns[_campaignId] = c;

            //log
            emit CampaignThresholdReached(_requestId, _campaignId, _uniqueVisitors);
        } else {
            //log
            emit CampaignThresholdNotReached(_requestId, _campaignId, _uniqueVisitors);
        }
    }

    /**
    ** Allows the campaign owner to get back the ETH in case deadline for marketing agency exceeded
    **
    ** @Param _campaignId the campaign Id for which to request payout for
    **
    **/
    function cancelCampaign(string _campaignId) public {
        assert(bytes(_campaignId).length > 0, "empty campaignId");
        Campaign storage campaign = campaigns[_campaignId];
        assert(campaign.client == msg.sender, "Payout can only be requested by client");
        assert(campaign.amount > 0, "Funds fully paid");
        assert(now > campaign.expiry, "Campaign not expired yet - cannot refund yet");

        //All conditions validated - marketing agency failed to reach full target - pay back the outstanding amount to the client
        require(msg.sender.transfer(campaign.amount), "Ether refund failed");
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
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "LINK refund failed");
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