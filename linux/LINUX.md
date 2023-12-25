| User Commands                   | Admin Commands                            | Network Commands                            |
|---------------------------------|-------------------------------------------|---------------------------------------------|
| [CURL Commands](#curl-commands) | [USER Commands](#user-commands)           | [PING Commands](#ping-commands)             |
| [WGET Commands](#wget-commands) | [SUDO Commands](#sudo-commands)           | [PING Commands](#ping-commands)             |
| [DF Commands](#df-commands)     | [SSH Commands](#ssh-commands)             | [TCPDUMP Commands](#tcpdump-commands)       |
| [DU Commands](#du-commands)     | [PS Commands](#ps-commands)               | [NETSTAT Commands](#netstat-commands)       |
| [GREP Commands](#grep-commands) | [TOP Commands](#top-commands)             | [ROUTE Commands](#route-commands)           |
| [AWK Commands](#awk-commands)   | [IFCONFIG Commands](#ifconfig-commands)   | [TRACEROUTE Commands](#traceroute-commands) |
| [SED Commands](#sed-commands)   | [SYSTEMCTL Commands](#systemctl-commands) | [ARP Commands](#arp-commands)               |
| [TAR Commands](#tar-commands)   | -                                         | [IWCONFIG Commands](#iwconfig-commands)     |
| [SCP Commands](#scp-commands)   | -                                         | [HOSTNAME Commands](#hostname-commands)     |
| [IP Commands](#ip-commands)     | -                                         | [SS Commands](#ss-commands)                 |
| [LN Commands](#ln-commands)     | -                                         | [LSOF Commands](#lsof-commands)             |
| [WGET Commands](#wget-commands) | -                                         | [IPTABLES Commands](#iptables-commands)     |
| [CURL Commands](#curl-commands) | -                                         | [NMCLI Commands](#nmcli-commands)           |
| -                               | -                                         | [NSLOOKUP Commands](#nslookup-commands)     |
| -                               | -                                         | -                                           |

[List of Network Commands](#list-network-commands)

## user-commands

**User Maintainance**

| Command                                                                        | Description                                                                                                                       |
|--------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `sudo useradd username`                                                        | Create a new user with the specified username.                                                                                    |
| `sudo useradd -m -g groupname username`                                        | Create a new user with the specified username and assign them to the specified primary group.                                     |
| `sudo useradd -m -g groupname -G additional_group1,additional_group2 username` | Create a new user with the specified username, assign them to the primary group, and add them to additional supplementary groups. |
| `sudo useradd -r username`                                                     | Create a system user with the specified username.                                                                                 |
| `sudo groupadd groupname`                                                      | Create a new group with the specified groupname.                                                                                  |
| `sudo usermod -aG groupname username`                                          | Add an existing user to a supplementary group.                                                                                    |
| `sudo usermod -l new_username old_username`                                    | Change the username of an existing user.                                                                                          |
| `sudo usermod -g new_primary_group username`                                   | Change the primary group of an existing user.                                                                                     |
| `sudo usermod -G new_supplementary_group1,new_supplementary_group2 username`   | Replace the supplementary groups of an existing user.                                                                             |
| `sudo userdel -r username`                                                     | Delete a user and remove their home directory.                                                                                    |
| `sudo groupdel groupname`                                                      | Delete a group.                                                                                                                   |

## sudo-commands

**SUDO Commands**

| Command                          | Description                                          |
|----------------------------------|------------------------------------------------------|
| `sudo command`                   | Run a command with superuser privileges              |
| `sudo -i`                        | Start a root shell                                   |
| `sudo -u username command`       | Run a command as a specified user                    |
| `sudo visudo`                    | Edit the sudoers file safely                         |
| `sudo -l`                        | List the commands a user can run with sudo           |
| `sudo -S`                        | Read password from standard input                    |
| `sudo -k`                        | Invalidate the sudo timestamp                        |
| `sudo !!`                        | Repeat the last command with sudo                    |
| `sudo apt-get update`            | Update the package database on Debian-based systems  |
| `sudo dnf update`                | Update the package database on Red Hat-based systems |
| `sudo systemctl restart service` | Restart a systemd service with sudo                  |
| `sudo journalctl`                | View system logs with sudo privileges                |
| `sudo nano /path/to/file`        | Edit a file with nano using sudo                     |

## ssh-commands

**SSH Commands**  
Connect to terminal

| Command                                                 | Description                                                                                          |
|---------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `ssh user@remote`                                       | Connect to a remote server using SSH.                                                                |
| `ssh -p 2222 user@remote`                               | Specify a custom SSH port (e.g., 2222) for the connection.                                           |
| `ssh user@remote -i /path/to/private_key.pem`           | Connect using a specific private key for authentication.                                             |
| `ssh -X user@remote`                                    | Enable X11 forwarding, allowing graphical applications on the remote server to be displayed locally. |
| `ssh -L local_port:remote_host:remote_port user@remote` | Set up local port forwarding.                                                                        |
| `ssh -R remote_port:local_host:local_port user@remote`  | Set up remote port forwarding.                                                                       |
| `ssh -D local_socks_port user@remote`                   | Set up dynamic port forwarding (SOCKS proxy).                                                        |
| `ssh -J user1@intermediate user2@target`                | Use a jump host (SSH jump/bastion) to connect to a target host.                                      |
| `ssh-copy-id user@remote`                               | Copy your public key to the remote server's `authorized_keys` file for passwordless login.           |
| `ssh-keygen -t rsa -b 2048`                             | Generate an RSA SSH key pair (public and private key).                                               |
| `ssh-add /path/to/private_key.pem`                      | Add a private key to the SSH agent for authentication.                                               |
| `ssh-agent bash`<br>`ssh-add /path/to/private_key.pem`  | Start an SSH agent and add a private key in one line.                                                |
| `ssh-keyscan remote >> ~/.ssh/known_hosts`              | Add the host key of a remote server to the local `known_hosts` file.                                 |
| `ssh -v user@remote`                                    | Enable verbose mode to show detailed information about the SSH connection.                           |
| `ssh -T git@github.com`                                 | Test an SSH connection to a specific host (e.g., GitHub).                                            |

## curl-commands

**CURL Commands**  http client

| Command                                        | Description                                               |
|------------------------------------------------|-----------------------------------------------------------|
| `curl URL`                                     | Make a simple GET request to a URL                        |
| `curl -O URL`                                  | Download a file and save it with its original name        |
| `curl -o filename URL`                         | Download a file and save it with a specific name          |
| `curl -L URL`                                  | Follow redirects when making a request                    |
| `curl -i URL`                                  | Include the HTTP headers in the output                    |
| `curl -H "Header: Value" URL`                  | Include custom HTTP headers in the request                |
| `curl -X POST -d "data" URL`                   | Send a POST request with data                             |
| `curl -F "key1=value1" -F "key2=value2" URL`   | Send a POST request with form data                        |
| `curl -u username:password URL`                | Perform basic authentication                              |
| `curl --user-agent "UserAgentString" URL`      | Set the user-agent string                                 |
| `curl -b "cookie1=value1; cookie2=value2" URL` | Include cookies in the request                            |
| `curl -c cookies.txt URL`                      | Save cookies to a file after a request                    |
| `curl -x proxyURL:port URL`                    | Use a proxy for the request                               |
| `curl -k URL`                                  | Allow connections to SSL sites without certificates       |
| `curl --head URL`                              | Fetch only the HTTP headers of a URL                      |
| `curl --upload-file file URL`                  | Upload a file using PUT request                           |
| `curl --limit-rate speed URL`                  | Limit the data transfer speed                             |
| `curl -v URL`                                  | Make the operation more talkative and show verbose output |

## wget-commands

**WGET Commands**

| Command                                                | Description                                             |
|--------------------------------------------------------|---------------------------------------------------------|
| `wget URL`                                             | Download a file from the specified URL                  |
| `wget -O filename URL`                                 | Download a file and save it with a specific name        |
| `wget -P /path/to/directory URL`                       | Download a file and save it to a specific directory     |
| `wget -c URL`                                          | Continue an interrupted download                        |
| `wget --limit-rate=amount URL`                         | Limit the download speed                                |
| `wget -r URL`                                          | Download a URL recursively                              |
| `wget -N URL`                                          | Download a file only if it is newer than the local copy |
| `wget --no-clobber URL`                                | Avoid overwriting files that already exist              |
| `wget --convert-links URL`                             | Convert links to make them suitable for local viewing   |
| `wget --mirror URL`                                    | Create an offline copy of a website                     |
| `wget --spider URL`                                    | Check if a URL exists without downloading it            |
| `wget --header="Header: Value" URL`                    | Include custom headers in the request                   |
| `wget --user=username --password=password URL`         | Perform HTTP authentication                             |
| `wget --ftp-user=username --ftp-password=password URL` | Perform FTP authentication                              |
| `wget --no-check-certificate URL`                      | Disable certificate checking for HTTPS                  |
| `wget --quiet URL`                                     | Suppress output except for errors                       |
| `wget --show-progress URL`                             | Display a progress bar during download                  |
| `wget --help`                                          | Display help information about wget                     |

## grep-commands

**GREP Commands**

| Command                                   | Description                                                  |
|-------------------------------------------|--------------------------------------------------------------|
| `grep pattern file`                       | Search for a pattern in a file                               |
| `grep -r pattern directory`               | Recursively search for a pattern in a directory              |
| `grep -i pattern file`                    | Perform a case-insensitive search                            |
| `grep -v pattern file`                    | Invert match, display lines not containing the pattern       |
| `grep -n pattern file`                    | Display line numbers along with matching lines               |
| `grep -l pattern files`                   | Display only the names of files containing the pattern       |
| `grep -c pattern file`                    | Display the count of lines containing the pattern            |
| `grep -e pattern1 -e pattern2 file`       | Search for multiple patterns in a file                       |
| `grep -E 'pattern1 (pipe) pattern2' file` | Use extended regular expressions for multiple patterns       |
| `grep -w word file`                       | Search for whole words only                                  |
| `grep -A num pattern file`                | Display num lines after each matching line                   |
| `grep -B num pattern file`                | Display num lines before each matching line                  |
| `grep -C num pattern file`                | Display num lines before and after each matching line        |
| `grep -o pattern file`                    | Display only the matched part of the line                    |
| `grep -r -l pattern directory`            | List files containing the pattern in a directory recursively |
| `grep --color=auto pattern file`          | Highlight the matching text in color                         |
| `grep -f pattern_file file`               | Read patterns from a file and search in another file         |
| `grep -q pattern file`                    | Quiet mode, return 0 if the pattern is found, 1 otherwise    |
| `zgrep pattern file.gz`                   | Search for a pattern in a compressed (gzip) file             |

## awk-commands

**AWK Commands**

| Command                                                                                   | Description                                                                          |
|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `awk '{print $1}' file`                                                                   | Print the first column of each line in a file                                        |
| `awk '{print $1, $2}' file`                                                               | Print the first and second columns of each line in a file                            |
| `awk '/pattern/' file`                                                                    | Print lines matching a specific pattern in a file                                    |
| `awk '!/pattern/' file`                                                                   | Print lines not matching a specific pattern in a file                                |
| `awk '/pattern/ {print $2}' file`                                                         | Print the second column of lines matching a pattern                                  |
| `awk '{print NF}' file`                                                                   | Print the number of fields in each line of a file                                    |
| `awk '{sum += $1} END {print sum}' file`                                                  | Calculate and print the sum of values in the first column                            |
| `awk '{if ($3 > 10) print $1, $2}' file`                                                  | Print the first and second columns if the third column is greater than 10            |
| `awk -F: '{print $1}' /etc/passwd`                                                        | Specify a field separator (colon in this case)                                       |
| `awk '{gsub(/old/, "new"); print}' file`                                                  | Replace occurrences of "old" with "new" in each line                                 |
| `awk '{if (length($0) > max) {max = length($0); maxline = $0}} END {print maxline}' file` | Find the longest line in a file                                                      |
| `awk '{arr[$1]++} END {for (i in arr) print i, arr[i]}' file`                             | Count occurrences of values in the first column                                      |
| `ps aux  (pipe) awk '$3 > 50 {print $1, $3}'`                                             | Use with other commands, print user and CPU usage if CPU usage is greater than 50%   |
| `ls -l (pipe) awk '{total += $5} END {print "Total file size: " total}'`                  | Calculate and print the total size of files in the current directory                 |
| `awk '/pattern/ {print FILENAME ":" FNR, $0}' files*`                                     | Print filename, line number, and line for lines matching a pattern in multiple files |

## sed-commands

**SED Commands**

| Command                                            | Description                                                                   |
|----------------------------------------------------|-------------------------------------------------------------------------------|
| `sed 's/old/new/' file`                            | Replace the first occurrence of "old" with "new" in each line of a file       |
| `sed 's/old/new/g' file`                           | Replace all occurrences of "old" with "new" in each line of a file            |
| `sed '2s/old/new/' file`                           | Replace the first occurrence of "old" with "new" in the second line of a file |
| `sed '1,3s/old/new/' file`                         | Replace the first occurrence of "old" with "new" in lines 1 to 3              |
| `sed -i 's/old/new/' file`                         | Edit the file in-place, replacing the first occurrence of "old" with "new"    |
| `sed -i 's/old/new/g' file`                        | Edit the file in-place, replacing all occurrences of "old" with "new"         |
| `sed '/pattern/d' file`                            | Delete lines containing a specific pattern                                    |
| `sed '2d' file`                                    | Delete the second line of a file                                              |
| `sed '1,3d' file`                                  | Delete lines 1 to 3 from a file                                               |
| `sed '/^$/d' file`                                 | Delete blank lines from a file                                                |
| `sed 's/\s//g' file`                               | Remove all whitespace from each line of a file                                |
| `sed -n '/pattern/p' file`                         | Print only lines containing a specific pattern                                |
| `sed -n '1,5p' file`                               | Print lines 1 to 5 from a file                                                |
| `sed 's/^/prefix/' file`                           | Add a prefix to the beginning of each line                                    |
| `sed 's/$/suffix/' file`                           | Add a suffix to the end of each line                                          |
| `sed -e 's/old/new/' -e 's/another/replace/' file` | Execute multiple sed commands on a file                                       |
| `sed '/pattern/!b; s//new_pattern/' file`          | If a line contains a pattern, replace the pattern with a new one              |
| `sed '1i\ New line at the beginning' file`         | Insert a new line at the beginning of the file                                |
| `sed '$a\ New line at the end' file`               | Insert a new line at the end of the file                                      |

## ps-commands

**PS Commands**

| Command                                 | Description                                                              |
|-----------------------------------------|--------------------------------------------------------------------------|
| `ps`                                    | Display information about the current processes                          |
| `ps aux`                                | Display detailed information about all processes                         |
| `ps -ef`                                | Display a full listing of processes                                      |
| `ps aux --sort=-%cpu`                   | Display processes sorted by CPU usage (descending)                       |
| `ps aux --sort=-%mem`                   | Display processes sorted by memory usage (descending)                    |
| `ps -u username`                        | Display processes for a specific user                                    |
| `ps -p pid`                             | Display information about a specific process ID (PID)                    |
| `ps -e --forest`                        | Display processes in a tree-like format                                  |
| `ps -e (pipe) grep process_name`        | Display processes matching a specific name                               |
| `ps -eF`                                | Display full-format listing of processes                                 |
| `ps -ejH`                               | Display a process hierarchy (forest) with additional information         |
| `ps -o pid,ppid,cmd,%cpu,%mem`          | Customize output to display specific information                         |
| `ps -o user,pid,%cpu,%mem,cmd`          | Display user, PID, CPU and memory usage, and command                     |
| `ps -e --format pid,ppid,%cpu,%mem,cmd` | Specify the output format using --format                                 |
| `ps -C process_name`                    | Display detailed information about processes with a specific name        |
| `ps -eo pid,comm,etime`                 | Display process ID, command, and elapsed time                            |
| `ps --no-headers`                       | Display output without headers                                           |
| `ps -e --sort=start_time`               | Display processes sorted by start time                                   |
| `ps -A -o user,group,%cpu,%mem,comm`    | Display user, group, CPU and memory usage, and command for all processes |

## top-commands

**TOP Commands**

| Command                            | Description                                                               |
|------------------------------------|---------------------------------------------------------------------------|
| `top`                              | Display a dynamic view of system processes and resource usage             |
| `top -u username`                  | Display processes for a specific user                                     |
| `top -p pid`                       | Display information for a specific process ID (PID)                       |
| `top -d seconds`                   | Set the delay between updates in seconds                                  |
| `top -n iterations`                | Run for a specified number of iterations and then exit                    |
| `top -H`                           | Display individual threads in the process list                            |
| `top -i`                           | Don't show idle or zombie processes                                       |
| `top -c`                           | Display the command full path and command line options                    |
| `top -b`                           | Run in batch mode, suitable for sending output to other programs or files |
| `top -o field`                     | Sort the process list by a specific field (e.g., %CPU, %MEM)              |
| `top -s delay`                     | Set the delay between updates in seconds interactively                    |
| `top -u username -p pid`           | Display processes for a specific user and process ID                      |
| `top -E g`                         | Display processes in a forest (grouped by process group)                  |
| `top -i -n 1 -b > output.txt`      | Run a single iteration in batch mode and save the output to a file        |
| `top -p $(pgrep process_name)`     | Display information for all processes matching a specific name            |
| `top -p $(pgrep -d',' -f pattern)` | Display information for all processes matching a specific pattern         |
| `top -w`                           | Display wide output, showing more information for each process            |
| `top -l`                           | Display the average load over the last 1, 5, and 15 minutes               |
| `top -G`                           | Show processes belonging to the same thread group                         |
| `top -U username`                  | Display processes for a specific effective user ID (EUID)                 |

## tar-commands

**TAR Commands**  File Compress

| Command                                              | Description                                                                        |
|------------------------------------------------------|------------------------------------------------------------------------------------|
| `tar -cvf archive.tar file1 file2`                   | Create a new tar archive named archive.tar containing file1 and file2.             |
| `tar -xvf archive.tar`                               | Extract the contents of the archive.tar file.                                      |
| `tar -cvzf archive.tar.gz directory/`                | Create a compressed tar archive named archive.tar.gz of the specified directory.   |
| `tar -xvzf archive.tar.gz`                           | Extract the contents of the compressed archive.tar.gz file.                        |
| `tar -tvf archive.tar`                               | Display the contents of the archive.tar file without extracting.                   |
| `tar -rvf archive.tar newfile`                       | Add newfile to an existing tar archive named archive.tar.                          |
| `tar -uvf archive.tar existingfile`                  | Update an existing tar archive named archive.tar with changes to an existing file. |
| `tar --exclude=pattern -cvf archive.tar *`           | Create a tar archive excluding files that match the specified pattern.             |
| `tar -cvf - directory/ (pipe) gzip > archive.tar.gz` | Create a tar archive and compress it on the fly using gzip.                        |
| `tar --list -f archive.tar`                          | List the contents of a tar archive without extracting.                             |

## scp-commands

**SCP Commands**  Copy files between servers

| Command                                                       | Description                                                             |
|---------------------------------------------------------------|-------------------------------------------------------------------------|
| `scp file.txt user@remote:/path/`                             | Copy a local file to a remote server.                                   |
| `scp user@remote:/path/file.txt /local/path/`                 | Copy a file from a remote server to the local machine.                  |
| `scp -r directory/ user@remote:/path/`                        | Recursively copy a local directory to a remote server.                  |
| `scp -r user@remote:/path/directory/ /local/path/`            | Recursively copy a directory from a remote server to the local machine. |
| `scp user1@remote1:/path/file.txt user2@remote2:/path/`       | Copy a file directly between two remote servers.                        |
| `scp -P 2222 file.txt user@remote:/path/`                     | Specify a custom SSH port (e.g., 2222) for the SCP connection.          |
| `scp user@remote:"/path/file with spaces.txt" /local/path/`   | Copy a file with spaces in the filename from a remote server.           |
| `scp -i /path/to/private_key.pem file.txt user@remote:/path/` | Use a specific private key for authentication.                          |
| `scp -v file.txt user@remote:/path/`                          | Enable verbose mode to show detailed information about the SCP process. |
| `scp -B file.txt user@remote:/path/`                          | Run SCP in the background (batch mode).                                 |

scp -r user@source_server:/path/to/source/ user@destination_server:/path/to/destination/

<<<<<<< HEAD

## ln-commands

**LN Commands**

| Command                                      | Description                                                                 |
|----------------------------------------------|-----------------------------------------------------------------------------|
| `ln source_file link_name`                   | Create a hard link to a file                                                |
| `ln -s source_file symbolic_link`            | Create a symbolic (soft) link to a file                                     |
| `ln source_directory link_name`              | Create a hard link to a directory (generally not recommended)               |
| `ln -s source_directory symbolic_link`       | Create a symbolic link to a directory                                       |
| `ln -b source_file link_name`                | Create a backup of the existing target file before creating a hard link     |
| `ln -s -b source_file symbolic_link`         | Create a backup of the existing target file before creating a symbolic link |
| `ln -i source_file link_name`                | Prompt before overwriting an existing target file with a hard link          |
| `ln -s -i source_file symbolic_link`         | Prompt before overwriting an existing target file with a symbolic link      |
| `ln -r source_directory link_name`           | Create symbolic links relative to the link location                         |
| `ln -T source target`                        | Treat the target as a normal file even if it is a directory                 |
| `ln --help`                                  | Display help information about the `ln` command                             |
| `ln --version`                               | Display version information for the `ln` command                            |
| `ln -v source_file link_name`                | Be verbose, display the link created                                        |
| `ln -s -f source_file symbolic_link`         | Force creation of a symbolic link, overwriting the target if it exists      |
| `ln -P source_file link_name`                | Do not dereference symbolic links when creating hard links                  |
| `ln -L source_file link_name`                | Dereference symbolic links when creating hard links                         |
| `ln -n source_file link_name`                | No-dereference, treat source_file as a normal file if it is a symbolic link |
| `ln --relative -s source_file symbolic_link` | Create symbolic link relative to the symlink location                       |

=======
> > > > > > > develop

## du-commands

**DU Commands**

| Command                     | Description                                                              |
|-----------------------------|--------------------------------------------------------------------------|
| `du`                        | Display disk usage for the current directory and its subdirectories      |
| `du -h`                     | Display disk usage in a human-readable format (e.g., KB, MB, GB)         |
| `du -s`                     | Display only the total disk usage for the current directory              |
| `du -c`                     | Display a grand total of disk usage at the end of the output             |
| `du -k`                     | Display disk usage in kilobytes                                          |
| `du -m`                     | Display disk usage in megabytes                                          |
| `du -g`                     | Display disk usage in gigabytes                                          |
| `du -d depth`               | Limit the depth of the directory tree to be displayed                    |
| `du --max-depth=depth`      | Same as `-d` option, specifying the depth of the directory tree          |
| `du -a`                     | Display disk usage for individual files as well as directories           |
| `du -h --max-depth=1`       | Display the total disk usage of each immediate subdirectory              |
| `du -csh`                   | Display a summary total of disk usage in a human-readable format         |
| `du -k --max-depth=1        | sort -n`                                                                 | Display disk usage of each immediate subdirectory and sort by size |
| `du -h --exclude=pattern`   | Exclude directories or files matching a specific pattern from the output |
| `du -h --exclude-from=file` | Exclude directories or files listed in a file from the output            |
| `du -B unit`                | Set the block size (unit) for disk usage calculation                     |
| `du --apparent-size`        | Display the apparent size of files rather than disk usage                |
| `du -L`                     | Follow symbolic links and display disk usage of the linked files         |
| `du --time`                 | Display the last modification time of the file or directory              |
| `du -x`                     | Stay on the same file system and do not cross mount points               |
| `du --help`                 | Display help information about `du` command                              |

## df-commands

**DF Commands**

| Command                                           | Description                                                            |
|---------------------------------------------------|------------------------------------------------------------------------|
| `df`                                              | Display disk space usage for all mounted filesystems                   |
| `df -h`                                           | Display disk space usage in a human-readable format (e.g., KB, MB, GB) |
| `df -T`                                           | Display filesystem type along with disk space usage                    |
| `df -a`                                           | Include pseudo, duplicate, inaccessible filesystems in the output      |
| `df -i`                                           | Display inode information along with disk space usage                  |
| `df -k`                                           | Display disk space usage in kilobytes                                  |
| `df -m`                                           | Display disk space usage in megabytes                                  |
| `df -g`                                           | Display disk space usage in gigabytes                                  |
| `df -P`                                           | Use the POSIX output format                                            |
| `df --output=source,target,size,used,avail,pcent` | Specify the columns to be displayed in the output                      |
| `df -x filesystem_type`                           | Exclude specific filesystem types from the output                      |
| `df --sync`                                       | Invoke the `sync` system call before getting disk usage                |
| `df --help`                                       | Display help information about the `df` command                        |
| `df -l`                                           | Only display information about locally mounted filesystems             |
| `df --total`                                      | Display a total line at the end of the output                          |
| `df --exclude=filesystem`                         | Exclude specific filesystems from the output                           |
| `df --exclude-type=filesystem_type`               | Exclude specific filesystem types from the output                      |
| `df --human-readable`                             | Display sizes in human-readable format                                 |
| `df --si`                                         | Use powers of 1000 instead of 1024 for human-readable output           |
| `df -B blocksize`                                 | Set the block size for disk space calculation                          |
| `df --version`                                    | Display version information for `df` command                           |
| `df -T --output=source,fstype`                    | Display only filesystem sources and types                              |

## ping-commands

**PING Commands**

| Command                           | Description                                                              |
|-----------------------------------|--------------------------------------------------------------------------|
| `ping hostname`                   | Send ICMP Echo Request to a hostname.                                    |
| `ping IP_address`                 | Send ICMP Echo Request to an IP address.                                 |
| `ping -c count hostname`          | Specify the number of ICMP Echo Requests to send.                        |
| `ping -s packet_size hostname`    | Set the size of the ICMP Echo Request packets.                           |
| `ping -i interval hostname`       | Set the interval between ICMP Echo Requests in seconds.                  |
| `ping -t ttl_value hostname`      | Set the Time-to-Live (TTL) value for the ICMP Echo Request packets.      |
| `ping -W timeout hostname`        | Set the timeout for waiting for a response in seconds.                   |
| `ping -q hostname`                | Run in quiet mode, only displaying summary statistics.                   |
| `ping -R hostname`                | Record route. Display the route of the ICMP Echo Request.                |
| `ping -A hostname`                | Display the autonomous system number (AS number) for the destination.    |
| `ping -n hostname`                | Numeric output only. Do not resolve hostnames.                           |
| `ping -4 hostname`                | Use IPv4 only.                                                           |
| `ping -6 hostname`                | Use IPv6 only.                                                           |
| `ping -v hostname`                | Verbose output. Display detailed information about each ICMP Echo Reply. |
| `ping -b broadcast_address`       | Ping the broadcast address on the local network.                         |
| `ping -f hostname`                | Flood ping. Send ICMP Echo Requests as fast as possible.                 |
| `ping -I interface_name hostname` | Use a specific network interface for sending ICMP Echo Requests.         |
| `ping -r hop_count hostname`      | Set the number of hops to discover the route to the destination.         |
| `ping -l preload hostname`        | Send a specified number of packets in the preload phase.                 |
| `ping -U username hostname`       | Set the username to include in the ping packet.                          |

## tcpdump-commands

**TCPDUMP Commands**

| Command                      | Description                                                        |
|------------------------------|--------------------------------------------------------------------|
| `tcpdump`                    | Capture and display packets on a network interface                 |
| `tcpdump -i interface`       | Specify the network interface to capture packets                   |
| `tcpdump -n`                 | Display IP addresses and ports numerically                         |
| `tcpdump -nn`                | Display IP addresses and ports numerically without resolving names |
| `tcpdump -c count`           | Capture a specific number of packets and then exit                 |
| `tcpdump -s snaplen`         | Set the snapshot length (captured portion) of each packet          |
| `tcpdump -X`                 | Display packet data in both hex and ASCII                          |
| `tcpdump -vvv`               | Increase verbosity level for more detailed output                  |
| `tcpdump -w filename`        | Write captured packets to a file for later analysis                |
| `tcpdump -r filename`        | Read packets from a saved capture file                             |
| `tcpdump -A`                 | Print each packet's payload in ASCII                               |
| `tcpdump -e`                 | Display the link-layer header in addition to packet data           |
| `tcpdump -q`                 | Be less verbose (quiet mode)                                       |
| `tcpdump -l`                 | Make output line-buffered                                          |
| `tcpdump -r file -w newfile` | Read packets from one file and write them to another               |
| `tcpdump host ip_address`    | Capture packets involving a specific IP address                    |
| `tcpdump port port_number`   | Capture packets for a specific port number                         |
| `tcpdump -i any`             | Capture packets on all interfaces                                  |
| `tcpdump -X 'expression'`    | Apply a display filter expression to captured packets              |

## netstat-commands

**NETSTAT Commands**

| Command            | Description                                                                                            |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `netstat -a`       | Display all listening and non-listening sockets.                                                       |
| `netstat -t`       | Display TCP connections.                                                                               |
| `netstat -u`       | Display UDP connections.                                                                               |
| `netstat -l`       | Display listening sockets.                                                                             |
| `netstat -p`       | Display the process ID and program name along with network connections.                                |
| `netstat -n`       | Show numerical addresses instead of resolving hosts and ports.                                         |
| `netstat -r`       | Display the kernel routing table.                                                                      |
| `netstat -s`       | Display statistics for various network protocols.                                                      |
| `netstat -i`       | Display information about network interfaces.                                                          |
| `netstat -c`       | Continuously display the selected information until interrupted.                                       |
| `netstat -punta`   | Display all listening and non-listening sockets, including the program and process using them (Linux). |
| `netstat -an`      | Display numerical addresses and port numbers without resolving them.                                   |
| `netstat -g`       | Display multicast group memberships.                                                                   |
| `netstat -h`       | Display help information for netstat options.                                                          |
| `netstat -f inet`  | Display only IPv4-related information.                                                                 |
| `netstat -f inet6` | Display only IPv6-related information.                                                                 |
| `netstat -W`       | Display wide output without truncating addresses.                                                      |
| `netstat -o`       | Display timer information for TCP connections.                                                         |
| `netstat -A`       | Show the state of all network interfaces.                                                              |
| `netstat -L`       | Display information about kernel resource usage (Linux).                                               |

## ifconfig-commands

**IFCONFIG Commands**

| Command                                    | Description                                                                                    |
|--------------------------------------------|------------------------------------------------------------------------------------------------|
| `ifconfig`                                 | Display information about all network interfaces.                                              |
| `ifconfig eth0`                            | Display information about a specific network interface (e.g., eth0).                           |
| `ifconfig eth0 up`                         | Bring a network interface up.                                                                  |
| `ifconfig eth0 down`                       | Bring a network interface down.                                                                |
| `ifconfig eth0 192.168.1.2`                | Assign a specific IP address to a network interface.                                           |
| `ifconfig eth0 netmask 255.255.255.0`      | Set the netmask for a network interface.                                                       |
| `ifconfig eth0 broadcast 192.168.1.255`    | Set the broadcast address for a network interface.                                             |
| `ifconfig eth0 mtu 1500`                   | Set the Maximum Transmission Unit (MTU) for a network interface.                               |
| `ifconfig eth0 hw ether 00:11:22:33:44:55` | Set the hardware (MAC) address for a network interface.                                        |
| `ifconfig -a`                              | Display information about all network interfaces, including those that are currently inactive. |
| `ifconfig -s`                              | Display a short summary of all network interfaces.                                             |
| `ifconfig -a`                              | grep "inet"  Display only IP addresses of all active network interfaces.                       |
| `ifconfig eth0:1 192.168.1.3`              | Create a virtual (alias) interface (e.g., eth0:1) with a specific IP address.                  |
| `ifconfig eth0 promisc`                    | Enable promiscuous mode on a network interface.                                                |
| `ifconfig eth0 -promisc`                   | Disable promiscuous mode on a network interface.                                               |

## ip-commands

**IP Commands**

| Command                                                            | Description                                                          |
|--------------------------------------------------------------------|----------------------------------------------------------------------|
| `ip addr show`                                                     | Display information about all network interfaces.                    |
| `ip addr show dev eth0`                                            | Display information about a specific network interface (e.g., eth0). |
| `ip link set eth0 up`                                              | Bring a network interface up.                                        |
| `ip link set eth0 down`                                            | Bring a network interface down.                                      |
| `ip addr add 192.168.1.2/24 dev eth0`                              | Assign a specific IP address to a network interface.                 |
| `ip addr del 192.168.1.2/24 dev eth0`                              | Remove a specific IP address from a network interface.               |
| `ip route show`                                                    | Display the IP routing table.                                        |
| `ip route add default via 192.168.1.1`                             | Add a default gateway to the routing table.                          |
| `ip route add 192.168.2.0/24 via 192.168.1.1`                      | Add a specific route to the routing table.                           |
| `ip route del 192.168.2.0/24`                                      | Remove a specific route from the routing table.                      |
| `ip neigh show`                                                    | Display the ARP (Address Resolution Protocol) table.                 |
| `ip neigh add 192.168.1.2 lladdr 00:11:22:33:44:55 dev eth0`       | Add a static ARP entry to the table.                                 |
| `ip neigh del 192.168.1.2 dev eth0`                                | Remove a specific ARP entry from the table.                          |
| `ip link show`                                                     | Display information about network interfaces and their status.       |
| `ip link set eth0 mtu 1500`                                        | Set the Maximum Transmission Unit (MTU) for a network interface.     |
| `ip link set eth0 address 00:11:22:33:44:55`                       | Set the hardware (MAC) address for a network interface.              |
| `ip -s link show eth0`                                             | Display detailed statistics for a network interface.                 |
| `ip tunnel add tun0 mode gre remote 203.0.113.1 local 203.0.113.2` | Create a GRE (Generic Routing Encapsulation) tunnel.                 |
| `ip tunnel del tun0`                                               | Delete a GRE tunnel.                                                 |
| `ip -6 addr show`                                                  | Display IPv6 addresses for network interfaces.                       |
| `ip -6 route show`                                                 | Display the IPv6 routing table.                                      |

## route-commands

**ROUTE Commands**

| Command                                                           | Description                                                            |
|-------------------------------------------------------------------|------------------------------------------------------------------------|
| `route`                                                           | Display the IP routing table.                                          |
| `route -n`                                                        | Display the IP routing table with numerical addresses.                 |
| `route add default gw 192.168.1.1`                                | Add a default gateway to the routing table.                            |
| `route add -net 192.168.2.0 netmask 255.255.255.0 gw 192.168.1.1` | Add a specific route to the routing table.                             |
| `route del default`                                               | Remove the default gateway from the routing table.                     |
| `route del -net 192.168.2.0 netmask 255.255.255.0`                | Remove a specific route from the routing table.                        |
| `route -A inet6`                                                  | Display the IPv6 routing table.                                        |
| `route -6 add default gw 2001:db8::1`                             | Add a default IPv6 gateway.                                            |
| `route -6 add 2001:db8:2::/64 gw 2001:db8::1`                     | Add a specific IPv6 route.                                             |
| `route -6 del default gw 2001:db8::1`                             | Remove the default IPv6 gateway.                                       |
| `route -6 del 2001:db8:2::/64 gw 2001:db8::1`                     | Remove a specific IPv6 route.                                          |
| `ip route`                                                        | Display the IP routing table using the `ip` command.                   |
| `ip route show`                                                   | Display detailed information about routes using the `ip` command.      |
| `ip route add 192.168.3.0/24 via 192.168.1.1 dev eth0`            | Add a specific route using the `ip` command.                           |
| `ip route del 192.168.3.0/24`                                     | Remove a specific route using the `ip` command.                        |
| `ip -6 route`                                                     | Display the IPv6 routing table using the `ip` command.                 |
| `ip -6 route show`                                                | Display detailed information about IPv6 routes using the `ip` command. |
| `ip -6 route add 2001:db8:3::/64 via 2001:db8::1 dev eth0`        | Add a specific IPv6 route using the `ip` command.                      |
| `ip -6 route del 2001:db8:3::/64`                                 | Remove a specific IPv6 route using the `ip` command.                   |

## traceroute-commands

**TRACEROUTE Commands**

| Command                               | Description                                                   |
|---------------------------------------|---------------------------------------------------------------|
| `traceroute example.com`              | Trace the route that packets take to reach a destination.     |
| `traceroute -n example.com`           | Trace the route without resolving hostnames.                  |
| `traceroute -4 example.com`           | Force the use of IPv4.                                        |
| `traceroute -6 example.com`           | Force the use of IPv6.                                        |
| `traceroute -m 15 example.com`        | Set the maximum number of hops to 15.                         |
| `traceroute -p 80 example.com`        | Use a specific destination port (e.g., port 80).              |
| `traceroute -q 3 example.com`         | Set the number of queries per hop to 3.                       |
| `traceroute -w 2 example.com`         | Set the timeout for each query to 2 seconds.                  |
| `traceroute -I example.com`           | Use ICMP Echo Requests instead of UDP packets.                |
| `traceroute -T example.com`           | Use TCP SYN packets instead of UDP packets.                   |
| `traceroute -U example.com`           | Use UDP packets.                                              |
| `traceroute -z 2 example.com`         | Set the time delay between probes to 2 seconds.               |
| `traceroute -f 3 example.com`         | Set the initial TTL (Time-To-Live) to 3.                      |
| `traceroute -l example.com`           | Print the host and network addresses in numerical form.       |
| `traceroute -r example.com`           | Bypass the normal routing tables and send directly to a host. |
| `traceroute -s source_ip example.com` | Use a specific source IP address.                             |
| `traceroute -V example.com`           | Print the version number of `traceroute`.                     |
| `traceroute -h`                       | Display help information for `traceroute`.                    |

## arp-commands

**ARP Commands**

| Command                                                      | Description                                                                             |
|--------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `arp`                                                        | Display the ARP (Address Resolution Protocol) cache.                                    |
| `arp -a`                                                     | Display the ARP cache in a more detailed format.                                        |
| `arp -n`                                                     | Display the ARP cache with numerical addresses.                                         |
| `arp -d 192.168.1.2`                                         | Delete a specific entry from the ARP cache.                                             |
| `arp -s 192.168.1.2 00:11:22:33:44:55`                       | Add a static ARP entry to the cache.                                                    |
| `arp -i eth0`                                                | Display the ARP cache for a specific network interface.                                 |
| `arp -e`                                                     | Display the ARP cache with vendor OUI (Organizationally Unique Identifier) information. |
| `ip neigh show`                                              | Display ARP entries using the `ip` command.                                             |
| `ip neigh add 192.168.1.2 lladdr 00:11:22:33:44:55 dev eth0` | Add a static ARP entry using the `ip` command.                                          |
| `ip neigh del 192.168.1.2 dev eth0`                          | Delete a specific ARP entry using the `ip` command.                                     |

## iwconfig-commands

**IWCONFIG Commands**

| Command                                            | Description                                                               |
|----------------------------------------------------|---------------------------------------------------------------------------|
| `iwconfig`                                         | Display wireless interface configuration.                                 |
| `iwconfig wlan0`                                   | Display configuration for a specific wireless interface (e.g., wlan0).    |
| `iwconfig wlan0 essid "Your_SSID"`                 | Set the ESSID (Extended Service Set Identifier) for a wireless interface. |
| `iwconfig wlan0 mode Managed`                      | Set the operating mode to Managed for a wireless interface.               |
| `iwconfig wlan0 channel 6`                         | Set the channel for a wireless interface.                                 |
| `iwconfig wlan0 key s:Your_WiFi_Password`          | Set the WEP or WPA key for a wireless interface.                          |
| `iwconfig wlan0 key open Your_WiFi_Password`       | Set an open key for a wireless interface.                                 |
| `iwconfig wlan0 key restricted Your_WiFi_Password` | Set a restricted key for a wireless interface.                            |
| `iwconfig wlan0 rate 54M`                          | Set the transmission rate for a wireless interface.                       |
| `iwconfig wlan0 power off`                         | Turn off power management for a wireless interface.                       |
| `iwconfig wlan0 txpower 20dBm`                     | Set the transmission power for a wireless interface.                      |
| `iwconfig wlan0 ap 00:11:22:33:44:55`              | Set the access point MAC address for a wireless interface.                |
| `iwconfig wlan0 ap any`                            | Connect to any available access point.                                    |
| `iwconfig wlan0 nickname "My_Nickname"`            | Set a nickname for a wireless interface.                                  |
| `iwconfig wlan0 retry 10`                          | Set the maximum number of retries for a wireless interface.               |
| `iwconfig wlan0 frag 2346`                         | Set the fragment size for a wireless interface.                           |
| `iwconfig wlan0 rts 2346`                          | Set the RTS/CTS threshold for a wireless interface.                       |
| `iwconfig wlan0 key off`                           | Turn off encryption for a wireless interface.                             |
| `iwconfig wlan0 enc s:Your_WEP_Key`                | Set the WEP encryption key for a wireless interface.                      |
| `iwconfig wlan0 mode Ad-Hoc`                       | Set the operating mode to Ad-Hoc for a wireless interface.                |

## hostname-commands

**HOSTNAME Commands**

| Command                                             | Description                                                                             |
|-----------------------------------------------------|-----------------------------------------------------------------------------------------|
| `hostname`                                          | Display the current hostname of the system.                                             |
| `hostname -I`                                       | Display the IP addresses associated with the current hostname.                          |
| `hostname -f`                                       | Display the fully qualified domain name (FQDN) of the system.                           |
| `hostnamectl`                                       | Display information about the system's hostname and related settings.                   |
| `hostnamectl set-hostname new-hostname`             | Set the system's hostname to a new value (requires sudo).                               |
| `echo "new-hostname" (pipe) sudo tee /etc/hostname` | Set the hostname by editing the `/etc/hostname` file (requires sudo).                   |
| `sudo sysctl kernel.hostname=new-hostname`          | Change the hostname using sysctl (requires sudo).                                       |
| `dnsdomainname`                                     | Display the DNS domain name of the system.                                              |
| `domainname`                                        | Display or set the NIS/YP domain name of the system.                                    |
| `nmtui`                                             | Open a text-based user interface for managing network settings, including the hostname. |

## dig-commands

**DIG Commands**

| Command                              | Description                                               |
|--------------------------------------|-----------------------------------------------------------|
| `dig example.com`                    | Perform a basic DNS query for the specified domain.       |
| `dig +short example.com`             | Display only the IP addresses associated with the domain. |
| `dig -t mx example.com`              | Query the mail exchange (MX) records for the domain.      |
| `dig -t cname www.example.com`       | Query the canonical name (CNAME) record for a subdomain.  |
| `dig -t txt example.com`             | Query the text (TXT) records for the domain.              |
| `dig -t aaaa example.com`            | Query IPv6 address (AAAA) records for the domain.         |
| `dig -t ns example.com`              | Query the name server (NS) records for the domain.        |
| `dig +short -x 8.8.8.8`              | Reverse DNS lookup for an IP address.                     |
| `dig @8.8.8.8 example.com`           | Query a specific DNS server for the domain.               |
| `dig +trace example.com`             | Perform a trace of DNS delegations for the domain.        |
| `dig +noquestion example.com`        | Display only the answer section of the DNS response.      |
| `dig +stats`                         | Display statistics after completing the query.            |
| `dig +tcp example.com`               | Use TCP instead of UDP for the DNS query.                 |
| `dig +notcp example.com`             | Use UDP instead of TCP for the DNS query.                 |
| `dig +short +additional example.com` | Display additional information in a short format.         |
| `dig +short +question example.com`   | Display only the question section of the DNS response.    |
| `dig +noauthority example.com`       | Do not display the authority section of the DNS response. |
| `dig +noanswer example.com`          | Do not display the answer section of the DNS response.    |
| `dig +qr example.com`                | Query with the QR (query response) flag set.              |
| `dig +aa example.com`                | Query with the AA (authoritative answer) flag set.        |

## ss-commands

**SS Commands**

| Command | Description                                       |
|---------|---------------------------------------------------|
| `ss -l` | Display listening sockets                         |
| `ss -a` | Display all sockets (listening and non-listening) |
| `ss -t` | Display TCP sockets                               |
| `ss -u` | Display UDP sockets                               |
| `ss -s` | Display summary statistics                        |
| `ss -p` | Display process using socket                      |
| `ss -n` | Show numerical addresses                          |
| `ss -r` | Display routing information                       |
| `ss -h` | Display help message                              |
| `ss -V` | Display version information                       |

## lsof-commands

**LSOF Commands**

| Command                   | Description                                       |
|---------------------------|---------------------------------------------------|
| `lsof`                    | List all open files and processes                 |
| `lsof -i`                 | List all network connections                      |
| `lsof -i :port`           | List processes using a specific port              |
| `lsof -i tcp`             | List TCP connections                              |
| `lsof -i udp`             | List UDP connections                              |
| `lsof -u username`        | List processes for a specific user                |
| `lsof -c process_name`    | List open files for a specific process            |
| `lsof -p pid`             | List open files for a specific process ID (PID)   |
| `lsof -i -sTCP:LISTEN`    | List processes that are listening on TCP ports    |
| `lsof -i -sUDP:LISTEN`    | List processes that are listening on UDP ports    |
| `lsof -i @ip_address`     | List processes connected to a specific IP address |
| `lsof -d file_descriptor` | List processes using a specific file descriptor   |

## iptables-commands

**IPTABLES Commands**

| Command                                                  | Description                                                       |
|----------------------------------------------------------|-------------------------------------------------------------------|
| `iptables -L`                                            | List all rules in all chains                                      |
| `iptables -L -n`                                         | List rules with numeric IP addresses and port numbers             |
| `iptables -A chain`                                      | Append a rule to the end of a chain                               |
| `iptables -I chain rule`                                 | Insert a rule at the beginning of a chain                         |
| `iptables -D chain rule`                                 | Delete a rule from a chain                                        |
| `iptables -P chain target`                               | Set the default policy on a chain                                 |
| `iptables -F`                                            | Flush all rules (delete all rules)                                |
| `iptables -t table -A chain`                             | Append a rule to a specific table and chain                       |
| `iptables -s source -j DROP`                             | Drop all packets from a specific source                           |
| `iptables -A INPUT -p protocol --dport port -j ACCEPT`   | Allow incoming traffic to a specific port                         |
| `iptables -A FORWARD -s source -d destination -j ACCEPT` | Allow forwarding from a specific source to a specific destination |
| `iptables -A OUTPUT -p protocol --sport port -j ACCEPT`  | Allow outgoing traffic from a specific port                       |

## systemctl-commands

**SYSTEMCTL Commands**

| Command                                    | Description                                                                |
|--------------------------------------------|----------------------------------------------------------------------------|
| `systemctl start service`                  | Start a service                                                            |
| `systemctl stop service`                   | Stop a service                                                             |
| `systemctl restart service`                | Restart a service                                                          |
| `systemctl status service`                 | Display the status of a service                                            |
| `systemctl enable service`                 | Enable a service to start on boot                                          |
| `systemctl disable service`                | Disable a service from starting on boot                                    |
| `systemctl is-active service`              | Check if a service is active                                               |
| `systemctl is-enabled service`             | Check if a service is enabled                                              |
| `systemctl list-units --type=service`      | List all active services                                                   |
| `systemctl list-unit-files --type=service` | List all installed services                                                |
| `systemctl daemon-reload`                  | Reload systemd manager configuration                                       |
| `systemctl show service`                   | Show detailed information about a service                                  |
| `systemctl mask service`                   | Mask a service, preventing it from being started manually or automatically |

## nmcli-commands

**NMCLI Commands**

| Command                                            | Description                               |
|----------------------------------------------------|-------------------------------------------|
| `nmcli connection show`                            | Show details of all available connections |
| `nmcli device show`                                | Show details of all network devices       |
| `nmcli device status`                              | Display the status of network devices     |
| `nmcli connection up connection_name`              | Activate a specific connection            |
| `nmcli connection down connection_name`            | Deactivate a specific connection          |
| `nmcli connection add ...`                         | Add a new connection                      |
| `nmcli connection modify ...`                      | Modify an existing connection             |
| `nmcli connection delete connection_name`          | Delete a connection                       |
| `nmcli device wifi list`                           | List available Wi-Fi access points        |
| `nmcli device wifi connect SSID password PASSWORD` | Connect to a Wi-Fi network                |
| `nmcli general hostname`                           | Display the system's hostname             |
| `nmcli general permissions`                        | Display NetworkManager permissions        |
| `nmcli radio wifi on`                              | Enable Wi-Fi                              |
| `nmcli radio wifi off`                             | Disable Wi-Fi                             |
| `nmcli networking on`                              | Enable networking                         |
| `nmcli networking off`                             | Disable networking                        |

## nslookup-commands

**NSLOOUP Commands**

| Command                                | Description                                  |
|----------------------------------------|----------------------------------------------|
| `nslookup example.com`                 | Perform a basic DNS lookup for a domain.     |
| `nslookup -type=mx example.com`        | Retrieve Mail Exchange (MX) records.         |
| `nslookup -type=ns example.com`        | Retrieve Name Server (NS) records.           |
| `nslookup -type=cname www.example.com` | Retrieve Canonical Name (CNAME) record.      |
| `nslookup -query=soa example.com`      | Retrieve Start of Authority (SOA) record.    |
| `nslookup -query=txt example.com`      | Retrieve Text (TXT) record.                  |
| `nslookup -query=ptr 8.8.8.8`          | Perform reverse DNS lookup for an IP.        |
| `nslookup -query=any example.com`      | Retrieve all available records for a domain. |

## wget-commands

**WGET Commands**

| Description                             | Command                                                                         |
|-----------------------------------------|---------------------------------------------------------------------------------|
| Download a file                         | `wget <URL>`                                                                    |
| Download and save with a different name | `wget -O <output_filename> <URL>`                                               |
| Download multiple files from a file     | `wget -i <file_containing_URLs>`                                                |
| Continue an interrupted download        | `wget -c <URL>`                                                                 |
| Limit download speed                    | `wget --limit-rate=<speed> <URL>`                                               |
| Download in the background              | `wget -b <URL>`                                                                 |
| Download recursively (whole website)    | `wget -r <URL>`                                                                 |
| Download with user-agent specification  | `wget --user-agent="<user_agent>" <URL>`                                        |
| Download with HTTP authentication       | `wget --http-user=<username> --http-password=<password> <URL>`                  |
| Download with FTP authentication        | `wget --ftp-user=<username> --ftp-password=<password> <URL>`                    |
| Download via a proxy                    | `wget --proxy=on/off --proxy-user=<username> --proxy-password=<password> <URL>` |

## curl-commands

**CURL Commands**
| Description | Command |
|------------------------------------|------------------------------------------------|
| Perform a basic GET request | `curl https://example.com`                     |
| Send data with a POST request | `curl -X POST -d 'data=example' https://example.com` |
| Include headers in a request | `curl -H 'Content-Type: application/json' https://example.com` |
| Follow redirects with `-L` option | `curl -L https://example.com`                  |
| Save response to a file | `curl -o output.html https://example.com`     |
| Set a specific timeout | `curl --max-time 10 https://example.com`      |
| Include basic authentication | `curl -u username:password https://example.com` |
| Send JSON data in a POST
request | `curl -X POST -H 'Content-Type: application/json' -d '{"key": "value"}' https://example.com` |
| Upload a file with a POST request | `curl -X POST -F 'file=@localfile.txt' https://example.com/upload` |
| Perform a HEAD request | `curl -I https://example.com`                 |
| Display only response headers | `curl -I -s https://example.com`              |

## list-network-commands

**NETWORK Commands**

| Command                               | Description                                                                   |
|---------------------------------------|-------------------------------------------------------------------------------|
| `ping example.com`                    | Test the reachability of a host on an IP network.                             |
| `traceroute example.com`              | Trace the route that packets take to reach a destination.                     |
| `netstat -a`                          | Display network-related information, such as open sockets and routing tables. |
| `ifconfig` or `ip addr show`          | Display and configure network interface parameters.                           |
| `route -n`                            | Display and manipulate the IP routing table.                                  |
| `arp -a`                              | Display and manipulate the Address Resolution Protocol (ARP) cache.           |
| `iwconfig`                            | Configure wireless network interfaces.                                        |
| `hostname`                            | Display or set the system's hostname.                                         |
| `dig example.com`                     | Perform DNS queries.                                                          |
| `nslookup example.com`                | Query DNS for information about domain names and IP addresses.                |
| `ss -t`                               | Display information about socket connections.                                 |
| `lsof -i`                             | List open files, including network sockets.                                   |
| `ip link show`                        | Configure network interfaces, routing, tunnels, etc.                          |
| `iptables -L`                         | Configure IP packet filter rules.                                             |
| `systemctl status sshd`               | Check the status of the SSH server daemon.                                    |
| `sudo ifdown eth0`                    | Bring a network interface down.                                               |
| `nmcli connection show`               | Display NetworkManager connections.                                           |
| `curl http://example.com`             | Make HTTP requests.                                                           |
| `wget http://example.com/file.tar.gz` | Download files from the web.                                                  |
| `tcpdump -i eth0`                     | Capture and display packets on a network.                                     |

| Purpose                                            | Command (example user is 'dev')       |
|----------------------------------------------------|---------------------------------------| 
| Add Group                                          | sudo groupadd development             |
| Add User without Home Directory                    | sudo useradd sysdev                   |
| Add User with Home Directory & group               | sudo useradd -m -g development sysdev |
| Set password to user                               | sudo pV1layatu<br/>asswd dev          |
| Before deleting user kill the process used by user | sudo killall -u dev                   |
| Delete user                                        | sudo userdel -r dev                   |

**How to Install MySQL Server 8.0 in Ubuntu 22.04 LTS***
https://www.cyberciti.biz/faq/installing-mysql-server-on-ubuntu-22-04-lts-linux/
<<<<<<< HEAD

| Step                                                                                                                                                                                                | Command                                                                                                                                                                                                                                      |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| 
| Update system                                                                                                                                                                                       | sudo apt update <br /> sudo apt list --upgradable <br /> sudo apt upgrade                                                                                                                                                                    |
| Search for Existing mysql                                                                                                                                                                           | apt-cache search mysql-server                                                                                                                                                                                                                |
| Find more info about mysql-<v>                                                                                                                                                                      | apt info -a mysql-server-8.0                                                                                                                                                                                                                 |
| Install MySQL 8 Server Package                                                                                                                                                                      | sudo apt install mysql-server-8.0                                                                                                                                                                                                            |
| Setup Root Password                                                                                                                                                                                 | sudo mysql   <br /> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'MyRootPassword';                                                                                                                                 | 
| Find info about mysql.service                                                                                                                                                                       | sudo systemctl start mysql.service <br /> sudo systemctl stop mysql.service <br /> sudo systemctl restart mysql.service <br /> sudo systemctl status mysql.service                                                                           |
| Main MySQL server configuration directory                                                                                                                                                           | /etc/mysql/                                                                                                                                                                                                                                  |
| The MySQL database server configuration file <br /> Edit the .my.cnf ($HOME/.my.cnf) to set user-specific options. <br /> Additional settings that can override from the following two directories: | /etc/mysql/my.cnf <br /> /etc/mysql/conf.d/ <br /> /etc/mysql/mysql.conf.d/                                                                                                                                                                  |
| Port Setting                                                                                                                                                                                        | The TCP/3306 is the default network for the MySQL server and binds to 127.0.0.1 for security reasons <br /> MySQL server using the localhost socket set in the/run/mysqld/ directory                                                         |
| Securing MySQL 8 server                                                                                                                                                                             | sudo mysql_secure_installation                                                                                                                                                                                                               |
| Enable MySQL server at boot time                                                                                                                                                                    | sudo systemctl is-enabled mysql.service <br />   sudo systemctl enable mysql.service     <br />  sudo systemctl status mysql.service                                                                                                         |
| Start/Stop/Restarting MySQL Server                                                                                                                                                                  | sudo systemctl start mysql.service <br /> sudo systemctl stop mysql.service <br /> sudo systemctl restart mysql.service <br /> sudo systemctl status mysql.service                                                                           |
| View Journal Log                                                                                                                                                                                    | sudo journalctl -u mysql.service -xe                                                                                                                                                                                                         |
| View Error Log                                                                                                                                                                                      | sudo tail -f /var/log/mysql/error.log                                                                                                                                                                                                        |
| Login into MySQL 8 server for testing purpose                                                                                                                                                       | mysql -u {user} -p <br /> mysql -u {user} -h {remote_server_ip} -p <br /> mysql -u root -p                                                                                                                                                   |
| Useful DB Commands                                                                                                                                                                                  | STATUS; <br /> SHOW VARIABLES LIKE "%version%";                                                                                                                                                                                              |
| Create DB & User                                                                                                                                                                                    | CREATE DATABASE mydemodb;  <br /> CREATE USER 'vivekappusr'@'%' IDENTIFIED BY 'myPassword'; <br /> GRANT SELECT, INSERT, UPDATE, DELETE ON mydemodb.* TO 'vivekappusr'@'%';  <br /> GRANT ALL PRIVILEGES ON mydemodb.* TO 'vivekappusr'@'%'; |
| Find DB user Status                                                                                                                                                                                 | SELECT USER,host FROM mysql.user; <br />    SHOW GRANTS FOR vivekappusr;                                                                                                                                                                     |
| MySQL 8 Server Configuration                                                                                                                                                                        | sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf <br /> sudo systemctl edit mysql.service                                                                                                                                                         |
| -                                                                                                                                                                                                   | -                                                                                                                                                                                                                                            |

=======

| Step                                                                                                                                                                                                | Command                                                                                                                                                                                                                                      |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| 
| Update system                                                                                                                                                                                       | sudo apt update <br /> sudo apt list --upgradable <br /> sudo apt upgrade                                                                                                                                                                    |
| Search for Existing mysql                                                                                                                                                                           | apt-cache search mysql-server                                                                                                                                                                                                                |
| Find more info about mysql-<v>                                                                                                                                                                      | apt info -a mysql-server-8.0                                                                                                                                                                                                                 |
| Install MySQL 8 Server Package                                                                                                                                                                      | sudo apt install mysql-server-8.0                                                                                                                                                                                                            |
| Setup Root Password                                                                                                                                                                                 | sudo mysql   <br /> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'MyRootPassword';                                                                                                                                 | 
| Find info about mysql.service                                                                                                                                                                       | sudo systemctl start mysql.service <br /> sudo systemctl stop mysql.service <br /> sudo systemctl restart mysql.service <br /> sudo systemctl status mysql.service                                                                           |
| Main MySQL server configuration directory                                                                                                                                                           | /etc/mysql/                                                                                                                                                                                                                                  |
| The MySQL database server configuration file <br /> Edit the .my.cnf ($HOME/.my.cnf) to set user-specific options. <br /> Additional settings that can override from the following two directories: | /etc/mysql/my.cnf <br /> /etc/mysql/conf.d/ <br /> /etc/mysql/mysql.conf.d/                                                                                                                                                                  |
| Port Setting                                                                                                                                                                                        | The TCP/3306 is the default network for the MySQL server and binds to 127.0.0.1 for security reasons <br /> MySQL server using the localhost socket set in the/run/mysqld/ directory                                                         |
| Securing MySQL 8 server                                                                                                                                                                             | sudo mysql_secure_installation                                                                                                                                                                                                               |
| Enable MySQL server at boot time                                                                                                                                                                    | sudo systemctl is-enabled mysql.service <br />   sudo systemctl enable mysql.service     <br />  sudo systemctl status mysql.service                                                                                                         |
| Start/Stop/Restarting MySQL Server                                                                                                                                                                  | sudo systemctl start mysql.service <br /> sudo systemctl stop mysql.service <br /> sudo systemctl restart mysql.service <br /> sudo systemctl status mysql.service                                                                           |
| View Journal Log                                                                                                                                                                                    | sudo journalctl -u mysql.service -xe                                                                                                                                                                                                         |
| View Error Log                                                                                                                                                                                      | sudo tail -f /var/log/mysql/error.log                                                                                                                                                                                                        |
| Login into MySQL 8 server for testing purpose                                                                                                                                                       | mysql -u {user} -p <br /> mysql -u {user} -h {remote_server_ip} -p <br /> mysql -u root -p                                                                                                                                                   |
| Useful DB Commands                                                                                                                                                                                  | STATUS; <br /> SHOW VARIABLES LIKE "%version%";                                                                                                                                                                                              |
| Create DB & User                                                                                                                                                                                    | CREATE DATABASE mydemodb;  <br /> CREATE USER 'vivekappusr'@'%' IDENTIFIED BY 'myPassword'; <br /> GRANT SELECT, INSERT, UPDATE, DELETE ON mydemodb.* TO 'vivekappusr'@'%';  <br /> GRANT ALL PRIVILEGES ON mydemodb.* TO 'vivekappusr'@'%'; |
| Find DB user Status                                                                                                                                                                                 | SELECT USER,host FROM mysql.user; <br />    SHOW GRANTS FOR vivekappusr;                                                                                                                                                                     |
| MySQL 8 Server Configuration                                                                                                                                                                        | sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf <br /> sudo systemctl edit mysql.service                                                                                                                                                         |
| -                                                                                                                                                                                                   | -                                                                                                                                                                                                                                            |

> > > > > > > develop
> > > > > > > Feel free to customize the table based on your needs or add more details as required.

**How to check application location**

sudo update-alternatives --config java
exit

**How to check application is running**

    sudo service mysql status

**How to login to Postgres**

    https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart
    sudo -i -u postgres
    psql
    \q

**Find the process using & port**

    netstat -tulpn | grep LISTEN

**Find public ip address**

    echo $(curl -s https://api.ipify.org)

**SSH Key Generation**

    ssh-keygen -t ed25519 -C "your_email@example.com"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/<private ssh file>

**Ubuntu Firewall commands**

https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04
https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands

    sudo ufw status
    sudo ufw enable
    sudo ufw allow 22
    sudo ufw deny 22
    sudo ufw allow 6000:6007/tcp
    sudo ufw allow 6000:6007/udp
    sudo ufw deny from <203.0.113.100> 
    sudo ufw deny from <203.0.113.0/24>
    sudo ufw deny in on <eth0> from 203.0.113.100

| Command                                                         | Description                                                    |
|-----------------------------------------------------------------|----------------------------------------------------------------|
| `find /path/to/search -name "filename"`                         | Find files by name in a specific directory                     |
| `find /path/to/search -type f`                                  | Find only regular files in a specific directory                |
| `find /path/to/search -type d`                                  | Find only directories in a specific directory                  |
| `find /path/to/search -user username`                           | Find files owned by a specific user in a specific directory    |
| `find /path/to/search -size +10M`                               | Find files larger than 10 megabytes in a specific directory    |
| `find /path/to/search -mtime -7`                                | Find files modified in the last 7 days in a specific directory |
| `find /path/to/search -exec rm {} \;`                           | Find and delete files in a specific directory                  |
| `find /path/to/search -name "*.txt" -exec grep "pattern" {} \;` | Search for a pattern in all text files in a specific directory |

| Command                                                               | Description                                                                                                  |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `grep "search_string" /path/to/file`                                  | Search for a string in a specific file                                                                       |
| `grep -r "search_string" /path/to/directory`                          | Recursively search for a string in all files within a directory                                              |
| `grep -r "search_string" /path/to/directory/*`                        | Recursively search for a string in all files and subdirectories within a directory                           |
| `grep -irl "search_string" /path/to/directory`                        | Recursively search for a string in file names (case-insensitive) within a directory                          |
| `ack "search_string" /path/to/directory`                              | Advanced search tool (you may need to install `ack`)                                                         |
| `ag "search_string" /path/to/directory`                               | Silver Searcher tool (you may need to install `silversearcher-ag`)                                           |
| `find /path/to/directory -type f -exec grep -l "search_string" {} \;` | Find files in a directory and its subdirectories containing a specific string                                |
| `ack-grep -il "search_string" /path/to/directory`                     | Find files in a directory and its subdirectories containing a specific string (alternative using `ack-grep`) |
