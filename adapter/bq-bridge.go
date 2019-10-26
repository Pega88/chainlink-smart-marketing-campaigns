package bq

import (
	"github.com/linkpoolio/bridges"
	"cloud.google.com/go/bigquery"
	"context"
	"google.golang.org/api/iterator"
	"log"
	"net/http"
)

// CryptoCompare is the most basic Bridge implementation, as it only calls the api:
// https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,JPY,EUR
type CryptoCompare struct{}

// Run is the bridge.Bridge Run implementation that returns the price response
func (cc *CryptoCompare) Run(h *bridges.Helper) (interface{}, error) {
	visitors := getNumUniqueVisitors();
	r := ud := map[string]interface{}{"uniqueVitors": visitors}
	return r, err
}

func Handler(w http.ResponseWriter, r *http.Request) {
	bridges.NewServer(&CryptoCompare{}).Handler(w, r)
}

// Opts is the bridge.Bridge implementation
func (cc *CryptoCompare) Opts() *bridges.Opts {
	return &bridges.Opts{
		Name:   "CryptoCompare",
	}
}

type Visitors struct {
	Visitors int64 `bigquery:"visitors"`
}

func getNumUniqueVisitors() int64 {
	ctx := context.Background()
	client, err := bigquery.NewClient(ctx, proj)
	if err != nil {
		log.Fatal(err)
		return -1;
	}
	query := client.Query(
		`
    	SELECT
    	COUNT(DISTINCT fullVisitorId) AS visitors
    	FROM` +
			"`chainlink-marketing-roi.ga_export.ga_stream`" +
			`WHERE
    	trafficsource_source = "chainlink_campaign";`)

	iter, read_error := query.Read(ctx)
	if read_error != nil {
		log.Fatal(err)
	}
	for {
		var row Visitors
		iterError := iter.Next(&row)
		if iterError == iterator.Done {
			return 0
		}
		if iterError != nil {
			log.Fatal(iterError)
			return -1
		}
		log.Info("unique visitors: %d", row.Visitors)
		return row.Visitors
	}
}