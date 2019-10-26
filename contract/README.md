# Solidity Smart Contract

## Context
This smart contract is the core of the business logic of the hackathon submission. Elaborate documentation of each function can be found as code comments. The core functionality of the contract is as follows:

Customers that want to hire a marketing agency to perform a marketing campaign can register this campaign with the Smart Contract. They device upon specific values such as the amount, required amount of website visitors that the campaign needs to bring and if there are partial payouts possible and if so, what the increments are.
Once deployed, the Smart Contract can be invoked by the Marketing Agency to request a payout. The Smart Contract will use the Custom Adapter registered with the Nodes to retrieve the amount of unique visitors. If this amount is sufficient, the marketing agency is paid out. If the customer (client) hiring the agency allowed for it, partial payouts are also allowed when specific intermediate targets have been reached. For example, if the agency will be paid 1 ETH for 100k visitors, then the smart contract could release 0.25ETH for each 25k visitors, if this was allowed by the customer during campaign registration. If the deadline has exceeded, the customer is allowed to ask a refund for the oustanding amount. The customer can also decide not to invoke this right and give the marketing agency a longer period of time to reach the target.

## Deploy
Deployment of the contract has been done using Remix which as connected to the local machine using remixd. Connection can be set up using `./remixd.sh`.

## Usage
Interaction with the contract has been done using Remix. Please see the main README in this project on a detailed usage of the contract in relation to the use case.