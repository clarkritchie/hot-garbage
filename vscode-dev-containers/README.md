# Dev Containers

A rough example of how to setup Dev Containers.

1. Install the VS Code plugin for Dev Containers.
2. At the root or your project, `mkdir .devcontainer` and inside of that, make a [devcontainer.json](devcontainer.json).  Make note of the path for `dockerComposeFile` -- you could put this anywhere, even in `.devcontainer` is fine -- I just like to keep it up one directory.
3. Make a directory at the path defined by `dockerComposeFile`.  See this example [Dockerfile](Dockerfike.dev-container), this [compose config](docker-compose-dev-container.yaml) and a basic [entrypoint](entrypoint-dev-container.sh) script.
4. Restart VS Code and it should prompt you to re-open your project in a container.
5. Customize as required!
