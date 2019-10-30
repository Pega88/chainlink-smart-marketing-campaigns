# Concept
**Introduction**

Marketing agencies have the difficult task of proving their ROI, making it hard for companies to invest in such campaigns. Companies want to be protected from spending money on a marketing campaign that does not deliver, as well as a marketing agency wants to get paid when certain criteria are met. One of these criteria that both parties could agree on, is the amount of new/unique visitors that landed on the website thanks to the marketing campaign (called clickthrough rate).

In the scope of the Virtual Chainlink Hackathon, a smart contract has been created that will payout the marketing agency once an agreed upon # unique visitors have visited the website within a timeframe. Agencies have the option to be rewarded with partial payouts for intermediate targets and the customers can recover the outstanding amount when the target has not been reached on the agreed upon deadline.

**The Basics**

Google Analytics data is streamed into Google BigQuery as a native feature of Google Analytics 360. This is data on hit-level (user click) so this dataset is both massive in size as well as it is valuable. The power of Google BigQuery is that it can scan TB or PB of data in just seconds. A SQL query can thus be run on this dataset to query the amount of visitors that reached visited the website.

Marketing campaigns often use an HTTP GET parameter, for example `utm_source`, to attribute the visit to the campaign from where the user clicked through (e.g. Advertisement, email campaign). All hyperlinks for a campaign contain this parameter. Querying for unique visitors while filtering on a specific `utm_source` shows us how many users have visited the site as a consequence of the marketing campaign. This metric is often used to show the ROI (Return on Investment) for a specific marketing campaign and to monitor its success. 

Thanks to this hackathon submission, actual performance payouts can now be linked to the amount if unique visitors rather than the metric only being used in campaign reporting. Customers that want to hire a marketing agency can register their campaign with this Smart Contract and set the payment terms. Some of these parameters are the amount to be paid, the agency to be paid and the amount of visitors required for a payout to happen. More details can be found in the `contract` section.

If the amount visitors is reached, the marketing agency can request to be paid out. If by the deadline the amount new visitors has not been reached, the company can request the remaining funds to be returned as the marketing campaign was not fully successful.

This motivated the marketing agency to deliver high quality campaigns, as well as be directly paid when the goal is met. For customers they have more guarantees on success, as well as marketing agencies can really stand out and show their reputation on the blockchain (amount of successful paid out campaigns) rather than the customer having to trust the agency on its word when they claim their campaigns have great ROI.

Marketing agencies delivering quality campaigns will therefore thrive, and they will be paid out in accordance with the initial agreements, rather than having to wait months on outstanding invoices for a badly paying customer.

# Demo

[![Demonstration of concept](https://img.youtube.com/vi/iKxMRBbYoss/0.jpg)](https://www.youtube.com/watch?v=iKxMRBbYoss)

The above video demonstrates the basic usage of the Smart Contract as well as the deployed Custom Adapter.

# Future work

**Multiple websites**

Currently the Custom Adapter is linked to my own BigQuery dataset for the website of my company (https://fourcast.io), because that's the Google Analytics and BigQuery data I had access to. When put into production, every customer will have its own BigQuery datasets which should be reflected in the Bridge and Smart Contract. For **security** this is an ideal scenario. Having only access to a view limits the options and makes it impossible for any SQL-injection-like operation to modify any data (there's only view access, no write access). 

**Better validation**

Currently, anyone can trigger new visits as shown in the demo video, by opening new requests to the website. This is problem domain in itself and many solutions exist to filter out these fraudulent visits, which could allow fake traffic to attribute as real traffic. One of the simplest solutions would be to conduct campaigns that focus on new user registrations, in which case a unique client id can be added as a [custom dimension](https://support.google.com/analytics/answer/2709829?hl=en) only on pages that are accessible for logged in users. This is a simplification of a solution and is a broad topic of discussion in the marketing & ad:tech ecosystem.

**Integration**

For the scope of the hackathon, the decision was made to work as low level as possible to show full understanding and impact of the solution. This resulted in working with remix and not yet integrating the solution with e.g. trufflebox. Future work should focus on writing tests and integrating with Trufflebox to manage the deployment and migration of the smart contract. There is currently no frontend and no unit tests on the Smart Contract itself (combination of priorities on the End-to-End flow + limited experience of NodeJS / Javascript). Depending on priorities I might expand further on creating a web front-end to for enterprises to actually make use of this hackathon submission, which should be seen as a POC/MVP of the concept.

**Access Management**

At this moment I deployed the Google Cloud Function that serves as the Custom Adapter on the same Google Cloud Project as where the BigQuery dataset resides. The result is that the default Service Account used by Cloud Functions has the rights to read the dataset (as it's not public). Other nodes deploying this bridge should communicate their Google Cloud Platform Service Account which needs to be given access to read data from the same BigQuery dataset.

**Aggregation**

When more Nodes deploy the adapter, the Smart Contract should be adapted to reflect multiple oracles and use an aggregation as per https://github.com/smartcontractkit/chainlink/blob/master/evm/contracts/Aggregator.sol to aggergate results. Due to the fact of having a custom adapter, focus was not on setting up multiple oracles and chainlink nodes but rather on making the solution work End-to-End.
