**User Maintainance**

| Purpose                                            | Command (example user is 'dev')    |
|----------------------------------------------------|------------------------------------| 
| Add Group                                          | sudo groupadd development          |
| Add User without Home Directory                    | sudo useradd dev                   |
| Add User with Home Directory & group               | sudo useradd -m -g development dev |
| Set password to user                               | sudo passwd dev                    |
| Before deleting user kill the process used by user | sudo killall -u dev                |
| Delete user                                        | sudo userdel -r dev                |

**How to check application location**

sudo update-alternatives --config java

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

    sudo ufw status
    sudo ufw enable
    sudo ufw allow 22
    sudo ufw allow 6000:6007/tcp
    sudo ufw allow 6000:6007/udp
