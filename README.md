# Icinga PHP Thirdparty

This project bundles all 3rd party PHP libraries used by Icinga Web products into one piece,
which can be integrated as library into Icinga Web 2.

## Requirements

* [Icinga Web 2](https://github.com/Icinga/icingaweb2) (>= 2.9)
* PHP (>= 5.6, 7+ recommended)

## Installation

Please download the latest release and install it in one of your configured library paths. The default library
path for Icinga Web 2 installations is: `/usr/share/icinga-php`

Download or clone this repository there (e.g. `/usr/share/icinga-php/vendor`) and you're done.

> **Note**: Do NOT install the GIT master, it will not work! Checking out a
> branch like `stable/0.10.0` or a tag like `v0.10.0` is fine.

### Examples

**Sample Tarball installation**

```sh
INSTALL_PATH="/usr/share/icinga-php/vendor"
INSTALL_VERSION="v0.10.0"
mkdir "$INSTALL_PATH" \
&& wget -q "https://github.com/Icinga/icinga-php-thirdparty/archive/$INSTALL_VERSION.tar.gz" -O - \
   | tar xfz - -C "$INSTALL_PATH" --strip-components 1
```

**Sample GIT installation**

```
INSTALL_PATH="/usr/share/icinga-php/vendor"
INSTALL_VERSION="stable/0.10.0"
git clone https://github.com/Icinga/icinga-php-thirdparty.git "$INSTALL_PATH" --branch "$INSTALL_VERSION"
```
