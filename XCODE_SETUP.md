# Xcode Target Configuration Guide

This guide explains how to configure the Xcode targets for building Apache and PHP-FPM as dependencies of the MacCloud application.

## Overview

The MacCloud build process requires three targets:
1. **Apache** - Aggregate target that builds Apache HTTP Server
2. **PHP** - Aggregate target that builds PHP-FPM
3. **MacCloud** - Main application target (already exists)

## Step 1: Create Apache Build Target

1. Open `MacCloud.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the **+** button at the bottom of the targets list
4. Choose **Cross-platform** → **Aggregate**
5. Name it **Apache**
6. Click **Finish**

### Configure Apache Target

1. Select the **Apache** target
2. Go to **Build Phases** tab
3. Click **+** → **New Run Script Phase**
4. Rename it to **Build Apache**
5. Set the shell to `/bin/bash`
6. Add the following script:

```bash
# Build Apache HTTP Server
cd "${SRCROOT}"
bash Scripts/build-apache.sh
```

7. Expand **Input Files** and add:
   - `$(SRCROOT)/Scripts/build-apache.sh`

8. Expand **Output Files** and add:
   - `$(BUILT_PRODUCTS_DIR)/Apache/bin/httpd`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_proxy.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_proxy_fcgi.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_rewrite.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_mime.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_dir.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_env.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_authz_core.so`
   - `$(BUILT_PRODUCTS_DIR)/Apache/modules/mod_mpm_prefork.so`

## Step 2: Create PHP Build Target

1. Click the **+** button at the bottom of the targets list again
2. Choose **Cross-platform** → **Aggregate**
3. Name it **PHP**
4. Click **Finish**

### Configure PHP Target

1. Select the **PHP** target
2. Go to **Build Phases** tab
3. Click **+** → **New Run Script Phase**
4. Rename it to **Build PHP**
5. Set the shell to `/bin/bash`
6. Add the following script:

```bash
# Build PHP-FPM
cd "${SRCROOT}"
bash Scripts/build-php.sh
```

7. Expand **Input Files** and add:
   - `$(SRCROOT)/Scripts/build-php.sh`

8. Expand **Output Files** and add:
   - `$(BUILT_PRODUCTS_DIR)/PHP/sbin/php-fpm`
   - `$(BUILT_PRODUCTS_DIR)/PHP/bin/php`

## Step 3: Add Dependencies to MacCloud Target

1. Select the **MacCloud** target
2. Go to **Build Phases** tab
3. Locate the **Dependencies** section (if it doesn't exist, click **+** at the top and select **New Dependencies Phase**)
4. Click **+** within the **Dependencies** section
5. Add **Apache** target from the list
6. Click **+** again within the **Dependencies** section
7. Add **PHP** target from the list

This ensures Apache and PHP are built before MacCloud.

## Step 4: Bundle Built Products

We need to copy the built Apache and PHP binaries into the MacCloud app bundle.

### Option A: Using Copy Files Build Phase

1. Select the **MacCloud** target
2. Go to **Build Phases** tab
3. Click **+** → **New Copy Files Phase**
4. Set **Destination** to **Resources**
5. Create subpath: `bin`
6. Click **+** and add:
   - From `$(BUILT_PRODUCTS_DIR)/Apache/bin/httpd`
   - From `$(BUILT_PRODUCTS_DIR)/PHP/sbin/php-fpm`
   - From `$(BUILT_PRODUCTS_DIR)/PHP/bin/php`

7. Create another Copy Files phase for modules:
   - Set **Destination** to **Resources**
   - Create subpath: `modules`
   - Add all Apache modules from `$(BUILT_PRODUCTS_DIR)/Apache/modules/`

### Option B: Using Run Script Phase

Alternatively, add a Run Script phase to MacCloud:

```bash
# Copy Apache and PHP to Resources
APACHE_DIR="${BUILT_PRODUCTS_DIR}/Apache"
PHP_DIR="${BUILT_PRODUCTS_DIR}/PHP"
RESOURCES="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources"

if [ -d "${APACHE_DIR}" ]; then
    echo "Copying Apache to Resources"
    mkdir -p "${RESOURCES}/Apache"
    cp -R "${APACHE_DIR}"/* "${RESOURCES}/Apache/"
fi

if [ -d "${PHP_DIR}" ]; then
    echo "Copying PHP to Resources"
    mkdir -p "${RESOURCES}/PHP"
    cp -R "${PHP_DIR}"/* "${RESOURCES}/PHP/"
fi
```

## Step 5: Update ServerManager to Find Bundled Resources

The `ServerManager.swift` already uses the correct approach to find bundled resources:

```swift
// Get resources path
guard let resourcesPath = Bundle.main.resourcePath else {
    throw NSError(domain: "ServerManager", code: 2, 
                  userInfo: [NSLocalizedDescriptionKey: "Resources path not found"])
}

// For Apache
let apachePath = URL(fileURLWithPath: resourcesPath)
    .appending(component: "Apache/bin/httpd")

// For PHP-FPM
let phpFpmPath = URL(fileURLWithPath: resourcesPath)
    .appending(component: "PHP/sbin/php-fpm")

// For PHP CLI
let phpPath = URL(fileURLWithPath: resourcesPath)
    .appending(component: "PHP/bin/php")

// For Apache modules
let apacheModulesDir = URL(fileURLWithPath: resourcesPath)
    .appending(component: "Apache/modules")
```

This approach works correctly with the resource bundling configured in Step 4.

## Step 6: Create Schemes

### Apache Scheme

1. In Xcode, choose **Product** → **Scheme** → **New Scheme**
2. Name it **Apache**
3. Select the **Apache** target
4. Click **OK**

### PHP Scheme

1. Choose **Product** → **Scheme** → **New Scheme**
2. Name it **PHP**
3. Select the **PHP** target
4. Click **OK**

## Step 7: Build and Test

1. Select the **MacCloud** scheme
2. Choose **Product** → **Build** (⌘B)
3. The build process will:
   - Download and cache Apache and PHP sources (first time only)
   - Compile Apache (~5-10 minutes first time)
   - Compile PHP (~5-10 minutes first time)
   - Build MacCloud application
   - Bundle everything together

4. Run the application (⌘R)
5. Select a Nextcloud version and port
6. Click **Start** to test the deployment

## Troubleshooting

### Build scripts fail

- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Check that build scripts are executable: `chmod +x Scripts/*.sh`
- Verify internet connection for downloads

### Resources not found at runtime

- Check that Copy Files phases are configured correctly
- Verify the resources are in the app bundle:
  ```bash
  ls -R MacCloud.app/Contents/Resources/
  ```
- Update `ServerManager.swift` paths if necessary

### "Permission denied" errors

- Ensure build scripts are executable
- Check that the Run Script phases use `/bin/bash` as the shell

## Build Times

**First build:**
- Apache: ~10 minutes
- PHP: ~10 minutes
- MacCloud: ~1 minute
- **Total: ~21 minutes**

**Subsequent builds (with cache):**
- Apache: ~5 minutes (or skipped if unchanged)
- PHP: ~5 minutes (or skipped if unchanged)
- MacCloud: ~1 minute
- **Total: ~1-11 minutes**

## Clean Build

To perform a completely clean build:

1. Choose **Product** → **Clean Build Folder** (⇧⌘K)
2. Delete `BuildCache/` directory
3. Delete `Build/` directory
4. Rebuild

## See Also

- [Scripts/README.md](../Scripts/README.md) - Build script documentation
- [MacCloud Documentation](../MacCloud/Documentation.docc/MacCloud.md) - Application documentation
