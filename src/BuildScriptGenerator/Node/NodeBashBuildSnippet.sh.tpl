echo
echo "Using Node version:"
node --version
echo
{{ PackageInstallerVersionCommand }}

{{ if ConfigureYarnCache }}
# Yarn config is per user, and since the build might run with a non-root account, we make sure
# the yarn cache is set on every build.
YARN_CACHE_DIR=/usr/local/share/yarn-cache
if [ -d $YARN_CACHE_DIR ]
then
	echo
    echo "Configuring Yarn cache folder..."
    yarn config set cache-folder $YARN_CACHE_DIR
fi
{{ end }}

zippedModulesFileName={{ CompressedNodeModulesFileName }}
allModulesDirName=__oryx_all_node_modules
prodModulesDirName=__oryx_prod_node_modules
copyOnlyProdModulesToOutput=false

PruneDevDependencies={{ PruneDevDependencies }}
# We want separate folders for prod modules only when the package.json has separate dependencies
hasProductionOnlyDependencies="{{ HasProductionOnlyDependencies }}"
if [ "$SOURCE_DIR" != "$DESTINATION_DIR" ] && \
   [ "$PruneDevDependencies" == "true" ] && \
   [ "$hasProductionOnlyDependencies" == "true" ]
then
	copyOnlyProdModulesToOutput=true
fi

# if node modules exist separately for dev & prod (like from an earlier build),
# rename the folders back appropriately for the current build
if [ -d "$allModulesDirName" ]
then
	echo
	echo "Found existing folder '$SOURCE_DIR/$allModulesDirName'."
	echo "Copying modules from '$SOURCE_DIR/$allModulesDirName' to '$SOURCE_DIR/node_modules'..."
	cd "$SOURCE_DIR"
	mkdir -p node_modules
	rsync -rtE --links "$allModulesDirName/" node_modules
fi

if [ "$copyOnlyProdModulesToOutput" == "true" ]
then
	# Delete existing prod modules folder so that we do not publish
	# any unused modules to final destination directory.
	if [ -d "$prodModulesDirName" ]; then
		echo "Found existing '$SOURCE_DIR/$prodModulesDirName'. Deleting it..."
		rm -rf "$prodModulesDirName"
	fi

	mkdir -p "$prodModulesDirName"
	cd "$prodModulesDirName"

	if [ -f "$SOURCE_DIR/package.json" ]; then
		cp -f "$SOURCE_DIR/package.json" .
	fi

	if [ -f "$SOURCE_DIR/package-lock.json" ]; then
		cp -f "$SOURCE_DIR/package-lock.json" .
	fi

	if [ -f "$SOURCE_DIR/yarn.lock" ]; then
		cp -f "$SOURCE_DIR/yarn.lock" .
	fi

	echo
	echo "Installing production dependencies in '$SOURCE_DIR/$prodModulesDirName'..."
	echo
	echo "Running '{{ ProductionOnlyPackageInstallCommand }}'..."
	echo
	{{ ProductionOnlyPackageInstallCommand }}

	echo
	echo "Copying production dependencies from '$SOURCE_DIR/$prodModulesDirName' to '$SOURCE_DIR/node_modules'..."
	START_TIME=$SECONDS
	rsync -rtE --links "node_modules/" "$SOURCE_DIR/node_modules"
	ELAPSED_TIME=$(($SECONDS - $START_TIME))
	echo "Done in $ELAPSED_TIME sec(s)."
fi

cd "$SOURCE_DIR"

echo
echo "Running '{{ PackageInstallCommand }}'..."
echo
{{ PackageInstallCommand }}

{{ if NpmRunBuildCommand | IsNotBlank }}
echo
echo "Running '{{ NpmRunBuildCommand }}'..."
echo
{{ NpmRunBuildCommand }}
{{ end }}

{{ if NpmRunBuildAzureCommand | IsNotBlank }}
echo
echo "Running '{{ NpmRunBuildAzureCommand }}'..."
echo
{{ NpmRunBuildAzureCommand }}
{{ end }}

{{ if RunNpmPack }}
echo
echo "Running custom packaging scripts that might exist..."
echo
npm run package || true
echo
echo "Running 'npm pack'..."
echo
npm pack
{{ end }}

if [ "$copyOnlyProdModulesToOutput" == "true" ]
then
	echo
	echo "Copy '$SOURCE_DIR/node_modules' with all dependencies to '$SOURCE_DIR/$allModulesDirName'..."
	rsync -rtE --links "node_modules/" "$allModulesDirName" --delete

	echo
	echo "Copying production dependencies from '$SOURCE_DIR/$prodModulesDirName/node_modules' to '$SOURCE_DIR/node_modules'..."
	rsync -rtE --links "$prodModulesDirName/node_modules/" node_modules --delete
fi

{{ if CompressNodeModulesCommand | IsNotBlank }}
if [ "$SOURCE_DIR" != "$DESTINATION_DIR" ]
then
	if [ -f $zippedModulesFileName ]; then
		echo
		echo "File '$zippedModulesFileName' already exists under '$SOURCE_DIR'. Deleting it..."
		rm -f $zippedModulesFileName
	fi

	if [ -d node_modules ]
	then
		echo
		echo Zipping existing 'node_modules' folder...
		START_TIME=$SECONDS
		# Make the contents of the node_modules folder appear in the zip file, not the folder itself
		cd node_modules
		{{ CompressNodeModulesCommand }} ../$zippedModulesFileName .
		ELAPSED_TIME=$(($SECONDS - $START_TIME))
		echo "Done in $ELAPSED_TIME sec(s)."
	fi
fi
{{ end }}
