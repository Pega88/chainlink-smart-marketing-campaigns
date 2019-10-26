# App Engine Application

## Context
This application was made in the first stage of the hackathon to expose the amount of visitors based on an BigQuery query as a JSON HTTP GET endpoint. This was used at first to get familiar with Solidity and the httpGet adapter Chainlink provides. Later on a bridge was added for my own Chainlink Node to use, making this app by itself obsolete. Left here fore later reference and for a fallback when Custom Adapter Development would not be successful. It queries a view on top of the actual raw Google Analytics data as to expose only relevant data and protect PII data from being read by all authorized nodes. The SQL with which the view has been created can be found in ga_stream.sql.

## Deploy
`$gcloud app deploy --project chainlink-marketing-roi`

## Usage
`curl https://chainlink-marketing-roi.appspot.com/`