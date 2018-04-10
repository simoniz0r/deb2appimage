# deb2appimage

deb2appimage uses deb packages from Debian's and/or Ubuntu's repos to build AppImages based on simple JSON configuration.  The debs are downloaded using `curl` and extracted using `ar x` so that AppImages can be built from any distribution.  The JSON configuration files are setup in a way that they should be easy to understand, yet flexible enough to work with AppImages that require extra tweaking before building.  `~/.cache/deb2appimage` is used as a temporary directory for building AppImages, and is deleted after run.

Contrary to the name, deb2appimage may also be used with other package types as the source for the application (or even the deps), but these files must be downloaded and placed manually in a prerun script.

It will help to make yourself familiar with [Debian's package website](https://www.debian.org/distrib/packages) and [Ubuntu's package website](https://packages.ubuntu.com) for getting the names of dependencies, which architecture they are for, and which version of Debian/Ubuntu we should grab them from.

Dependencies: curl, tar, jq, binutils (jq and binutils are included in [deb2appimage's AppImage](https://github.com/simoniz0r/deb2appimage/releases))
# Arguments

```
--help|-h       Show this output and exit

--json|-j       Specify the location of the json file for building the AppImage (required)

--output|-o     Specify the output directory of the AppImage (optional; $HOME will be used by default)

--quiet|-q      Enable quiet mode

--debug         Enable debug mode

```

Any arguments not listed above will be passed to 'appimagetool' when building the AppImage.

Examples:

```
deb2appimage -j $HOME/my-app.json
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages -q
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages --debug
```
# Setting up the JSON configuration

Example JSON configuration for creating an AppImage of `parsec`:

```
{
    "buildinfo": [
    {
        "prerun": [
            "curl -sL https://s3.amazonaws.com/parsec-build/package/parsec-linux.deb -o ~/.cache/deb2appimage/debs/parsec-linux.deb"
        ],
        "name": "parsec",
        "version": "linux",
        "deps": "libsndio6.1,expat,libexpat1",
        "repoarch": "amd64",
        "distrorepo": "Debian",
        "repoversion": "jessie-backports,jessie,jessie",
        "binarypath": "/usr/bin/parsec",
        "desktoppath": "/usr/share/applications/parsec.desktop",
        "iconpath": "/usr/share/icons/hicolor/256x256/apps/parsec.png",
        "usewrapper": "true",
        "postrun": [
            null
        ]
    }
    ],
    "apprunconf": [
    {
        "setpath": "true",
        "setlibpath": "true",
        "setpythonpath": "false",
        "setpythonhome": "false",
        "setpythondontwritebytecode": "false",
        "setxdgdatadirs": "false",
        "setperllib": "false",
        "setgsettingsschemadir": "false",
        "setqtpluginpath": "false",
        "exec": "/usr/bin/parsec.wrapper"
    }
    ],
    "authors": [
    {
        "type": "Author",
        "author": "parsecgaming",
        "url": "https://parsecgaming.com"
    },
    {
        "type": "AppImage Maintainer",
        "author": "E5ten",
        "url": "https://github.com/E5ten"
    }
    ]
}
```

## buildinfo

**prerun:**

```
"prerun": [
    "curl -sL https://s3.amazonaws.com/parsec-build/package/parsec-linux.deb -o ~/.cache/deb2appimage/debs/parsec-linux.deb"
],
```

Here we download the deb package for parsec using `curl`.  Multiple commands may be used, but complex commands may fail and can to be put in bash script.  If a package for the target application is available in Debian's or Ubuntu's repos and no extra preperation is needed, simply put `null` as the prerun.

**name:**

```
"name": "parsec",
```

Pretty self explanatory; just put the name of the application here.

**version:**

```
"version": "linux",
```

The version of the application.  If no version or `null` is entered, the current date will be used instead.

**deps:**

```
"deps": "libsndio6.1,expat,libexpat1",
```

Dependencies as named on [Debian's package website](https://www.debian.org/distrib/packages) or [Ubuntu's package website](https://packages.ubuntu.com).  Packages must be separated by commas (`package1,package2,package3,package4`).  If a package for the target application is available in Debian's or Ubuntu's repos, you can list the target applicaton's package name here to have it be downloaded and placed in the AppImage automatically.

**repoarch:**

```
"repoarch": "amd64",
```

This specifies the architecture of the dependencies in Debian's repo.  Some packages may be `amd64` and some may be `all`.  If ***all*** of the listed dependencies are ***not*** from the same architecture, then the `repoarch` must be specified for each package in a comma separated list.  Ex:

```
"repoarch": "amd64,all,amd64",
```

**distrorepo:**

```
"distrorepo": "Debian",
```

This specifies which distribution to get packages from.  Either Debian or Ubuntu may be used.

**repoversion:**

```
"repoversion": "jessie-backports,jessie,jessie",
```

This specifies which version of the specified distribution we will be downloading packages from.  We always want to *try* to use the oldest supported version that we can so that AppImages will work on as many distributions as possible.  As with the `repoarch`, if all packages listed as dependencies do ***not*** come from the same version of the specified distribution, then the version must be specified for each package in a comma separated list.

**binarypath:**

```
"binarypath": "/usr/bin/parsec",
```

The path to the binary file of the application after being extracted from the deb package.  To find this, you can extract the deb file manually and look inside of `data.tar.gz`.  For most deb packages, this is usually `/usr/bin/packagename`.

**desktoppath:**

```
"desktoppath": "/usr/share/applications/parsec.desktop",
```

The path to the desktop file of the application after being extracted from the deb package.  If a desktop file is not provided by the application, set this to `null` to have a generic desktop file created for use in the AppImage.

**iconpath:**

```
"iconpath": "/usr/share/icons/hicolor/256x256/apps/parsec.png",
```

The path to the icon file of the application after being extracted fron the deb package.  If no icon file is provided by the application, set this to `null` to have a generic icon downloaded for use in the AppImage.

**usewrapper:**

```
"usewrapper": "true",
```

If this is set to true, the [desktopintegration](https://github.com/simoniz0r/deb2appimage/blob/master/resources/desktopintegration) script will be downloaded and placed in the `binarypath`.  This script povides prompts to ask users if they would like to add the AppImage to their menu for easy access and also provides ways to remove those entries.

If `/usr/bin/myapp` is the `binarypath`, then the `desktopintegration` script will be placed at  `/usr/bin/myapp.wrapper` .  If used, the `exec` line in the `apprunconf` section must be set to launch the wrapper script otherwise the application will just launch normally.

**postrun:**

```
"postrun": [
    null
]
```

The postrun command will be ran after all of the debs have been extracted and placed, and also after `~/.cache/deb2appimage/AppDir` has been prepared.  This can be used to make any necessary changes to those files.  As with `prerun`, multiple commands may be used, and a bash script can be used to for complex commands.  If no `postrun` is needed, put `null` as the `postrun`.

## apprunconf

This section is used to provide more flexability to `AppRun`; not every application needs all of these variables to be set (and some even don't work well with some of them set), so set them to true as needed.

**setlibpath:**

```
"setpath": "true",
```

Adds `/usr/bin` within the AppImage to the user's `PATH`.  This should pretty much always be set to `true` .

**setlibpath:**

```
"setlibpath": "true",
```

Adds library paths within the AppImage to `LD_LIBRARY_PATH`.  Most AppImages will more than likely need this set to `true` .

**setpythonpath:**

```
"setpythonpath": "false",
```

Sets the `PYTHONPATH`.  This should only be used if you are bundling Python in the AppImage.

**setpythonhome:**

```
"setpythonhome": "false",
```

Sets the `PYTHONHOME`.  This should also only be used if you are bundling Python in the AppImage.

**setpythondontwritebytecode:**

```
"setpythondontwritebytecode": "false",
```

Sets `PYTHONDONTWRITEBYTECODE=1` for problems with some AppImages that use Python.  Do not set this unless needed.

**setxdgdatadirs:**

```
"setxdgdatadirs": "false",
```

Adds `/usr/share` within the AppImage to the `XDG_DATA_DIRS` .

**setperllib:**

```
"setperllib": "false",
```

Adds `/usr/share/perl5` within the AppImage to the `PERLLIB` .

**setgsettingsschemadir:**

```
"setgsettingsschemadir": "false",
```

Adds `/usr/share/glib-2.0/schemas` within the AppImage to the `GSETTINGS_SCHEMA_DIR` .

**setqtpluginpath:**

```
"setqtpluginpath": "false",
```

Adds Qt paths within the AppImage to the `QT_PLUGIN_PATH` .

**exec:**

```
"exec": "/usr/bin/parsec.wrapper"
```

This is ***required***.  In most cases, it will be the same as the `binarypath`.  If `usewrapper` is set to `true`, then the path to the wrapper should be inserted here.  If a special script is needed to make the application launch properly, that script may be placed somewhere in `~/.cache/deb2appimage/AppDir` with a `prerun` or `postrun` command/script and then used as the `exec`.
