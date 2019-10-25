# Oryx Dockerfile - GitHub Action

## About

This GitHub Action will use the `oryx dockerfile` command to generate a Dockerfile that will produce an image to build and run an Azure web app. This Dockerfile can then be built and pushed to a registry, such as [Azure Container Registry](https://azure.microsoft.com/en-us/services/container-registry/), and ran at a later time to run the web app.

The Dockerfile follows a template similar to the following:

```
ARG RUNTIME=<PLATFORM_NAME>:<PLATFORM_VERSION>

FROM mcr.microsoft.com/oryx/build:<BUILD_TAG> as build
WORKDIR /app
COPY . .
RUN oryx build /app

FROM mcr.microsoft.com/oryx/${RUNTIME}
COPY --from=build /app /app
RUN cd /app && oryx
ENTRYPOINT ["/app/run.sh"]
```

where the following variables are set as a part of the `oryx dockerfile` command:

- `<PLATFORM_NAME>`
    - Either provided by the user or detected by Oryx, the platform that will be used to build the web app in the Oryx build image
- `<PLATFORM_VERSION>`
    - Either provided by the user or detected by Oryx, the version of the platform that will be used to build the web app in the Oryx build image
- `<BUILD_TAG>`
    - Either `latest` or `slim`, determined by the platform name and version; `slim` is a smaller image with fewer build dependencies that is faster to pull than the `latest` image, which contains all platform build dependencies

## Usage

The Oryx Dockerfile GitHub Action can be included in a repository's workflow by using `microsoft/oryx/actions/oryx-dockerfile@master`.

The following parameters can be set as a part of the action:

- `sourceDirectory`
    - Source directory of the repository; if no value is provided for this, the current working directory in the container is set as the source directory
- `outputDockerfile`
    - Path to the Dockerfile that will be written to; if no value is provided for this, the result will be written to a `Dockerfile.oryx` file in the source directory
- `platform`
    - Programming platform used to build the web app; if no value is provided for this, Oryx will detect the platform. The supported values are "dotnet", "nodejs", "php" and "python"
- `platformVersion`
    - Version of the programming platform used to build the web app; if no value is provided for this, Oryx will detect the version

The result of the action is a path to the Dockerfile that was generated; the path to this Dockerfile can be used in the workflow by calling `{{ steps.id.outputs.dockerfilePath }}`, where `id` is the ID of the step calling this Oryx Dockerfile action.

## Examples

### Pushing the image

#### Pushing using Azure CLI

The following is an end-to-end sample of generating the Dockerfile, building the image, and pushing it to Azure Container Registry using Azure CLI:

```
steps:
  - name: Cloning repository to container
    uses: actions/checkout@v1

  - name: Running Oryx to generate a Dockerfile
    uses: microsoft/oryx/actions/oryx-dockerfile@master
    id: oryx

  - name: Azure authentication
    uses: azure/actions/login@v1
    with:
      creds: ${{ secrets.AZURE_CREDENTIALS }}

  - name: Building image and pushing to ACR
    run: |
      az acr build -t <IMAGE_NAME>:<TAG> \
                   -r <ACR_NAME> \
                   -f {{ steps.oryx.outputs.dockerfilePath }}
```

The following variables should be replaced in your workflow `.yaml` file:

- `<ACR_NAME>`
    - Name of the Azure Container Registry that you are pushing to
- `<IMAGE_NAME>`
    - Name of the image that will be pushed to your registry
- `<TAG>`
    - Name of the image tag

The following variables should be set in the GitHub repository's secrets store:

- `AZURE_CREDENTIALS`
    - Used to authenticate calls to Azure; for more information on setting this secret, please see the [`azure/actions/login`](https://github.com/Azure/actions) action

#### Pushing using Docker

The following is an end-to-end sample of generating the Dockerfile, building the image, and pushing it to a registry using Docker:

```
steps:
  - name: Cloning repository to container
    uses: actions/checkout@v1

  - name: Running Oryx to generate a Dockerfile
    uses: microsoft/oryx/actions/oryx-dockerfile@master
    id: oryx

  - name: Logging into registry
    uses: azure/container-actions/docker-login@master
    with:
      login-server: <REGISTRY_NAME>
      username: ${{ secrets.REGISTRY_USERNAME }}
      password: ${{ secrets.REGISTRY_PASSWORD }}

  - name: Building image and pushing to registry using Docker
    run: |
      docker build . -t <REGISTRY_NAME>/<IMAGE_NAME>:<TAG> -f {{ steps.oryx.outputs.dockerfilePath }}
      docker push <REGISTRY_NAME>/<IMAGE_NAME>:<TAG>
```

The following variables should be replaced in your workflow:

- `<REGISTRY_NAME>`
    - Name of the registry that you are pushing to
- `<IMAGE_NAME>`
    - Name of the image that will be pushed to your registry
- `<TAG>`
    - Name of the image tag

The following variables should be set in the GitHub repository's secrets store:

- `REGISTRY_USERNAME`
    - The username for the container registry; for more information on setting this secret, please see the [`azure/container-actions/docker-login`](https://github.com/Azure/container-actions) action
- `REGISTRY_PASSWORD`
    - The password for the container registry; for more information on setting this secret, please see the [`azure/container-actions/docker-login`](https://github.com/Azure/container-actions) action

### Deploying an Azure Web App

#### Deploying using Web App Containers

The following is an end-to-end sample of generating the Dockerfile, building the image, pushing it to a registry using Docker, and deploying the web app to Azure:

```
steps:
  - name: Cloning repository to container
    uses: actions/checkout@v1

  - name: Running Oryx to generate a Dockerfile
    uses: microsoft/oryx/actions/oryx-dockerfile@master
    id: oryx

  - name: Logging into Azure
    uses: azure/actions/login@master
    with:
      creds: ${{ secrets.AZURE_CREDENTIALS }}

  - name: Logging into registry
    uses: azure/container-actions/docker-login@master
    with:
      login-server: <REGISTRY_NAME>
      username: ${{ secrets.REGISTRY_USERNAME }}
      password: ${{ secrets.REGISTRY_PASSWORD }}

  - name: Building image and pushing to registry using Docker
    run: |
      docker build . -t <REGISTRY_NAME>/<IMAGE_NAME>:<TAG> -f {{ steps.oryx.outputs.dockerfilePath }}
      docker push <REGISTRY_NAME>/<IMAGE_NAME>:<TAG>

  - name: Deploying container web app to Azure
    uses: azure/appservice-actions/webapp-container@master
    with:
      app-name: <WEB_APP_NAME>
      images: <REGISTRY_NAME>/<IMAGE_NAME>:<TAG>
```

The following variables should be replaced in your workflow:

- `<REGISTRY_NAME>`
    - Name of the registry that you are pushing to
- `<IMAGE_NAME>`
    - Name of the image that will be pushed to your registry
- `<TAG>`
    - Name of the image tag
- `<WEB_APP_NAME>`
    - Name of the web app that's being deployed

The following variables should be set in the GitHub repository's secrets store:

- `AZURE_CREDENTIALS`
    - Used to authenticate calls to Azure; for more information on setting this secret, please see the [`azure/actions/login`](https://github.com/Azure/actions) action
- `REGISTRY_USERNAME`
    - The username for the container registry; for more information on setting this secret, please see the [`azure/container-actions/docker-login`](https://github.com/Azure/container-actions) action
- `REGISTRY_PASSWORD`
    - The password for the container registry; for more information on setting this secret, please see the [`azure/container-actions/docker-login`](https://github.com/Azure/container-actions) action