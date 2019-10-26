# Node Configuration

## Context
Node Configuration for running the Chainlink node on localhost.  `JobSpec` defines the way the Custom Adapter has been 
The bridge has been created in the Chainlink Node GUI using the deployed URL from the Google Cloud Function (https://us-central1-chainlink-marketing-roi.cloudfunctions.net/bq-bridge).

## Deploy
Manually add the JobSpec to the node. Localhost node has been configured with the values written by `config.sh`. An API key was retrieved from fiews.io to avoid having to run a local ethereum node locally and allow for faster portability.

## Usage
Use the JobID that references the custom adapter/bridge when deploying the Smart Contract.