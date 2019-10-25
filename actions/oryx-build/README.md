# Oryx Build - GitHub Action

## About

This GitHub Action will use the `oryx build` command to generate a build script for the given repository, and then run that script ion order to build the web app. The action returns the path to the artifacts from the build that can then be used for testing, or deployed to Azure App Service.

## Usage

The Oryx Build GitHub Action can be included in a repository's workflow by using `microsoft/oryx/actions/oryx-build@master`.

The following parameters can be set as a part of the action:

- `sourceDirectory`
    - Source directory of the repository; if no value is provided for this, the current working directory in the container is set as the source directory.
- `outputDirectory`
    - Path to the Dockerfile that will be written to; if no value is provided for this, the output will be copied to the source directory.
- `platform`
    - Programming platform used to build the web app; if no value is provided for this, Oryx will detect the platform. The supported values are "dotnet", "nodejs", "php" and "python".
- `platformVersion`
    - Version of the programming platform used to build the web app; if no value is provided for this, Oryx will detect the version.

The result of the action is the following properties:

- `outputDirectory`
    - Path to the build artifacts (see `outputDirectory` parameter to the action)
- `zipPath`
    - Path to the `.zip` file containing the build artifacts

These properties can be referenced in the workflow `.yaml` by calling `{{ steps.id.outputs.<property> }}`, where `id` is the ID of the step calling this Oryx Build action.

## Examples

### Building a web app

The following is a sample of building a web app in a repository:

```
steps:
  - name: Cloning repository to container
    uses: actions/checkout@v1

  - name: Running Oryx to build web app
    uses: microsoft/oryx/actions/oryx-build@master
    id: oryx
```

### Deploying an Azure Web App

The following is an end-to-end sample of building a web app in a repository and then deploying it to Azure:

```
steps:
  - name: Cloning repository to container
    uses: actions/checkout@v1

  - name: Running Oryx to build web app
    uses: microsoft/oryx/actions/oryx-build@master
    id: oryx

  - name: Deploying web app to Azure
    uses: azure/appservice-actions/webapp@master
    with:
      app-name: <WEB_APP_NAME>
      package: {{ steps.oryx.outputs.zipPath }}
      publish-profile: ${{ secrets.AZURE_WEB_APP_PUBLISH_PROFILE }}
```

The following variable should be replaced in your workflow:

- `<WEB_APP_NAME>`
    - Name of the web app that's being deployed

The following variable should be set in the GitHub repository's secrets store:

- `AZURE_WEB_APP_PUBLISH_PROFILE`
    - The contents of the publish profile file (`.publishsettings`) used to deploy the web app; for more information on setting this secret, please see the [`azure/appservice-actions/webapp`](https://github.com/Azure/appservice-actions) action