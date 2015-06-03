# Library - Meta data library

## Version Perl on Moarvm

```
This is perl6 version 2015.01-77-gd320f00 built on MoarVM version 2015.01-21-g4ee4925
```

## Description

Programs and modules to maintain a library of metadata of documents.

```
lib/Library.pm6
lib/Library/Configuration.pm6
lib/Library/File-metadata-manager.pm6

bin/install-mimetypes.pl6
bin/store-file-metadata.pl6
```

## Documentation

* ./doc/Library.mm, Freemind mindmapping.
* ./doc/Docbook-docs/library-requirements-setup.pdf, Setup

## Bugs

Still in a 'omega' state. So bugs come and go.

## Changes

0.3.0
  * Added keyword processing to store-file-metadata.pl6 and
    File-metadata-manager.pm6
  * Install-mimetypes.pl6 changed to store fileext as an array of extensions.
0.2.1
  * Bugfixes in File-metadata-manager
  * Bugfixes updating entries.
0.2.0
  * Added install-mimetypes.pl6
0.1.1
  * Modified modules and finished store-file-metadata.pl6
0.1.0
  * Creation date. Lots of thinking.

## Author
  M.Timmerman
  Github account MARTIMM

## License

Released under [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
