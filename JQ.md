| Command                                                             | Description                                        |
|---------------------------------------------------------------------|----------------------------------------------------|
| `jq .filename.json`                                                 | Format JSON from a file                            |
| `curl -s https://api.example.com/data.json   ( pipe ) jq .`         | Pipe JSON from a URL and format with `jq`          |
| `jq .field filename.json`                                           | Extract a specific field from JSON                 |
| `jq '.field.subfield' filename.json`                                | Extract nested field from JSON                     |
| `jq '.array[]' filename.json`                                       | Iterate over elements in an array                  |
| `jq '.array[]  (pipe) select(.key == "value")' filename.json`       | Filter array elements based on a condition         |
| `jq 'map(.field)' filename.json`                                    | Apply a transformation to each element in an array |
| `jq 'length' filename.json`                                         | Get the length of an array or object               |
| `jq '. (pipe) keys' filename.json`                                  | Get the keys of an object                          |
| `jq '.[] (pipe) select(.key > 10)' filename.json`                   | Filter objects based on a condition                |
| `jq 'del(.field)' filename.json`                                    | Delete a field from an object                      |
| `jq 'has("field")' filename.json`                                   | Check if an object has a specific field            |
| `jq 'if .field == "value" then .elseField else .end' filename.json` | Conditional logic in `jq`                          |
| `jq '.[]  (pipe) .field (pipe) @csv' filename.json`                 | Convert JSON to CSV                                |
| `jq -c '.' filename.json`                                           | Compact output (remove pretty-printing)            |
| `jq -r '.field' filename.json`                                      | Output raw strings (remove quotes)                 |
| `jq '.field' filename.json (pipe) sed 's/"//g'`                     | Remove quotes from the output of `jq`              |
| `echo '{"key":"value"}' (pipe) jq .`                                | Format JSON from a string                          |
