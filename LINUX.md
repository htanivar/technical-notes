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
