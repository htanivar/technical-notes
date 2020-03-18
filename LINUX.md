**Find the process using & port**

    netstat -tulpn | grep LISTEN

**Find public ip address**

    echo $(curl -s https://api.ipify.org)
