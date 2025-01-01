# Dev Containers

A rough example of how to setup Dev Containers.

1. Install the VS Code plugin
2. At the root or your project, `mkdir .devcontainer` and inside it, make a [devcontainer.json](devcontainer.json).  Make note of the path for `dockerComposeFile`.
3. Make a directory at the path defined by `dockerComposeFile`.  See example [Dockerfile](Dockerfike.dev-container), a [compose config](docker-compose-dev-container.yaml) and a basic [entrypoint](entrypoint-dev-container.sh) script.
4. Customize as required!
