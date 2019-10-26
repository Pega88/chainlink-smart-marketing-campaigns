# Chainlink Custom Adapter

## Context
This Chainlink Custom Adapter replaces the initial App Engine deployment and queries Google Cloud BigQuery to request the amount of unique visitors registered for a specific marketing campaign. It queries a view on top of the actual raw Google Analytics data as to expose only relevant data and protect PII data from being read by all authorized nodes. See ../app/ga_stream.sql for details.

## Deploy
`gcloud functions deploy bridge --runtime go111 --entry-point Handler --trigger-http --project chainlink-marketing-roi`

## Usage
`curl -d {} -H "Content-Type: application/json" -X POST https://us-central1-chainlink-marketing-roi.cloudfunctions.net/bq-bridge`