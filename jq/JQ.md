| Feature                                                     | Description                              |
|-------------------------------------------------------------|------------------------------------------|
| [Selecting Fields](#selecting-fields)                       | Select specific fields from JSON objects |
| [Filtering Objects](#filtering-objects)                     | Filter JSON objects based on conditions  |
| [Modifying JSON](#modifying-json)                           | Modify JSON objects                      |
| [Sorting Arrays](#sorting-arrays)                           | Sort arrays                              |
| [Aggregation Functions](#aggregation-functions)             | Perform aggregations (e.g., sum, count)  |
| [Conditional Logic](#conditional-logic)                     | Use conditional statements (if-else)     |
| [Iterating over Arrays](#iterating-over-arrays)             | Iterate through arrays                   |
| [Variable Assignment](#variable-assignment)                 | Assign variables within JQ scripts       |
| [Regular Expressions](#regular-expressions)                 | Use regex for pattern matching           |
| [JSON Formatting](#json-formatting)                         | Format JSON output                       |
| [Custom Functions](#custom-functions)                       | Define and use custom functions          |
| [Composing JQ Scripts](#composing-jq-scripts)               | Combine multiple JQ commands in a script |
| [Compact and Pretty Printing](#compact-and-pretty-printing) | Format JSON output for readability       |

## selecting-fields

**Selecting Fields**

| Command purpose                           | Command                                     |
|-------------------------------------------|---------------------------------------------|
| Select a specific field from JSON objects | `jq '.field_name' input.json`               |
| Select nested fields from JSON objects    | `jq '.parent_field.child_field' input.json` |
| Select multiple fields from JSON objects  | `jq '.field1, .field2' input.json`          |
| Alias field selection                     | `jq '{ alias: .original_name }' input.json` |

## filtering-objects

**Filtering Objects**

| Command purpose                             | Command                                                               |
|---------------------------------------------|-----------------------------------------------------------------------|
| Filter objects where a field equals a value | `jq '.[] \| select(.field == "value")' input.json`                    |
| Filter objects based on multiple conditions | `jq '.[] \| select(.field1 > 10 and .field2 == "abc")' input.json`    |
| Filter objects with nested fields           | `jq '.[] \| select(.parent_field.child_field == "value")' input.json` |
| Filter objects based on array elements      | `jq '.[] \| select(.array_field[] > 5)' input.json`                   |
| Filter objects using regular expressions    | `jq '.[] \| select(.field \| test("pattern"))' input.json`            |

## modifying-json

**Modifying JSON**

| Command purpose                               | Command                                                                                |
|-----------------------------------------------|----------------------------------------------------------------------------------------|
| Add a new field to JSON objects               | `jq '.[] \| .new_field = "value"' input.json`                                          |
| Update existing fields in JSON objects        | `jq '.[] \| .field = .field * 2' input.json`                                           |
| Remove fields from JSON objects               | `jq '.[] \| del(.field_to_remove)' input.json`                                         |
| Rename fields in JSON objects                 | `jq '.[] \| .new_name = .old_name \| del(.old_name)' input.json`                       |
| Conditional modification based on field value | `jq '.[] \| if .field > 10 then .status = "high" else .status = "low" end' input.json` |

## sorting-arrays

**Sorting Arrays**

| Command purpose                               | Command                                              |
|-----------------------------------------------|------------------------------------------------------|
| Sort array elements in ascending order        | `jq 'sort' input.json`                               |
| Sort array elements in descending order       | `jq 'sort \| reverse' input.json`                    |
| Sort array elements based on a specific field | `jq 'sort_by(.field_name)' input.json`               |
| Reverse the order of array elements           | `jq 'reverse' input.json`                            |
| Sort array elements based on multiple fields  | `jq 'sort_by(.field1, .field2)' input.json`          |
| Sort array of objects based on nested fields  | `jq 'sort_by(.parent_field.child_field)' input.json` |

## aggregation-functions

**Aggregation Functions**

| Command purpose                          | Command                                               |
|------------------------------------------|-------------------------------------------------------|
| Calculate the sum of array elements      | `jq 'add' input.json`                                 |
| Calculate the average of array elements  | `jq 'add / length' input.json`                        |
| Count the number of elements in an array | `jq 'length' input.json`                              |
| Find the maximum value in an array       | `jq 'max' input.json`                                 |
| Find the minimum value in an array       | `jq 'min' input.json`                                 |
| Concatenate strings in an array          | `jq 'reduce .[] as $item (""; . + $item)' input.json` |

## conditional-logic

**Conditional Logic**

| Command purpose                                                      | Command                                                                                                                                                                                  |
|----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Use if-then-else statement to conditionally modify JSON objects      | `jq '.[] \| if .field > 10 then .status = "high" else .status = "low" end' input.json`                                                                                                   |
| Filter objects based on a condition using the `select` function      | `jq '.[] \| select(.field == "value")' input.json`                                                                                                                                       |
| Use boolean operators (&&,                                           |                                                                                                                                                                                          |, !) in conditional statements      | `jq '.[] \| select(.field1 > 10 and .field2 == "abc")' input.json` |
| Use if-then-else statement to conditionally modify JSON objects      | `jq '.[] \| if .age > 18 then .category = "adult" elif .age > 12 then .category = "teenager" else .category = "child" end' input.json`                                                   |
| Filter objects based on multiple conditions using logical OR         | `jq '.[] \| select(.age < 18 or .is_student == true)' input.json`                                                                                                                        |
| Filter objects based on multiple conditions using logical AND        | `jq '.[] \| select(.age > 18 and .is_employed == true)' input.json`                                                                                                                      |
| Use negation to filter objects where a field is not equal to a value | `jq '.[] \| select(.status != "inactive")' input.json`                                                                                                                                   |
| Conditionally filter objects based on array length                   | `jq '.[] \| select(length(.friends) > 5)' input.json`                                                                                                                                    |
| Use if-then-else statement with complex conditions                   | `jq '.[] \| if .age >= 18 and .country == "USA" then .status = "eligible" elif .age >= 18 and .country != "USA" then .status = "not eligible" else .status = "underage" end' input.json` |

## iterating-over-arrays

**Iterating over Arrays**

| Command purpose                                              | Command                                                                          |
|--------------------------------------------------------------|----------------------------------------------------------------------------------|
| Iterate over array elements and perform an action            | `jq '.[] \| .field_name = .field_name * 2' input.json`                           |
| Use the `foreach` construct to iterate and manipulate arrays | `jq 'foreach .[] as $item (.; . + $item.field_name)' input.json`                 |
| Filter objects based on array elements                       | `jq '.[] \| select(.array_field[] > 5)' input.json`                              |
| Apply conditional logic inside array iteration               | `jq '.[] \| .new_field = if .field1 > 10 then "high" else "low" end' input.json` |

## variable-assignment

**Variable Assignment**

| Command purpose                      | Command                                                                       |
|--------------------------------------|-------------------------------------------------------------------------------|
| Assign a variable to a field value   | `jq '.[] \| .new_field = .existing_field' input.json`                         |
| Use variables in calculations        | `jq '.[] \| .total = .price * .quantity' input.json`                          |
| Assign variables based on conditions | `jq '.[] \| .status = if .age > 18 then "adult" else "minor" end' input.json` |
| Use variables in filtering           | `jq 'foreach .[] as $item (.; select($item.field > 10))' input.json`          |

## regular-expressions

**Regular Expressions**

| Command purpose                                          | Command                   |
|----------------------------------------------------------|---------------------------|
| Filter objects based on a regex pattern with global flag | `jq '.[] \| select(.field | test("pattern"; "g"))' input.json`           |
| Extract all matches from a field using regex capture     | `jq '.[] \| .field        | capture_all("pattern")' input.json`                       |
| Filter objects based on a regex pattern and ignore case  | `jq '.[] \| select(.field | test("pattern"; "i"))' input.json`       |
| Extract specific groups using regex capture              | `jq '.[] \| .field        | capture("pattern"; "g"; "group1", "group2")' input.json` |
| Use regex to validate and filter objects                 | `jq '.[] \| select(.field | test("^[A-Za-z]+$"))' input.json`     |
| Replace text based on a regex pattern and ignore case    | `jq '.[] \| .field        | sub("pattern"; "replacement"; "i")' input.json`           |

## json-formatting

**JSON Formatting**

| Command purpose                              | Command                                                   |
|----------------------------------------------|-----------------------------------------------------------|
| Pretty print JSON output                     | `jq '.' input.json`                                       |
| Compact JSON output                          | `jq -c '.' input.json`                                    |
| Format JSON output with specific indentation | `jq '{ field1: .field1, field2: .field2 }' input.json`    |
| Include newlines in JSON output              | `jq -n '{ field1: .field1, field2: .field2 }' input.json` |

## custom-functions

**Custom Functions**

| Command purpose                                         | Command                                                                                                                           |
|---------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| Define a custom function in JQ                          | `jq 'def myFunction(arg): arg * 2; .[] \| myFunction(.field)' input.json`                                                         |
| Use a custom function in JQ                             | `jq 'def myFunction(arg): arg * 2; .[] \| myFunction(.field)' input.json`                                                         |
| Pass multiple arguments to a custom function            | `jq 'def sum(x; y): x + y; .[] \| sum(.field1; .field2)' input.json`                                                              |
| Define and use a custom function with conditional logic | `jq 'def status(age): if age > 18 then "adult" else "minor"; .[] \| { name: .name, age: .age, status: status(.age) }' input.json` |

## composing-jq-scripts

**Composing JQ Scripts**

| Command purpose                                                         | Command                                                                                                                                                        |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Compose multiple JQ filters in a single script                          | `jq '.[] \| select(.age > 18) \| { name: .name, age: .age }' input.json`                                                                                       |
| Use JQ variables to compose complex scripts                             | `jq 'def isAdult(age): age > 18; .[] \| select(isAdult(.age)) \| { name: .name, age: .age }' input.json`                                                       |
| Combine JQ filters and functions to process JSON data in a specific way | `jq 'def isAdult(age): age > 18; .[] \| select(isAdult(.age)) \| { name: .name, age: .age, category: if .age > 21 then "adult" else "minor" end }' input.json` |

## Compact and Pretty Printing

**Compact and Pretty Printing**

| Command purpose                                 | Command                                                   |
|-------------------------------------------------|-----------------------------------------------------------|
| Pretty print JSON output for better readability | `jq '.' input.json`                                       |
| Compact JSON output to remove extra whitespace  | `jq -c '.' input.json`                                    |
| Format JSON output with specific indentation    | `jq '{ field1: .field1, field2: .field2 }' input.json`    |
| Include newlines in JSON output                 | `jq -n '{ field1: .field1, field2: .field2 }' input.json` |

**Old Example**

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
