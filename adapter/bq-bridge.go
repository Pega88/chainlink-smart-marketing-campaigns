package bq

import (
	"cloud.google.com/go/bigquery"
	"context"
	"github.com/linkpoolio/bridges"
	"google.golang.org/api/iterator"
	"log"
	"net/http"
)

type BigQueryVisitors struct{}

// Run is the bridge.Bridge Run implementation that returns the price response
func (cc *BigQueryVisitors) Run(h *bridges.Helper) (interface{}, error) {
	log.Print("before running")
	campaignId := h.GetParam("campaignId")
	log.Print("campaignId from request:",campaignId)
	visitors, err := getNumUniqueVisitors(campaignId)
	log.Print("returned vistors to bridge Run: ",visitors)
	r := map[string]interface{}{"uniqueVitors": visitors}
	return r, err
}

func Handler(w http.ResponseWriter, r *http.Request) {
	bridges.NewServer(&BigQueryVisitors{}).Handler(w, r)
}

// Opts is the bridge.Bridge implementation
func (cc *BigQueryVisitors) Opts() *bridges.Opts {
	return &bridges.Opts{
		Name: "BigQueryVisitors",
	}
}

type Visitors struct {
	Visitors int64 `bigquery:"visitors"`
}

func getNumUniqueVisitors(campaignId string) (int64, error) {
	ctx := context.Background()
	client, err := bigquery.NewClient(ctx, "chainlink-marketing-roi")
	if err != nil {
		log.Fatal(err)
		return -1, err
	}
	query := client.Query(
		`
    	SELECT COUNT(DISTINCT fullVisitorId) AS visitors FROM ` +
			"`chainlink-marketing-roi.ga_export.ga_stream` " +
			`WHERE
    	trafficsource_source ="` +
			campaignId +
			`";`)

	iter, read_error := query.Read(ctx)
	if read_error != nil {
		log.Fatal(err)
	}
	for {
		var row Visitors
		iterError := iter.Next(&row)
		if iterError == iterator.Done {
			return -1, iterError
		}
		if iterError != nil {
			log.Fatal(iterError)
			return -1, iterError
		}
		log.Print("unique visitors: %d", row.Visitors)
		return row.Visitors, nil
	}
}
