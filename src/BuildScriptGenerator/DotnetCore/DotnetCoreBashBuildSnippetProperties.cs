﻿// --------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.
// --------------------------------------------------------------------------------------------

namespace Microsoft.Oryx.BuildScriptGenerator.DotnetCore
{
    /// <summary>
    /// Build script template for DotnetCore in Bash.
    /// </summary>
    public class DotNetCoreBashBuildSnippetProperties
    {
        public DotNetCoreBashBuildSnippetProperties(
            string projectFile,
            string publishDirectory)
        {
            ProjectFile = projectFile;
            PublishDirectory = publishDirectory;
        }

        public string ProjectFile { get; set; }

        public string PublishDirectory { get; set; }
    }
}