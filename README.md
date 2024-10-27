# Medal of Honor: Heroes 2 - Deployment project

A docker compose project designed to automate the deployment of [Medal of Honor: Heroes's master server](https://github.com/a-blondel/mohh-master-server) and its requirements.

## How to deploy

- Install Docker and Docker Compose on your server
- Create environment secrets matching the right environment in GitHub Actions :
  - `SERVER_IP` : Server IP, used to connect to the server machine and host the services
  - `SERVER_USERNAME` : The username to connect to the server machine
  - `SERVER_SSH_KEY` : The SSH key to connect to the server machine
  - `GH_USERNAME` : The username to connect to GitHub
  - `GH_TOKEN` : The token to connect to GitHub (see [here](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token))
  - `DB_USERNAME` : The username to connect to the database
  - `DB_PASSWORD` : The password to connect to the database
  - `GPS_NAME` : The name of the game account used to host GPS server instances
  - `GPS_PWD` : The password of the game account used to host GPS server instances
  - `GPS_ADMIN_PWD` : The password to access the admin menu of GPS server instances in the game
  - `GPS_PORT` : The port of the first GPS server instance, defaults to 3658. Every instance will use a port starting from this one
  - `GPS_INSTANCE` : The number of GPS server instances to run, defaults to 1
- Run the workflow