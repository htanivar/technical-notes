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


**How to Install MySQL Server 8.0 in Ubuntu 22.04 LTS***
https://www.cyberciti.biz/faq/installing-mysql-server-on-ubuntu-22-04-lts-linux/

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
