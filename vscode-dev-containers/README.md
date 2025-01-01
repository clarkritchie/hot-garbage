# Dev Containers

A rough example of how to setup Dev Containers.

1. Install the VS Code plugin
2. At the roof or your project, `mkdir .devcontainer` and inside it, place a [devcontainer.json](devcontainer.json).  Make note of the path for `dockerComposeFile`.
3. Make a directory at the path defined by `dockerComposeFile`.  Sample [compose config](docker-compose-dev-container.yaml) and a basic [entrypoint](entrypoint-dev-container.sh) scripts.
4. Customize as required!
