| Command                         | Description                                   |
|---------------------------------|-----------------------------------------------|
| `[[ string =~ regex ]]`         | Check if a string matches a regex pattern     |
| `expr "$string" : 'regex'`      | Extract matched portion using `expr`          |
| `grep -E 'regex' file`          | Search for regex pattern in a file            |
| `sed 's/regex/replacement/'`    | Replace regex pattern with a string           |
| `awk '/regex/ {print $0}'`      | Print lines matching regex pattern            |
| `find . -regex 'regex'`         | Find files/directories matching regex pattern |
| `[[ string =~ ^regex$ ]]`       | Ensure the entire string matches the regex    |
| `grep -P 'regex' file`          | Use Perl-compatible regex in `grep`           |
| `sed -E 's/regex/replacement/'` | Use extended regex in `sed`                   |
| `awk '$1 ~ /regex/ {print $0}'` | Filter lines based on regex in `awk`          |

Replace `string`, `regex`, and other placeholders with your actual values. The table provides a quick reference for
various scenarios where regular expressions are commonly used in Bash.
