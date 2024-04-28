| User Commands                                  | Admin Commands                              | Network Commands                      |
|------------------------------------------------|---------------------------------------------|---------------------------------------|
| [FINDSTR Commands](#findstr-commands)          | [SYSTEMINFO Commands](#systeminfo-commands) | [NETSTAT Commands](#netstat-commands) |
| [TASKKILL_Commands](#taskkill-commands)        |                                             |                                       |
| [STRINGMANIPUATION_COMMANDS](#strman-commands) |                                             |                                       |
| [PIPE_COMMANDS](#pipe-commands)                |                                             |                                       |

## systeminfo-commands

**SYSTEMINFO Commands**

| Command                                   | Description                                                          |
|-------------------------------------------|----------------------------------------------------------------------|
| `systeminfo`                              | Displays detailed configuration information about a computer         |
| `hostname`                                | Displays the name of the current host                                |
| `ipconfig /all`                           | Displays all current TCP/IP network configuration values             |
| `netstat -ano`                            | Displays active network connections and ports                        |
| `tasklist`                                | Displays a list of currently running processes and their PID         |
| `wmic os get Caption, Version`            | Retrieves information about the operating system                     |
| `wmic cpu get Name, MaxClockSpeed`        | Retrieves CPU information, including name and max clock speed        |
| `wmic memorychip get BankLabel, Capacity` | Retrieves memory chip information, including bank label and capacity |

## netstat-commands

**NETSTAT Commands**

| Command                 | Description                                                                             |
|-------------------------|-----------------------------------------------------------------------------------------|
| `netstat -a`            | Displays all active TCP connections and the TCP and UDP ports                           |
| `netstat -b`            | Displays the executable involved in creating each connection or listening port          |
| `netstat -e`            | Displays Ethernet statistics, such as the number of bytes and packets sent and received |
| `netstat -n`            | Displays addresses and port numbers in numerical form                                   |
| `netstat -o`            | Displays the owning process ID associated with each connection                          |
| `netstat -p [protocol]` | Shows connections for the specified protocol (TCP, UDP, TCPv6, UDPv6)                   |
| `netstat -r`            | Displays the routing table                                                              |
| `netstat -s`            | Displays per-protocol statistics                                                        |
| `netstat -t`            | Displays all active TCP connections                                                     |
| `netstat -u`            | Displays all active UDP connections                                                     |
| `netstat -v`            | Displays extended information                                                           |
| `netstat -x`            | Displays Network Direct connections statistics                                          |

## findstr-commands

**FINDSTR Commands**

| Command                                        | Description                                                                                        |
|------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `findstr "pattern" filename`                   | Searches for the specified pattern in the given file                                               |
| `findstr /C:"pattern1" /C:"pattern2" filename` | Searches for multiple patterns in the given file                                                   |
| `findstr /S "pattern" *.txt`                   | Searches for the pattern recursively in all .txt files in the current directory and subdirectories |
| `findstr /I "pattern" filename`                | Performs a case-insensitive search for the pattern                                                 |
| `findstr /V "pattern" filename`                | Displays all lines that do not contain the specified pattern                                       |
| `findstr /R "pattern" filename`                | Searches using regular expressions for the specified pattern                                       |
| `findstr /B "pattern" filename`                | Searches for patterns that are at the beginning of a line                                          |
| `findstr /E "pattern" filename`                | Searches for patterns that are at the end of a line                                                |
| `findstr /L /G:patterns.txt filename`          | Searches for patterns listed in a separate file (patterns.txt)                                     |
| `findstr /M "pattern" filename`                | Displays only the filename if a match is found (does not show lines)                               |
| `findstr /N "pattern" filename`                | Displays line numbers along with the matching lines                                                |

## taskkill-commands

**TASKKILL Commands**

| Command                                                       | Description                                                               |
|---------------------------------------------------------------|---------------------------------------------------------------------------|
| `taskkill /IM process_name`                                   | Terminates a process by its image name (e.g., `taskkill /IM notepad.exe`) |
| `taskkill /PID process_id`                                    | Terminates a process by its process ID (PID)                              |
| `taskkill /F /IM process_name`                                | Forces termination of a process by its image name                         |
| `taskkill /F /PID process_id`                                 | Forces termination of a process by its process ID                         |
| `taskkill /S system /U username /P password /IM process_name` | Terminates a process on a remote system by its image name                 |
| `taskkill /S system /U username /P password /PID process_id`  | Terminates a process on a remote system by its process ID                 |
| `taskkill /FI "filter_expression"`                            | Terminates processes that match the specified filter expression           |
| `taskkill /T /PID process_id`                                 | Terminates a process and all its child processes                          |
| `taskkill /IM process_name /FI "filter_expression"`           | Terminates processes by both image name and filter expression             |
| `taskkill /PID process_id /T`                                 | Terminates a process and all its child processes                          |
| `taskkill /PID process_id /F`                                 | Forces termination of a process and its child processes                   |

## strman-commands

**STRINGMANIPULATION Commands**

| Command                                                    | Description                                              |
|------------------------------------------------------------|----------------------------------------------------------|
| `set /P variable_name=string`                              | Reads input from the user and assigns it to a variable.  |
| `set variable_name=value`                                  | Sets the value of a variable.                            |
| `set combined_string=%str1%%str2%`                         | Combines strings and assigns the result to a variable.   |
| `echo %variable_name%`                                     | Displays the value of a variable.                        |
| `echo message`                                             | Displays a message.                                      |
| `find /I "string" filename`                                | Searches for a string in a file (case-insensitive).      |
| `findstr "pattern" filename`                               | Searches for strings in files using regular expressions. |
| `replace "old" "new" filename`                             | Replaces one string with another in a file.              |
| `set string=Hello World`                                   | Sets a string variable.                                  |
| `echo %string:~start,length%`                              | Outputs a substring of a string.                         |
| `echo %string% has %len(%string%) characters`              | Gets the length of a string and displays it.             |
| `for /F "options" %%variable in (file/command) do command` | Iterates through lines of a file or command output.      |

## pipe-commands

**PIPE Commands**

| Command                           | Description                                                                  |
|-----------------------------------|------------------------------------------------------------------------------|
| `command1 \| command2`            | Pipes the output of `command1` as input to `command2`                        |
| `dir \| find "search_string"`     | Lists files and directories in the current directory and filters by a string |
| `tasklist \| find "chrome"`       | Lists running processes and filters for processes containing "chrome"        |
| `ipconfig \| findstr "IPv4"`      | Displays network configuration and filters for lines containing "IPv4"       |
| `type filename \| find "pattern"` | Displays the content of a file and filters for lines containing "pattern"    |
| `dir \| sort`                     | Lists files and directories in alphabetical order                            |
| `tasklist \| sort /R`             | Lists running processes in reverse order of their process IDs                |
| `ipconfig /all \| clip`           | Displays detailed network configuration and copies it to the clipboard       |
| `systeminfo \| find "OS Name"`    | Displays detailed system information and filters for "OS Name"               |

**Find the process using & port**

    netstat -ano | find "8080"
    taskkill /PID 7324
