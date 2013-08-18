##DCD

###Yet Another Fast Change Directory based on the honorable NCD

DCD was modeled after Norton Change Directory (NCD). NCD appeared first in The Norton Utilities, Release 4, for DOS in 1987, published by Peter Norton. NCD was written by Brad Kingsbury.

This is a very old program I wrote for MS-DOS, and now I ported it to Mac OS X using FPC/Lazarus. 
Maybe in the near future I'll make it multi-platform.

###INSTALLATION

* Compile it with fpc (http://www.freepascal.org):

```
$ fpc dcd.pas
```

* Copy it to /usr/local/bin

```
$ cp dcd /usr/local/bin
```

* Add this to your ~/.profile:

```
dcd ()
{
    new_path="$(/usr/local/bin/dcd ${@})";
    case $? in
        0) echo -e "\\033[31m${new_path}\\033[0m";
           cd "${new_path}";
           ;;
        1) return
           ;;
        2) echo "dcd: directory '${@}' not found";
           echo "Try \`dcd -r\` to update db.";
           ;;
    esac
}
```