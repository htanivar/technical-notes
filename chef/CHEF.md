| User Commands                         | Admin Commands |
|---------------------------------------|----------------|
| [CHEF Commands](#chef-commands)       | -              |
| [KNIFE Commands](#knife-commands)     | -              |
| [KITCHEN Commands](#kitchen-commands) | -              |
| [OHAI Commands](#ohai-commands)       | -              |

## chef-commands

**CHEF Commands**

| Command                                  | Description                                             |
|------------------------------------------|---------------------------------------------------------|
| `chef -v`                                | Check Chef version                                      |
| `chef -h` \| `chef --help`               | Display help information about Chef CLI                 |
| `chef-shell --version`                   | Check Chef Shell version                                |
| `chef-solo --version`                    | Check Chef Solo version                                 |
| `chef-client --version`                  | Check Chef Client version                               |
| `chef-server-ctl version`                | Check Chef Server version                               |
| `chef-server-ctl status`                 | Check status of the Chef Server                         |
| `ohai`                                   | Display system configuration details                    |
| `ohai platform` \| `ohai   \| grep chef` | Display platform information (e.g., Linux distribution) |
| `cat /etc/*-release`                     | Check Linux distribution version                        |
| `ps aux \| grep chef`                    | Check if Chef processes are running                     |
| `chef-apply --version`                   | Check Chef Apply version                                |
| `chef -h` or `chef --help`               | Display help information about Chef CLI                 |
| `chef-shell --version`                   | Check Chef Shell version                                |
| `chef-solo --version`                    | Check Chef Solo version                                 |
| `chef-client --version`                  | Check Chef Client version                               |
| `chef-server-ctl version`                | Check Chef Server version                               |
| `chef-server-ctl status`                 | Check status of the Chef Server                         |
| `knife --version`                        | Check version of the Knife CLI                          |
| `ohai`                                   | Display system configuration details                    |
| `ohai platform`                          | Display platform information (e.g., Linux distribution) |
| `cat /etc/*-release`                     | Check Linux distribution version                        |
| `chef-apply --version`                   | Check Chef Apply version                                |

## knife-commands

**KNIFE Commands**

| Command                                                          | Description                                              |
|------------------------------------------------------------------|----------------------------------------------------------|
| `knife -v`                                                       | Check Knife version                                      |
| `knife client list`                                              | List all clients                                         |
| `knife node list`                                                | List all nodes                                           |
| `knife cookbook list`                                            | List all cookbooks                                       |
| `knife environment list`                                         | List all environments                                    |
| `knife role list`                                                | List all roles                                           |
| `knife data bag list`                                            | List all data bags                                       |
| `knife user list`                                                | List all users                                           |
| `knife status`                                                   | Display the status of all nodes                          |
| `knife node show NODE_NAME`                                      | Show details of a specific node                          |
| `knife cookbook show COOKBOOK_NAME`                              | Show details of a specific cookbook                      |
| `knife environment show ENVIRONMENT_NAME`                        | Show details of a specific environment                   |
| `knife role show ROLE_NAME`                                      | Show details of a specific role                          |
| `knife data bag show DATA_BAG_NAME ITEM_NAME`                    | Show details of a specific item in a data bag            |
| `knife user show USER_NAME`                                      | Show details of a specific user                          |
| `knife bootstrap NODE_IP -x USERNAME -P PASSWORD`                | Bootstrap a node with Chef client using SSH              |
| `knife ssh 'name:*' 'uptime' -x USERNAME -P PASSWORD`            | Run a command on multiple nodes via SSH                  |
| `knife search node 'platform:ubuntu'`                            | Search for nodes based on criteria (e.g., platform)      |
| `knife upload /path/to/cookbooks`                                | Upload local cookbooks to Chef server                    |
| `knife download /path/to/destination`                            | Download cookbooks, roles, or data bags from Chef server |
| `knife role from file /path/to/role.json`                        | Create or update a role from a JSON file                 |
| `knife data bag create DATA_BAG_NAME`                            | Create a new data bag                                    |
| `knife data bag from file DATA_BAG_NAME FILE.json`               | Upload data bag items from a JSON file                   |
| `knife user create USERNAME -f FIRST_NAME LAST_NAME -p PASSWORD` | Create a new user                                        |
| `knife user edit USERNAME`                                       | Edit user details                                        |
| `knife user delete USERNAME`                                     | Delete a user                                            |
| `knife node run_list add NODE_NAME 'recipe[RECIPE_NAME]'`        | Add a recipe to a node's run list                        |
| `knife node run_list remove NODE_NAME 'recipe[RECIPE_NAME]'`     | Remove a recipe from a node's run list                   |

## kitchen-commands

**KITCHEN Commands**

| Command                                   | Description                                               |
|-------------------------------------------|-----------------------------------------------------------|
| `kitchen init`                            | Initialize Test Kitchen in the current directory          |
| `kitchen create`                          | Create an instance based on the configuration             |
| `kitchen converge`                        | Apply cookbook changes to the instance                    |
| `kitchen verify`                          | Run automated tests on the instance                       |
| `kitchen login`                           | Log in to the instance via SSH                            |
| `kitchen destroy`                         | Destroy the instance                                      |
| `kitchen test`                            | Create, converge, verify, and destroy the instance        |
| `kitchen list`                            | List all instances                                        |
| `kitchen diagnose`                        | Diagnose common issues with Test Kitchen                  |
| `kitchen exec INSTANCE_NAME COMMAND`      | Execute a command on a specific instance                  |
| `kitchen converge INSTANCE_NAME`          | Converge a specific instance                              |
| `kitchen verify INSTANCE_NAME`            | Verify a specific instance                                |
| `kitchen destroy INSTANCE_NAME`           | Destroy a specific instance                               |
| `kitchen test -d always`                  | Run Test Kitchen in debug mode always                     |
| `kitchen test -d never`                   | Run Test Kitchen in debug mode never                      |
| `kitchen test -d INSTANCE_NAME`           | Run Test Kitchen in debug mode for a specific instance    |
| `kitchen login INSTANCE_NAME`             | Log in to a specific instance via SSH                     |
| `kitchen converge -c 3`                   | Converge with a concurrency level of 3 instances          |
| `kitchen exec INSTANCE_NAME -c 'COMMAND'` | Execute a command on a specific instance with concurrency |

## ohai-commands

**OHAI Commands**

| Command                          | Description                                          |
|----------------------------------|------------------------------------------------------|
| `ohai`                           | Display all available system and node attributes     |
| `ohai -l`                        | List all available plugins                           |
| `ohai attribute_name`            | Display a specific attribute (e.g., `ohai platform`) |
| `ohai --help`                    | Display help information about Ohai                  |
| `ohai -d attribute_name`         | Debug mode: Display attribute with debug information |
| `ohai -i plugin_name`            | Display information from a specific plugin           |
| `ohai --yaml`                    | Display node attributes in YAML format               |
| `ohai --json`                    | Display node attributes in JSON format               |
| `ohai --version`                 | Check Ohai version                                   |
| `ohai -c /path/to/custom/plugin` | Specify a custom Ohai plugin to use                  |
