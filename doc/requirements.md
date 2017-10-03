# Library Requirements and Design

# Abstract

This is a small document describing the wishes and requirements which are needed for this project. It also describes the needed functionality, programs and structures.

[TOC]

# Introduction

Purpose of this project is to store meta information of objects. An object can be any type of document, url, project, contact etc. This information is about the object in question and is meant to give some extra meaning to it. For example when labels or keywords are used in the meta data, it is possible to group objects together when a value of the key or label is the same over all the objects of the same group. This information must be independent of the current location (if any) of an object.

Objects are found anywhere locally or externally of a computer and are only described by system. Its content will never be saved in the database nor changed. Although external objects may be copied to the local system because it can be interesting like books and pictures. Every object should always have a type. Some can be automatically assigned e.g. for files, directories and websites. Others need help from the user of the system. E.g. a project description is not an object found on disk but is mostly a group of files together with other objects such as a server, websites or devices.

A short list of possible objects:
* Files are objects with a content. E.g. text, image, xml, scripts, archives and code. For most of these type objects there are viewers and editors available. Besides its content like mp3, svg etc, a language can be specified e.g. C, Perl or Markdown. Also its purpose is important. Most of the time these can be resource files or configuration files. Examples of these are; rdf, html, vCard, calendar etc.
The files can be found locally, other computers, local or external servers or in a cloud. While the purpose of the project is not to manage files, it must be possible to download files for offline use or archiving. The external document might be removed from servers as time passes by, so that is another reason to download. The content can be retrieved using various protocols among which http, ssh, ftp, smtp and ldap. Use of specific APIs to access servers are also possible to implement.

* Directories are containers for files which are grouped together.

* Servers are objects of which the meta data can describe its services.


## Implementation

This software package should come with several modules and programs to         suit several ways of accessing the data. There is also an issue of making the software platform independent so everyone can be happy with it.

* **The programming language**. The first item to think about is the choice of programming language. A scripting language would be a proper choice because these languages have a higher level of coding and will access the underlaying system in a platform independent way. The language I want to choose is perl6.

* The second approach is to use a browser to do the work. There we can use **html5**, **css3** and **javascript** and libraries. There is also a server side scripting language needed which can be any of **perl6**, **perl 5** or **javascript (nodejs)**

* **The storage method**.
  * **Storage**. The name of the database and the names of the collections

## Ideas to implement

Here a list of thoughts will show what I like to include in this system. It does not mention if this will be feasible or not. That will come in a later part where things like dependencies will be investigated.

* Files can be located anywhere. This system will not manage documents. It will manage information about the documents. So it is not necessary to store them somewhere. It is however nice when it can detect duplicates when another document is entered by the user. This duplication can be caused by backups or archives.

* A file can only be found on the local disk or externally connected disk (directly or network). There are however other places where documents can be found such as network attached storage, media stores or on web servers. In the same process as adding the meta data to the database these remote documents might be copied to local store to prevent disappearing from the net when you find it still important.

* Not only files. A file on a disk is pointed to by a name and path and a drive on windows. There are other ways to get to a document like using a unified resource locator (abbrev[URL]).

* Use of mimetypes and document suffixes. Mimetypes are an important type of description method to show what can be done with the document. The list can also be used to start native applications to process a particular document. According to their mimetype of the document it mostly has also a proper suffix such as emphasis[.txt] or emphasis[.html]. See also citation[MIMETYPES].
A few examples are
  * **text/plain:** This is simple text format mostly created with simple text editors.
  * **audio/mpeg3:** A type of audio file with document suffix of **mp3**.

* Use of protocols. Protocols are used to get to the document before processing it. E.g. the emphasis[http] protocol is used to get a webpage from a site on the network and emphasis[file] is used often to get a document from the local filesystem. See also citation[MIMETYPES].
The following list is a series of protocols which might be supported.
  * **file:** Protocol to get documents from a filesystem.
  * **http** and **https:** Protocols to get webpage documents from a web   server.
  * **ftp:** File transfer protocol.


# Requirements

## Environment

First some specifications to define the environment and products needed to
run the programs.

* LIBRARY-CONFIG. Environment variable holding the root directory location on disk where the library program data is stored. Here the program can store pid info of background programs and log files. Also the configuration files are stored here. If the database server is local, its data should come here too.

* Configuration file. This file holds information on how to connect to the mongodb database server and what database and collections to use amongst others.

* Database. The data needed to save for each object can be diverse and varying depending on its type. Sometimes, there are only a few fields, on other times a lot of extra fields are added. They might also have different field names. A choice is made, based on this phenomenon to use a document based NoSQL database **MongoDB**. While developing, a standalone server is setup but can later become a set of servers in a replica set which run on several machines.

* An important aspect of data are relations between objects. Here things like Rdf and Tupple comes into play. To describe those in a database another NoSQL typed database should be used also. An example of this is **Neo4j** which is a network database.

### Simplified view from user

Two diagrams to show how the user interacts with the system. The important points are;
* The user changes the configuration using an editor editor or by using other components of the system.
* The system starts the gathering processes.
* The gathering processes use the configuration to know what to search for. Then the data is examined to set default meta information and sends it to the database. These processes are also checking for possible changes in the file system like renamed or moved files.
* The user is able to modify the meta data by adding keys or modify those keys.

```plantuml

title User view to the system

actor user

file cfg as "config\nfile"

component gather as "gather\nservices"
component dmeta as "meta\ndefault"
component mmeta as "meta\nmodify"
component imeta as "meta\ninfo"

database mdb as "MongoDB"
node mdbs as "db\nserver"
mdbs -- mdb


user --> cfg
user -> mmeta

cfg -> gather
gather -> dmeta
mmeta <--> mdbs
dmeta <-> mdbs

imeta <-- mdbs
user <-- imeta

```

```plantuml

title System view to the system

actor system

file cfg as "config\nfile"

file lfile as "local\nfile"
file efile as "external\nfile"
folder lfolder as "local\ndirectory"
folder efolder as "external\ndirectory"


component gl as "gather\nlocal"
component ge as "gather\nexternal"

component store as "meta\ndefault"

database mdb as "MongoDB"
cloud " " as internet1
cloud " " as internet2
node es as "external\nserver"
node mdbs as "db\nserver"


lfolder - lfile
efolder - efile
es <-- efolder

mdbs - mdb

system .> ge
system ..> gl

cfg --> gl

gl <-- lfolder
gl <-> store
store <-> internet2
internet2 <-> mdbs


ge <-- cfg
internet1 <- es
ge <- internet1
ge <--> store

```

## General specifications of an object

Objects found anywhere are only described by system. Its content will never be saved in the database nor changed. External objects may be copied to the local system. Every object should always have a type. Some can be automatically assigned e.g. for files and directories. Others need help from the user of the system. E.g. a project description is not an object found on disk but is mostly a group of files together with other objects such as a server, websites or devices.

* There are three types of information to be stored
  * Automatically found data such as ownership, path to document and volume name in case of documents
  * Sha1 generated numbers based on the content of the object for searching and comparing. This can help to find e.g. a renamed file and attach the meta information already in the database. Only the general info need to be modified. Actions which could take place are
    * Move a file from one place to another on the file system.
    * Rename a file
    * Rename and move in one operation
    * Modify its contents
    * Modify ownership or access rights
    * Remove the file
    * Modify URI
  * Explicitly provided information like keywords, name and address of owner, project name etcetera.

* Store, update or delete meta information in the database. This is
for automatically retrieved or explicitly provided information.

* Search meta information using exact match or regular expressions on
any part of the meta information.

* Displaying output from searches by commandline program or by webpage
in a browser.

* Actions can be started using mimetypes also stored as metadata.

* Mimetypes are an important type of description method to show
what can be done with the document. The list can also be used
to start native applications to process a particular document.
According to their mimetype of the document it mostly has also
a proper suffix such as `.txt` or `.html`. See
also [MIMETYPES]. A few examples are:
  * **text/plain**: This is simple text format mostly created with simple text editors.
  * **audio/mpeg3**: A type of audio file with document suffix of `mp3`.
* General meta information to store. Besides the list below, users must be capable to add new metadata attributes.

### Document objects

* This system will not manage documents. It will manage information
about the documents. Location of the document is stored as part
of this information. It is however nice when it can detect
duplicates when another document is entered by the user. This
duplication can be caused by backups or archives.

* A document can be found on the local disk, externally connected
disk, other computers and network devices such as network attached
storage (**NAS**), media stores or on web servers.

* As a side effect of locating documents on e.g. external servers,
these documents can be stored on disk for offline use.

### URL Website information

A file on a disk is pointed to by a name and path and a alse a drive when
working on windows. There are other ways to get to a document like
using a unified resource locator (**URL**).

Protocols are used to get to the document before processing it.
E.g. the **http** protocol is used to get a web page from a
site on the network and **file** is used often to get a
document from the local file system. See also [MIMETYPES].
The following list is a series of protocols which might be supported.
* file: Protocol to get documents from a filesystem.
* http and https: Protocols to get web page documents from a web server.
* ftp: File transfer protocol.

Also here, as a side effect of locating documents on external servers,
these documents can be stored on disk for offline use.

### Other information
Other information besides meta information can be imported such as
agendas and contact information.

* Contact information can be imported from vcard files. This data can
also be linked to other meta items.
* Relations between objects are stored in the database using directions
of Topic Maps ($abbrev[TM]). Import and export are done via
* XML as XTM or encapsulated in RDF.
* Web Ontology Language OWL. Relations defined above with TM can be tested using a reasoner reading this ontology information. The rules for this language can be imported and exported as OWL/XML documents or as RDF.


## Meta data

What information do we want to store. Well, it must be something about the object. Furthermore, keys under which a document might be categorized. A description will sometimes help. There are on the internet numerous descriptions available of known items like books and movies. Besides the list below, users and programs must be capable to add new meta data attributes.

### File meta data
* **name**, The name of the file.
* **content-type**, The extention of the file which mostly says something about its contents. E.g. **c** for c code files and **jpg** for a specific type of image.
* **path**. Complete and absolute path to the file
* **exists**. If the file exists it is True, otherwise it is False. This field is useful because the meta data should not be thrown away when a file gets deleted or renamed. There are methods to find the information back of files entered anew and then adjust the meta data in the database.
* **content-sha1**. The content of a file is not stored in the database. To compare files in the database, a sha1 key is made from its content and stored instead.

### Directory meta data
* **name**. Unique name.
* **path**. complete and absolute path to the document.

### Web pages
* **uri**. complete path to the web page.
* **name**. Last component of the path if any. Cannot assume it will be index.html as a default.
* **path**. Part after the domain name till just before the name part.

### User meta data
Separate documents can be inserted in the database to describe whatever is interesting to the user. This independent document must have a meta type field.
It might also need its own collection.

Otherwise it is a sub document in any of the above documents for File, Directory or Web meta data. In that case no meta type field is added to this subdocument. Fields are free to be set. Below are some examples
* **description**. A description.
* **author**. A set of data like name and surname, address and email etc.
* **datetime**. Date and time of retrieval, date and time of modification or current date and time.
* **purpose**. The purpose of an object.
* **tag-list**. A list of keywords.

This information will typically be set by a gui program where users can input or modify there data.

### Program meta data
This type of data is essentially the same as the user meta data but typically set by a program. Examples are calendar or contact information. This can be a independent document or sub-document.

### Relationship meta data
This is meant to make relationships between the meta data documents. The question is, should it be with MongoDB (document based) or Neo4j (network/node based). See below.

### All types of meta data
* **meta-type**. This is the type of the meta data. This is 'File', 'Directory' etc.
* **servername**. This can be a hostname or a domainname. For files and directories it is a hostname of the computer where the file or directory is found. For websites this the name of the server.
* **user-meta**. Optional sub-document of user information specific to the object where it is the sub-document from.
* **program-meta**. Optional sub-document of program information specific to the object where it is the sub-document from.





## Summary of fields

### Generic meta data fields

* name: Name of the object
* description: Description of the object
* author: A set of data like name and surname, address and email etc.
* datetime: Date and time of retrieval, date and time of modification or current date and time.
* object-type: Type of object such as document, directory or url.
* keys: A list of keywords under which the object can be categorized.
* uri: Every object must have a uri which can be used to compare things

### Document meta data fields derived from files and directories

* full-name: Complete and absolute path to the document
* file-name: Name of document object
* extension: Extension of the document. This is empty for directory documents.
* accessed: Date and time of last access.
* modified: Date and time of last modification.
* changed: Date and time of last change.
* size: Size of document.
* location: Place where document is downloaded

### Web meta information to store.

* protocol: Name of used protocol
* server: Name of server
* path: Path of document
* arguments: key-value pairs found on the url
* location: Place where document is downloaded

```erd {cmd=true output="html" hide=true args=["-i", "$input_file", "-f", "svg"]}

title {
  label: "Collections and sub documents. Types are perl6 types",
  size: "18"
}

header {size: "12"}
entity {bgcolor: "#fafaf8", size: "10"}
relationship {size: "9"}

[FileMeta]
*metaType {label: "ObjectType, ¬ ∅"}
*name {label: "Str, ¬ ∅"}
contentType {label: "Str"}
path {label: "Str, ¬ ∅"}
exists {label: "Bool, ¬ ∅"}
contentSha1 {label: "Str, ¬ ∅"}

[DirMeta]
*metaType {label: "ObjectType, ¬ ∅"}
*name {label: "Str, ¬ ∅"}
path {label: "Str, ¬ ∅"}
exists {label: "Bool, ¬ ∅"}

[WebMeta]
*metaType {label: "ObjectType, ¬ ∅"}
uri {label: "Str, ¬ ∅"}
protocol {label: "Str, ¬ ∅"}
server {label: "Str, ¬ ∅"}
path {label: "Str, ¬ ∅"}
arguments {label: "Str, ¬ ∅"}
location {label: "Str, ¬ ∅"}

[UserMeta]
*metaType {label: "ObjectType, ¬ ∅"}
anyitem

[ProgramMeta]
*metaType {label: "ObjectType, ¬ ∅"}
anyitem

# Each relationship must be between exactly two entities, which need not
# be distinct. Each entity in the relationship has exactly one of four
# possible cardinalities:
#
# Cardinality    Syntax
# 0 or 1         ?
# exactly 1      1
# 0 or more      *
# 1 or more      +
FileMeta 1--? WebMeta
FileMeta 1--* UserMeta
FileMeta 1--* ProgramMeta
DirMeta 1--? UserMeta
#ProgramMeta 1--? WebMeta
ProgramMeta 1--? UserMeta
WebMeta 1--? UserMeta
```

## Database and collections

The database is by default called **Library** and the meta data of each object in documents stored in a collection called **Metadata**. These names can be defined differently using a configuration file which is explained later.

An extra collection is used to find some control documents. By default called **Metaconfig**. The following documents can be found there;
* To skip objects a single document is specified with the fields;
  * **config-type**. Type field with value **skip-filter**.
  * **fileskip**. Array of values to check on filename. These can be perl6 regular expressions. There is a skiplist for directories and one for files
  * **dirskip**. Skip list for directories.
* To filter tag fields also a single doc is used;
  * **config-type**. Type field with value **tag-filter**.
  * **tags**. Array of values to filter the tags with.

## Configuration


# Implementation

This software package should come with several modules and programs to
suit several ways of accessing the data. There is also an issue of
making the software platform independent so everyone can be happy with
it.

## The programming language

The first item to think about is the choice of programming
language. A scripting language would be a proper choice because
these languages have a higher level of coding and will access
the underlaying system in a platform independent way. The
language I want to choose is perl6. Yes, the still unfinished
perl version. I am very confident that the language gets its
first release this year(2015) and wanted to learn about the
language by doing this project.

The second approach is to use a browser to do the work. There we can
use html5, css3 and javascript and libraries. There is also a server side scripting which can be any of perl6, perl 5 or javascript by means of nodejs. There are also a great many javascript modules which can be used.

## The storage method

Because the information items on one object can be different than on
the other a hiërargycal database would be the choice. MongoDB is a
dayabase for which there is support from javascript as well as perl6.

## Storage

The name of the database and the names of the collections

## Dependencies

The program will be depending on several modules and programs. That
is  only logical because we do not want to reinvent the wheel(s) again
do we? We only try not to select those software which will bind it to
some platform as explained above.

## Perl6

The followup version of perl 5.*. The program
is not yet completely finished but will be soon (2015-01). This
program is a interpreter/compiler which can compile the script into some
intermediary



# State of affairs

A list of programs and web pages created and made available for use. While
the project is still in a pristene state there presumable are several bugs
left behind. Also things in the database and programs might change when
other ideas arrive. Below there is a list of what has been made. For
documentation.

The mongo database is Library with several collections.
* object_metadata: Collection to store meta information of any object found.
* mimetypes: Collection to store mimetype information. This can be connected to the object-type.

install-mimetypes.pl6 is program to install mimetype information from
http://www.freeformatter.com/mime-types-list.html

store-file-metadata.pl6 is a program to insert or modify metadata of
files and directories in the database.


# Priorities

# Design

```plantuml

title Overview

hide members
class Client as "Client\nApplication"

package MongoDB #AAAAAA {
  'set namespaceSeparator ::
  class MC as "MongoDB::Client"
  class MDB as "MongoDB::Database"
  class MCL as "MongoDB::Collection"

  MC -[hidden]- MDB
  MDB -[hidden]- MCL
}

package library #FFFFFF {

  class L as "Library" << (P,#FF8800) package >>
  class LC as "Library::Configuration"
  class LD as "Library::Database" << (R,#FFFF00) role >>
  class LMD as "Library::Metadata::Database"
  class Obj as "Library::Metadata::Object" << (R,#FFFF00) role >>
  class OTF as "Library::Metadata::Object::File"
  class OTD as "Library::Metadata::Object::Directory"

  MC <--* L
  LC --* L

  L --* LD
  MDB <-right-* LD
  MCL <-right-* LD

  Client *--> Obj
  LD <|-- LMD

  'LMD <- Obj
  Obj -> LMD
  Obj <|-- OTF
  Obj <|-- OTD
}

```
