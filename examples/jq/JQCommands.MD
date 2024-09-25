| Description                         | Command                                                                                                                     |
|-------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| is valid json                       | `jq empty input.json`                                                                                                       |
| find the Name                       | `cat input.json  \| jq '.data[].name'`                                                                                      |
| find the Name and the pet names     | `cat input.json \| jq -r \'.data[] \| "\( .name ) - \( .pets[].name )"\'`                                                   |
| create another JSON from the result | `cat input.json \| jq '[.data[] \| {name: .name, age: .age, pets: (.pets[] \| {name: .name, cost: .cost})}]' > output.json` |