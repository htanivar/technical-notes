https://www.geeksforgeeks.org/awk-command-unixlinux-examples/

# Built-In Variables In Awk

1. NR: NR command keeps a current count of the number of input records. Remember that records are usually lines. Awk
   command performs the pattern/action statements once for each record in a file.
1. NF: NF command keeps a count of the number of fields within the current input record.
1. FS: FS command contains the field separator character which is used to divide fields on the input line. The default
   is “white space”, meaning space and tab characters. FS can be reassigned to another character (typically in BEGIN) to
   change the field separator.
1. RS: RS command stores the current record separator character. Since, by default, an input line is the input record,
   the default record separator character is a newline.
1. OFS: OFS command stores the output field separator, which separates the fields when Awk prints them. The default is a
   blank space. Whenever print has several parameters separated with commas, it will print the value of OFS in between
   each parameter.
1. ORS: ORS command stores the output record separator, which separates the output lines when Awk prints them. The
   default is a newline character. print automatically outputs the contents of ORS at the end of whatever it is given to
   print.

# AWK Examples

```agsl

ajay manager account 45000
sunil clerk account 25000
varun manager sales 50000
amit manager account 47000
tarun peon sales 15000
deepak clerk sales 23000
sunil peon sales 13000
satvik director purchase 80000
```

awk '$1 == "ajay" && $2 == "manager" && $3 == "account" { print $4 }' employee.txt
salary=$(awk '$1 == "ajay" && $2 == "manager" && $3 == "account" { print $4 }' employee.txt)
salary=$(awk -F',' '$1 == "ajay" && $2 == "manager" && $3 == "account" { print $4 }' employee.txt)
awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "sl" { print $4,$5 }' service.txt
awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "gl" { print $4,$5 }' service.txt
awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "sl" { print $4,$5 }' service.txt
awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "gl" { print $4,$5 }' service.txt
salary=$(awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "sl" { print $4,$5 }' service.txt)
salary=$(awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "gl" { print $4,$5 }' service.txt)
salary=$(awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "sl" { print $4,$5 }' service.txt)
salary=$(awk -F',' '$1 == "gozeus" && $2 == "dev" && $3 == "gl" { print $4,$5 }' service.txt)

| Command                                       | Purpose                                                 |
|-----------------------------------------------|---------------------------------------------------------|
| awk '{print}' employee.txt                    | Print the entire file                                   |
| awk '/manager/ {print}' employee.txt          | Print the lines which match the given pattern           |
| awk '{print $1,$4}' employee.txt              | Splitting a Line Into Fields                            |
| awk '{print NR, $0}' employee.txt             | Use of NR built-in variables (Display Line Number)      |
| awk '{print $1, $NF}' employee.txt            | Use of NF built-in variables (Display Last Field)       |
| awk 'NR==3, NR==6 {print NR,$0}' employee.txt | use of NR built-in variables (Display Line From 3 to 6) |
| -                                             | -                                                       |

```agsl

A    B    C
Tarun    A12    1
Man    B6    2
Praveen    M42    3

```

| Command                          | Purpose                                                                      |
|----------------------------------|------------------------------------------------------------------------------|
| awk '{print NR "- " $1}' abc.txt | first item along with the row number(NR) separated with ” – “ from each line |
|                                  |                                                                              |