# Comprehensive Docker Commands

## Basic Commands

| Command                        | Description                                 |
| ------------------------------ | ------------------------------------------- |
| `docker --version`             | Show the Docker version installed           |
| `docker info`                  | Display system-wide information             |
| `docker help`                  | List Docker commands                        |

## Container Management

| Command                                     | Description                                                                                  |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `docker run -d --name container_name image` | Run a container in detached mode                                                             |
| `docker ps`                                 | List running containers                                                                      |
| `docker ps -a`                              | List all containers (including stopped ones)                                                 |
| `docker start container_name`               | Start a stopped container                                                                    |
| `docker stop container_name`                | Stop a running container                                                                     |
| `docker restart container_name`             | Restart a container                                                                          |
| `docker rm container_name`                  | Remove a stopped container                                                                   |
| `docker logs container_name`                | View the logs of a container                                                                 |
| `docker exec -it container_name bash`       | Execute a command in a running container (e.g., open a bash shell)                           |
| `docker attach container_name`              | Attach to a running container                                                                |
| `docker inspect container_name`             | Display detailed information about a container                                               |
| `docker cp container_name:/path/to/file .`  | Copy files/folders from a container to the host                                              |
| `docker update --restart=always container_name` | Set a container to always restart                                                            |

## Image Management

| Command                                  | Description                                               |
| ---------------------------------------- | --------------------------------------------------------- |
| `docker images`                          | List all Docker images                                    |
| `docker pull image`                      | Download an image from a Docker registry                  |
| `docker build -t image_name .`           | Build an image from a Dockerfile                          |
| `docker tag image_name username/repo:tag`| Tag an image                                             |
| `docker push username/repo:tag`          | Push an image to a Docker registry                        |
| `docker rmi image_name`                  | Remove an image                                           |
| `docker history image_name`              | Show the history of an image                              |
| `docker save -o image.tar image_name`    | Save an image to a tar archive                            |
| `docker load -i image.tar`               | Load an image from a tar archive                          |

## Network Management

| Command                                     | Description                                                   |
| ------------------------------------------- | ------------------------------------------------------------- |
| `docker network ls`                         | List all Docker networks                                      |
| `docker network inspect network_name`       | Display detailed information about a network                  |
| `docker network create network_name`        | Create a new network                                          |
| `docker network connect network_name container_name` | Connect a container to a network                          |
| `docker network disconnect network_name container_name` | Disconnect a container from a network                    |
| `docker network rm network_name`            | Remove a network                                              |

## Volume Management

| Command                               | Description                                                   |
| ------------------------------------- | ------------------------------------------------------------- |
| `docker volume ls`                    | List all Docker volumes                                       |
| `docker volume create volume_name`    | Create a new volume                                           |
| `docker volume inspect volume_name`   | Display detailed information about a volume                   |
| `docker volume rm volume_name`        | Remove a volume                                               |
| `docker run -v volume_name:/path image` | Mount a volume when running a container                       |

## Docker Compose

| Command                                  | Description                                                   |
| ---------------------------------------- | ------------------------------------------------------------- |
| `docker-compose up`                      | Create and start containers defined in `docker-compose.yml`   |
| `docker-compose up -d`                   | Create and start containers in detached mode                  |
| `docker-compose down`                    | Stop and remove containers, networks, images, and volumes     |
| `docker-compose ps`                      | List containers                                               |
| `docker-compose build`                   | Build or rebuild services                                     |
| `docker-compose logs`                    | View output from containers                                   |
| `docker-compose exec service_name command` | Execute a command in a running service                       |
| `docker-compose stop`                    | Stop running containers                                       |
| `docker-compose restart`                 | Restart running containers                                    |
| `docker-compose rm`                      | Remove stopped containers                                     |

## Docker Swarm

| Command                                | Description                                                   |
| -------------------------------------- | ------------------------------------------------------------- |
| `docker swarm init`                    | Initialize a swarm                                            |
| `docker swarm join --token token node_ip:2377` | Join a node to a swarm                                  |
| `docker node ls`                       | List nodes in the swarm                                       |
| `docker service create --name service_name image` | Create a service in the swarm                          |
| `docker service ls`                    | List services in the swarm                                    |
| `docker service ps service_name`       | List tasks of a service                                       |
| `docker service scale service_name=replicas` | Scale a service to the specified number of replicas   |
| `docker service rm service_name`       | Remove a service from the swarm                               |
| `docker stack deploy -c docker-compose.yml stack_name` | Deploy a stack in the swarm using a Compose file      |
| `docker stack ls`                      | List stacks in the swarm                                      |
| `docker stack services stack_name`     | List services in a stack                                      |
| `docker stack ps stack_name`           | List tasks in a stack                                         |
| `docker stack rm stack_name`           | Remove a stack from the swarm                                 |

## Docker Cleanup

| Command                                  | Description                                                   |
| ---------------------------------------- | ------------------------------------------------------------- |
| `docker system prune`                    | Remove all unused containers, networks, images, and volumes   |
| `docker container prune`                 | Remove all stopped containers                                 |
| `docker image prune`                     | Remove unused images                                          |
| `docker volume prune`                    | Remove unused volumes                                         |
| `docker network prune`                   | Remove unused networks                                        |

## Additional Commands

| Command                                     | Description                                                   |
| ------------------------------------------- | ------------------------------------------------------------- |
| `docker stats`                              | Display a live stream of container(s) resource usage statistics|
| `docker top container_name`                 | Display the running processes of a container                  |
| `docker events`                             | Get real-time events from the Docker daemon                   |
| `docker wait container_name`                | Block until a container stops, then print the exit code       |
| `docker export container_name > container.tar` | Export a container’s filesystem as a tar archive            |
| `docker import < container.tar`             | Import a tarball to create a filesystem image                 |

This Markdown document provides a comprehensive list of Docker commands, organized by category, for easy reference.
