# Build RPMs/DEBs using Effing Package Manager

Note: Quick and dirty script

## Dependencies

- git
- curl
- docker
- [gum](https://github.com/charmbracelet/gum)
- [keyring](https://github.com/jaraco/keyring)
- [parallel](https://www.gnu.org/software/parallel/)
  - MacOS: `parallel` can be installed via `brew`
- [yq](https://github.com/mikefarah/yq)

## Run it like this

```shell
./scripts/main.sh
```

## How your `packages.yaml` should look like

```yaml
packages:
  - name: <Name of the package>
    version: <Version of the package to download>
    release: <Release or iteration of this package>
    noarch: <Optional boolean, when `true` tells fpm to use `-a all`>
    source: <URL with the binary in zip, tar, tar.gz or gzip format>
    vendor: <Name of the vendor/creator of this package>
    maintainer: <Email address of the team maintaining this package>
    license: <License of the package. E.g. MIT, GPL>
    description: <one line description of the package and what it does>
    deb_dependencies: <Optional, list of strings with debian dependencies>
    rpm_dependencies: <Optional, list of strings with rpm dependencies>
    deb_flags: <Optional, list of deb specific fpm flags>
    rpm_flags: <Optional, list of rpm specific fpm flags>
    files_flags: <List of file searching fpm flags>
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
