# 10root stack

**Goal**: The goal of this project is to create a stack of services that can be used for incident response and threat hunting.

**Description**: This stack contains a set of the services, which are combined with the docker compose file. Each app has its own folder with the docker compose file, all apps use one network.

## Current status

The current implementation is a POC, which is not stable from time to time. The main goal is to have a working stack with the following services:

1. **[ELK](https://github.com/deviantony/docker-elk)**. Description: Elasticsearch, Kibana & Logstash. The ELK stack is a log management platform for collecting, searching, and analyzing logs.
2. **[Portainer](https://github.com/portainer/portainer)**. Description: Portainer is a lightweight management UI that allows you to easily manage your different Docker environments (Docker hosts or Swarm clusters).
3. **[Iris](https://github.com/dfir-iris/iris-web/tree/master)**. Description: Iris is a web collaborative platform aiming to help incident responders sharing technical details during investigations.
4. **[Strelka](https://github.com/target/strelka/)** Description: Strelka is a real-time file scanning system used for threat hunting, threat detection, and incident response.
5. **[Timesketch](https://github.com/google/timesketch)**. Description: Timesketch is an open-source tool for collaborative forensic timeline analysis.
6. **[Velociraptor](https://github.com/Velocidex/velociraptor)**. Description: Velociraptor is a tool for collecting host-based state information using The Velociraptor Query Language (VQL) queries.
7. **[Nginx](https://github.com/nginx/nginx)**. Description: Nginx is a web server that proxy all requests to the services  in this stack.

## Resources

All settings are located in the `resources` folder.

## Scripts

All scripts are located in the `scripts` folder.

The following scripts are available:
- `endtoend.sh` - start the stack
- `cleanup.sh` - stop and remove the stack
  - Use `cleanup.sh --help` to see the available options

## Pre-requirements

TODO: Fix the `install_pre_requisites.sh` logic

- Docker; client and server ~ 20.10
- docker compose plugin v2 ~ 2.26
- Git ~ 2.34
- [yq](https://github.com/mikefarah/yq/#install) ~ 4.44
- bash shell ~ 5.0
- unzip ~ 6.0
- rsync ~ 3.2
