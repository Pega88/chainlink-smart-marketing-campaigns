# Concept
Marketing agencies have the difficult task of proving their ROI, making it hard for companies to invest in such campaigns. Companies want to be protected from spending money on a marketing campaign that does not deliver, as well as a marketing agency wants to get paid when certain criteria are met. One of these criteria that both parties could agree on, is the amount of new/unique visitors that landed on the website thanks to the marketing campaign (called clickthrough rate). A smart contract has been created that will payout the marketing agency once an agreed upon # unique visitors have visited the website within a timeframe.

Google Analytics data is sent to the SC through chainlink every day (currently every minute to showcase the use case). If the # visitors is reached, the marketing agency gets paid out. If by the deadline the # new visitors has not been reached, the company is returned the funds as the marketing campaign was not successful. This motivated the marketing agency to deliver high quality campaigns, as well as be directly paid when the goal is met.

# Pseudo code
createMktDeposit(amount a,recipient r, unique_visitors v, period p){
	//payout amount A to R when V visitors have visited the website based on the marketing campaign
	//if after p days the goal is not met, the funds are returned to the company.
}

postWebsiteTraffic(visitors v,){
	//if v on t is > threshold, payout.
}

data ingested RT into BQ.
--> # visitors only based on campagin --> UTM tag
to mimic days, every minut a scheduled Q is run to calculate the # visitors on page.

future work:
expand logic to increase of i% sustained over multiple days.
