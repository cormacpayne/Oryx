﻿// --------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.
// --------------------------------------------------------------------------------------------

using Microsoft.Oryx.BuildScriptGenerator.Node;
using Microsoft.Oryx.Common;
using Microsoft.Oryx.Tests.Common;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;

namespace Microsoft.Oryx.RuntimeImage.Tests
{
    public class NodeRuntimeImageOtherTests : NodeRuntimeImageTestBase
    {
        public NodeRuntimeImageOtherTests(ITestOutputHelper output, TestTempDirTestFixture testTempDirTestFixture)
            : base(output, testTempDirTestFixture)
        {
        }

        [Theory]
        [InlineData("4.4", "4.4.7")]
        [InlineData("4.5", "4.5.0")]
        [InlineData("4.8", "4.8.7")]
        [InlineData("6.2", "6.2.2")]
        [InlineData("6.6", "6.6.0")]
        [InlineData("6.9", "6.9.5")]
        [InlineData("6.10", "6.10.3")]
        [InlineData("6.11", "6.11.5")]
        [InlineData("8.0", "8.0.0")]
        [InlineData("8.1", "8.1.4")]
        [InlineData("8.2", "8.2.1")]
        [InlineData("8.8", "8.8.1")]
        [InlineData("8.9", "8.9.4")]
        [InlineData("8.11", "8.11.4")]
        [InlineData("8.12", "8.12.0")]
        [InlineData("9.4", "9.4.0")]
        [InlineData("10.1", "10.1.0")]
        [InlineData("10.10", "10.10.0")]
        [InlineData("10.12", "10.12.0")]
        [InlineData("10.14", "10.14.2")]
        [InlineData("12", "12.7.0")]
        public void NodeVersionMatchesImageName(string nodeTag, string nodeVersion)
        {
            // Arrange & Act
            var expectedNodeVersion = "v" + nodeVersion;
            var result = _dockerCli.Run(new DockerRunArguments
            {
                ImageId = $"oryxdevmcr.azurecr.io/public/oryx/node-{nodeTag}:latest",
                CommandToExecuteOnRun = "node",
                CommandArguments = new[] { "--version" }
            });

            // Assert
            var actualOutput = result.StdOut.ReplaceNewLine();
            RunAsserts(
                () =>
                {
                    Assert.True(result.IsSuccess);
                    Assert.Equal(expectedNodeVersion, actualOutput);
                },
                result.GetDebugInfo());
        }

        [Theory]
        // Only version 6 of npm is upgraded, so the following should remain unchanged.
        [InlineData("10.1", "5.6.0")]
        // Make sure the we get the upgraded version of npm in the following cases
        [InlineData("10.10", "6.10.2")]
        [InlineData("10.12", "6.10.2")]
        [InlineData("10.14", "6.10.2")]
        [InlineData("12", "6.10.2")]
        public void HasExpectedNpmVersion(string nodeTag, string expectedNpmVersion)
        {
            // Arrange & Act
            var result = _dockerCli.Run(new DockerRunArguments
            {
                ImageId = $"oryxdevmcr.azurecr.io/public/oryx/node-{nodeTag}:latest",
                CommandToExecuteOnRun = "npm",
                CommandArguments = new[] { "--version" }
            });

            // Assert
            var actualOutput = result.StdOut.ReplaceNewLine();
            RunAsserts(
                () =>
                {
                    Assert.True(result.IsSuccess);
                    Assert.Equal(expectedNpmVersion, actualOutput);
                },
                result.GetDebugInfo());
        }


        [Fact]
        public void GeneratedScript_CanRunStartupScriptsFromAppRoot()
        {
            // Arrange
            const int exitCodeSentinel = 222;
            var appPath = "/tmp/app";
            var script = new ShellScriptBuilder()
                .CreateDirectory(appPath)
                .CreateFile(appPath + "/entry.sh", $"exit {exitCodeSentinel}")
                .AddCommand("oryx -userStartupCommand entry.sh -appPath " + appPath)
                .AddCommand(". ./run.sh") // Source the default output path
                .ToString();

            // Act
            var result = _dockerCli.Run(new DockerRunArguments
            {
                ImageId = "oryxdevmcr.azurecr.io/public/oryx/node-10.14",
                CommandToExecuteOnRun = "/bin/sh",
                CommandArguments = new[] { "-c", script }
            });

            // Assert
            RunAsserts(() => Assert.Equal(result.ExitCode, exitCodeSentinel), result.GetDebugInfo());
        }

        [Fact]
        public void GeneratedScript_CanRunStartupScripts_WithAppInsightsConfigured()
        {
            // Arrange
            const int exitCodeSentinel = 222;
            var appPath = "/tmp/app";
            var aiNodesdkLoaderContent = @"var appInsights = require('applicationinsights');  
                if (process.env.APPINSIGHTS_INSTRUMENTATIONKEY)
                { 
                    try 
                    { 
                       appInsights.setup().start();
                    } catch (e) { 
                       console.error(e); 
                    } 
                }";
            var manifestFileContent = $"'{NodeConstants.InjectedAppInsights}=\"True\"'";

            var script = new ShellScriptBuilder()
                .CreateDirectory(appPath)
                .CreateFile($"{appPath}/entry.sh", $"exit {exitCodeSentinel}")
                .CreateFile($"{appPath}/{FilePaths.BuildManifestFileName}", manifestFileContent)
                .CreateFile($"{appPath}/oryx-appinsightsloader.js", $"\"{aiNodesdkLoaderContent}\"")
                .AddCommand("oryx -userStartupCommand entry.sh -appPath " + appPath)
                .AddCommand(". ./run.sh") // Source the default output path
                .AddStringExistsInFileCheck("export NODE_OPTIONS='--require ./oryx-appinsightsloader.js'", "./run.sh")
                .ToString();

            // Act
            var result = _dockerCli.Run(new DockerRunArguments
            {
                ImageId = "oryxdevmcr.azurecr.io/public/oryx/node-10.14",
                EnvironmentVariables = new List<EnvironmentVariable>
                {
                    new EnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", "asdas")
                },
                CommandToExecuteOnRun = "/bin/sh",
                CommandArguments = new[] { "-c", script }
            });

            // Assert
            RunAsserts(() => Assert.Equal(result.ExitCode, exitCodeSentinel), result.GetDebugInfo());
        }

        [Theory(Skip = "Investigating debugging using pm2")]
        [MemberData(
            nameof(TestValueGenerator.GetNodeVersions_SupportDebugging),
            MemberType = typeof(TestValueGenerator))]
        public async Task RunNodeAppUsingProcessJson_withDebugging(string nodeVersion)
        {
            var appName = "express-process-json";
            var hostDir = Path.Combine(_hostSamplesDir, "nodejs", appName);
            var volume = DockerVolume.CreateMirror(hostDir);
            var dir = volume.ContainerDir;
            int containerDebugPort = 8080;

            var runAppScript = new ShellScriptBuilder()
                .AddCommand($"cd {dir}/app")
                .AddCommand("npm install")
                .AddCommand("cd ..")
                .AddCommand($"oryx -remoteDebug -debugPort={containerDebugPort}")
                .AddCommand("./run.sh")
                .ToString();

            await EndToEndTestHelper.RunAndAssertAppAsync(
                imageName: $"oryxdevmcr.azurecr.io/public/oryx/node-{nodeVersion}",
                output: _output,
                volumes: new List<DockerVolume> { volume },
                environmentVariables: null,
                port: containerDebugPort,
                link: null,
                runCmd: "/bin/sh",
                runArgs: new[] { "-c", runAppScript },
                assertAction: async (hostPort) =>
                {
                    var data = await _httpClient.GetStringAsync($"http://localhost:{hostPort}/");
                    Assert.Contains("Say It Again", data);
                },
                dockerCli: _dockerCli);

        }
    }
}
