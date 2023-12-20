| Syntax Element     | Description                                                    |
|--------------------|----------------------------------------------------------------|
| Literal Characters | Match characters literally, e.g., `abc` matches "abc".         |
| Character Classes  | `[abc]`: Matches any one of the characters a, b, or c.         |
| Quantifiers        | `*`: Matches 0 or more occurrences of the preceding element.   |
|                    | `+`: Matches 1 or more occurrences of the preceding element.   |
|                    | `?`: Matches 0 or 1 occurrence of the preceding element.       |
|                    | `{min, max}`: Matches between min and max occurrences.         |
| Anchors            | `^`: Anchors the regex at the start of the string.             |
|                    | `$`: Anchors the regex at the end of the string.               |
| Escape Characters  | `\`: Escapes a special character, treating it as literal.      |
| Dot (Wildcard)     | `.`: Matches any single character except a newline.            |
| Alternation        | `\|`: Logical OR, matches either pattern on the left or right. |
| Grouping           | `()`: Groups elements together.                                |
| Character Escapes  | `\d`: Matches any digit (0-9).                                 |
|                    | `\w`: Matches any word character (alphanumeric + underscore).  |
|                    | `\s`: Matches any whitespace character (space, tab, newline).  |
| Word Boundaries    | `\b`: Matches a word boundary.                                 |
| Assertions         | `(?=...)`: Positive lookahead assertion.                       |
|                    | `(?!...)`: Negative lookahead assertion.                       |
|                    | `(?<=...)`: Positive lookbehind assertion.                     |
|                    | `(?<!...)`: Negative lookbehind assertion.                     |

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
