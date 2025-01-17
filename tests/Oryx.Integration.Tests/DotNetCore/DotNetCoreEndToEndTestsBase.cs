﻿// --------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.
// --------------------------------------------------------------------------------------------

using Microsoft.Oryx.Tests.Common;
using System.IO;
using Xunit.Abstractions;

namespace Microsoft.Oryx.Integration.Tests
{
    public abstract class DotNetCoreEndToEndTestsBase : PlatformEndToEndTestsBase
    {
        protected const int ContainerPort = 3000;
        protected const string NetCoreApp11WebApp = "NetCoreApp11WebApp";
        protected const string NetCoreApp21WebApp = "NetCoreApp21.WebApp";
        protected const string NetCoreApp22WebApp = "NetCoreApp22WebApp";
        protected const string NetCoreApp30WebApp = "NetCoreApp30.WebApp";
        protected const string NetCoreApp30MvcApp = "NetCoreApp30.MvcApp";
        protected const string DefaultWebApp = "DefaultWebApp";
        protected const string NetCoreApp21MultiProjectApp = "NetCoreApp21MultiProjectApp";
        protected const string DefaultStartupFilePath = "./run.sh";

        public DotNetCoreEndToEndTestsBase(ITestOutputHelper output, TestTempDirTestFixture testTempDirTestFixture)
            : base(output, testTempDirTestFixture)
        {
        }

        protected DockerVolume CreateDefaultWebAppVolume()
        {
            return DockerVolume.CreateMirror(Path.Combine(_hostSamplesDir, "DotNetCore", DefaultWebApp));
        }
    }
}