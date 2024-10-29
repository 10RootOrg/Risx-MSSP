# 10root stack

**Goal**: The goal of this project is to create a stack of services that can be used for incident response and threat hunting.

**Description**: This stack contains a set of the services, which are combined with the docker compose file. Each app has its own folder with the docker compose file, all apps use one network.

## Current status

The current implementation is a POC, which is not stable from time to time. The main goal is to have a working stack with the following services:

<details>
  <summary>CLick to open the list of the APPS</summary>

This stack is growing, you find a complete list of the services in the file `resources/default.env` in the environment variable `APPS_TO_INSTALL`.

1. **[CyberChef](https://github.com/gchq/CyberChef)**. Description: CyberChef is a simple, intuitive web app for carrying out all manners of "cyber" operations within a web browser.
2. **[ELK](https://github.com/deviantony/docker-elk)**. Description: Elasticsearch, Kibana & Logstash. The ELK stack is a log management platform for collecting, searching, and analyzing logs.
3. **[Iris](https://github.com/dfir-iris/iris-web/tree/master)**. Description: Iris is a web collaborative platform aiming to help incident responders sharing technical details during investigations.
4.  **[Nightingale](https://github.com/nightingaleproject/nightingale)**. Description: An Open Source Next Generation Electronic Death Registration System.
5. **[Portainer](https://github.com/portainer/portainer)**. Description: Portainer is a lightweight management UI that allows you to easily manage your different Docker environments (Docker hosts or Swarm clusters).
6. **[Strelka](https://github.com/target/strelka/)** Description: Strelka is a real-time file scanning system used for threat hunting, threat detection, and incident response.
7. **[Timesketch](https://github.com/google/timesketch)**. Description: Timesketch is an open-source tool for collaborative forensic timeline analysis.
8. **[Velociraptor](https://github.com/Velocidex/velociraptor)**. Description: Velociraptor is a tool for collecting host-based state information using The Velociraptor Query Language (VQL) queries.
9. **[Nginx](https://github.com/nginx/nginx)**. Description: Nginx is a web server that proxy all requests to the services in this stack.

</details>

## Resources

All settings are located in the `resources` folder.

## Scripts

All scripts are located in the `scripts` folder.

The following scripts are available:
- `endtoend.sh` - start the stack
- `cleanup.sh` - stop and remove the stack
  - Use `cleanup.sh --help` to see the available options

## Pre-requirements

<details>
  <summary>CLick to open the list of the pre-requirements</summary>

This stack is growing,
you find a complete list of the requirements in the file `resources/default.env` in the environment variable `REQUIRED_PACKAGES`.

- Docker; client and server ~ 20.10
- docker compose plugin v2 ~ 2.26
- Git ~ 2.34
- [yq](https://github.com/mikefarah/yq/#install) ~ 4.44
- bash shell ~ 5.0
- unzip ~ 6.0
- rsync ~ 3.2

</details>
