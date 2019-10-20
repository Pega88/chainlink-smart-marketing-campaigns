pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm/contracts/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm/contracts/vendor/Ownable.sol";

contract ATestnetConsumer is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;

    uint256 public currentPrice;
    int256 public changeDay;
    bytes32 public lastMarket;

    event RequestEthereumPriceFulfilled(
        bytes32 indexed requestId,
        uint256 indexed price
    );


    constructor() public Ownable() {
        setPublicChainlinkToken();
    }

    function requestEthereumPrice(address _oracle, string _jobId)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumPrice.selector);
        req.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        req.add("path", "USD");
        req.addInt("times", 100);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function requestEthereumChange(address _oracle, string _jobId)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumChange.selector);
        req.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        req.add("path", "RAW.ETH.USD.CHANGEPCTDAY");
        req.addInt("times", 1000000000);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function requestEthereumLastMarket(address _oracle, string _jobId)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumLastMarket.selector);
        req.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");
        string[] memory path = new string[](4);
        path[0] = "RAW";
        path[1] = "ETH";
        path[2] = "USD";
        path[3] = "LASTMARKET";
        req.addStringArray("path", path);
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
    {
        emit RequestEthereumPriceFulfilled(_requestId, _price);
        currentPrice = _price;
    }

}

/**
* Contract will payout marketing agency once agreed upon threshold for unique visitors is reached.
* utilize Ownable helper functions to manage ownership and transfer thereof with the onlyOwner modifier.
**/
contract MarketingROI is ChainlinkClient, Ownable {
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    string constant APPENGINE_ENDPOINT = "https://chainlink-marketing-roi.appspot.com";

    //ROPSTEN VALUES
    address constant private CHAINLINK_ORACLE = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    byte32 constant private HTTP_GET_INT_JOB_ID = "46a7c3f9852e46e09350ad5af92ce86f";
    byte32 constant private HTTP_GET_UINT_JOB_ID = "3cff0a3524694ff8834bda9cf9c779a1";
    byte32 constant private HTTP_GET_BYTE32_JOB_ID = "76ca51361e4e444f8a9b18ae350a5725";


    event RequestGetVisitorsFullfilled(
        bytes32 indexed requestId,
        uint256 indexed visitors
    );

    constructor() public Ownable(){
        setPublicChainlinkToken();
        setChainlinkOracle(CHAINLINK_ORACLE);
    }

    function checkVisitors() public returns (bytes32 requestId) {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(HTTP_GET_UINT_JOB_ID), this, this.fulfillEthereumPrice.selector);
        req.add("get", APPENGINE_ENDPOINT);
        req.add("path", "uniqueVisitors");
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", 1);
        // Sends the request with 1 LINK to the oracle contract
        requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
    }


    // fulfillEthereumPrice receives a uint256 data type
    function fulfillEthereumPrice(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        price = _price;
        emit gotResponse(price);
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