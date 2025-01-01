# Dev Containers

A rough example of how to setup Dev Containers.

1. Install the VS Code plugin for Dev Containers.
2. At the root or your project, `mkdir .devcontainer` and inside of that, make a [devcontainer.json](devcontainer.json).  Make note of the path for `dockerComposeFile` -- you could put this anywhere, even in `.devcontainer` is fine -- I just like to keep it up one directory.
3. Make a directory at the path defined by `dockerComposeFile`.  See this example [Dockerfile](Dockerfike.dev-container), this [compose config](docker-compose-dev-container.yaml) and a basic [entrypoint](entrypoint-dev-container.sh) script.  Customize these, as required!  The compose config is pretty much just regular Docker Compose.
4. Restart VS Code and it should prompt you to re-open your project in a container.  You'll know it succeeded if your terminal is `/workspace` instead of your normal `/Users/cool-guy/projects` or whatever.
