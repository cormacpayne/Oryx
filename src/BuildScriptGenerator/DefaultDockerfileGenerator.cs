﻿// --------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.
// --------------------------------------------------------------------------------------------

using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.Logging;
using Microsoft.Oryx.BuildScriptGenerator.Exceptions;
using Microsoft.Oryx.BuildScriptGenerator.Node;
using Microsoft.Oryx.BuildScriptGenerator.Resources;

namespace Microsoft.Oryx.BuildScriptGenerator
{
    internal class DefaultDockerfileGenerator : IDockerfileGenerator
    {
        private readonly ICompatiblePlatformDetector _platformDetector;
        private readonly ILogger<DefaultDockerfileGenerator> _logger;

        private readonly IDictionary<string, IList<string>> _slimPlatformVersions =
            new Dictionary<string, IList<string>>()
            {
                { "dotnetcore", new List<string>() { "2.1" } },
                { "node", new List<string>() { "8", "10", "12" } },
                { "python", new List<string>() { "3.7", "3.8" } },
            };

        public DefaultDockerfileGenerator(
            ICompatiblePlatformDetector platformDetector,
            ILogger<DefaultDockerfileGenerator> logger)
        {
            _platformDetector = platformDetector;
            _logger = logger;
        }

        public string GenerateDockerfile(DockerfileContext ctx)
        {
            var buildImageTag = "slim";
            var runImage = string.Empty;
            var runImageTag = string.Empty;
            var compatiblePlatforms = GetCompatiblePlatforms(ctx);
            if (!compatiblePlatforms.Any())
            {
                throw new UnsupportedLanguageException(Labels.UnableToDetectLanguageMessage);
            }

            foreach (var platformAndVersion in compatiblePlatforms)
            {
                var platform = platformAndVersion.Key;
                var version = platformAndVersion.Value;
                if (!_slimPlatformVersions.ContainsKey(platform.Name) ||
                    !_slimPlatformVersions[platform.Name].Any(v => version.StartsWith(v)))
                {
                    buildImageTag = "latest";
                }

                runImage = platform.Name == "dotnet" ? "dotnetcore" : platform.Name;
                runImageTag = GenerateRuntimeTag(version);
            }

            var properties = new DockerfileProperties()
            {
                RuntimeImageName = runImage,
                RuntimeImageTag = runImageTag,
                BuildImageTag = buildImageTag,
            };

            return TemplateHelper.Render(
                TemplateHelper.TemplateResource.Dockerfile,
                properties,
                _logger);
        }

        private IDictionary<IProgrammingPlatform, string> GetCompatiblePlatforms(DockerfileContext ctx)
        {
            return _platformDetector.GetCompatiblePlatforms(ctx, ctx.Platform, ctx.PlatformVersion);
        }

        private bool IsEnabledForMultiPlatformBuild(IProgrammingPlatform platform, DockerfileContext ctx)
        {
            if (ctx.DisableMultiPlatformBuild)
            {
                return false;
            }

            return platform.IsEnabledForMultiPlatformBuild(ctx);
        }

        /// <summary>
        /// For runtime images, the tag follows the format `{MAJOR}.{MINOR}`, so we need to correctly format the
        /// version that is returned from the detector to ensure we are pulling from a valid tag.
        /// </summary>
        /// <param name="version">The version of the platform returned from the detector.</param>
        /// <returns>A formatted version tag to pull the runtime image from.</returns>
        private string GenerateRuntimeTag(string version)
        {
            var split = version.Split('.');
            if (split.Length < 3)
            {
                return version;
            }

            return $"{split[0]}.{split[1]}";
        }
    }
}
