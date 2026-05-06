Bpackage main

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
)

type Difference struct {
	Path   string
	Issue  string
	PrdVal interface{}
	StgVal interface{}
}

func main() {
	prdFile := "prd.json"
	stgFile := "stg.json"

	var prdData interface{}
	var stgData interface{}

	loadJSON(prdFile, &prdData)
	loadJSON(stgFile, &stgData)

	var diffs []Difference
	compareJSON("", prdData, stgData, &diffs)

	if len(diffs) == 0 {
		fmt.Println("✅ JSON structures are identical")
		return
	}

	fmt.Println("❌ Differences found:")
	for _, d := range diffs {
		fmt.Printf(
			"Path: %s\nIssue: %s\nPrd: %v\nStg: %v\n\n",
			d.Path,
			d.Issue,
			d.PrdVal,
			d.StgVal,
		)
	}
}

func loadJSON(file string, target interface{}) {
	data, err := os.ReadFile(file)
	if err != nil {
		panic(err)
	}

	if err := json.Unmarshal(data, target); err != nil {
		panic(err)
	}
}

func compareJSON(path string, prd interface{}, stg interface{}, diffs *[]Difference) {
	prdType := reflect.TypeOf(prd)
	stgType := reflect.TypeOf(stg)

	if prdType != stgType {
		*diffs = append(*diffs, Difference{
			Path:   path,
			Issue:  "datatype mismatch",
			PrdVal: prdType,
			StgVal: stgType,
		})
		return
	}

	switch prdVal := prd.(type) {

	case map[string]interface{}:
		stgVal := stg.(map[string]interface{})

		// Check missing keys in stg
		for key, v := range prdVal {
			newPath := buildPath(path, key)

			if _, exists := stgVal[key]; !exists {
				*diffs = append(*diffs, Difference{
					Path:   newPath,
					Issue:  "missing key in stg",
					PrdVal: v,
					StgVal: nil,
				})
				continue
			}

			compareJSON(newPath, v, stgVal[key], diffs)
		}

		// Check extra keys in stg
		for key, v := range stgVal {
			if _, exists := prdVal[key]; !exists {
				*diffs = append(*diffs, Difference{
					Path:   buildPath(path, key),
					Issue:  "extra key in stg",
					PrdVal: nil,
					StgVal: v,
				})
			}
		}

	case []interface{}:
		stgVal := stg.([]interface{})

		if len(prdVal) == 0 || len(stgVal) == 0 {
			return
		}

		// Compare first element structure
		compareJSON(path+"[0]", prdVal[0], stgVal[0], diffs)
	}
}

func buildPath(base, key string) string {
	if base == "" {
		return key
	}
	return base + "." + key
}
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B
B

