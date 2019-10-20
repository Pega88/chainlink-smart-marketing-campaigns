package main

import (
	"cloud.google.com/go/bigquery"
	"context"
	"encoding/json"
	"fmt"
	"google.golang.org/api/iterator"
	"log"
	"net/http"
	"os"
)

var proj string

type UniqueVisitors struct {
	UniqueVisitors int64 `json:"uniqueVisitors"`
}

func main() {

	http.HandleFunc("/", indexHandler)

	proj = os.Getenv("GOOGLE_CLOUD_PROJECT")
	if proj == "" {
		proj = "chainlink-marketing-roi"
	}

	//GAE env sets port env - dynamically allocated.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("Defaulting to port %s", port)
	}

	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}

//TODO - add website param, add date param, add Auth token
func indexHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	v := UniqueVisitors{getNumUniqueVisitors()}
	json.NewEncoder(w).Encode(v)
}

type Visitors struct {
	Visitors int64 `bigquery:"visitors"`
}

func getNumUniqueVisitors() int64 {
	ctx := context.Background()
	client, err := bigquery.NewClient(ctx, proj)
	if err != nil {
		log.Fatal(err)
		os.Exit(1)
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
		fmt.Printf("unique visitors: %d", row.Visitors)
		return row.Visitors
	}
}
