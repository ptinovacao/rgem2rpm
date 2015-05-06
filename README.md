## rgem2rpm

rgem2rpm is a gem to make a rpm package out of a .gem file. The intent
is to provide a minimal and flexible way to easily package a gem into an
rpm. With this done you can use all the facilities provided by Linux Red Hat
systems to manage your ruby software.

rgem2rpm provides a sane set of out-of-the box defaults that should allow most
gem files to assemble and Just Work.

## Getting Started

1. Install the gem: `gem install rgem2rpm`
2. Run the command: `rgem2rpm <gemfilename>`
3. The RPM file will be cretated in the current directory

## Usage

rgem2rpm's **rgem2rpm** command is an executable that provides the capability to 
assemble rpm's using gem files. Run the next command to get help:

    $ rgem2rpm --help
    Usage: rgem2rpm [options] [gemfilename]
        options:
                        --template TEMPLATE          RPM spec template.
                        --release RELEASE            RPM spec release.
                        --group GROUP                RPM spec group.
                        --osuser OSUSER              OS install user.
                        --osgroup OSGROUP            OS install group.
                        --installdir INSTALLDIR      OS install directory.
                        --jruby                      Build RPM to jruby platform (only when gem has executables).
                        --help                       Show this message.
                        --version                    Show version.
## License

rgem2rpm is released under the [MIT License](http://www.opensource.org/licenses/MIT).
