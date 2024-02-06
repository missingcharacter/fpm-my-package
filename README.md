# Build RPMs/DEBs using Effing Package Manager

Note: Quick and dirty script

## Dependencies

- git
- curl
- docker
- [keyring](https://github.com/jaraco/keyring)
- [parallel](https://www.gnu.org/software/parallel/)
  - MacOS: `parallel` can be installed via `brew`

## Run it like this

```shell
./build.sh
```

## How your `packages/file` should look like

**Note**: There are single quotes, these are important

```text
NAME='<Name of the package>'
VERSION='<Version of the package to download>'
RELEASE='<Release or iteration of this package>'
SOURCE='<URL with the binary in zip, tar, tar.gz or gzip format>'
VENDOR='<Name of the vendor/creator of this package>'
MAINTAINER='<Email address of the team maintaining this package>'
LICENSE='<License of the package. E.g. MIT, GPL>'
DESCRIPTION='<one line description of the package and what it does>'
# You must set Debian and RPM dependencies or neither.
# Depdencies must be comma separated. Examples below:
DEB_DEPENDENCIES='tshark > 1.10.2,python3-virtualenv'
RPM_DEPENDENCIES='wireshark > 1.10.2,python36-virtualenv'
```

## Where will packages appear?

### RPMs

```shell
./tmp-files/RPM
```

### DEBs

```shell
./tmp-files/DEB
```
