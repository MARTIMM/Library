use v6;

use BSON;
use BSON::Document;

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::Cursor;

use Library::App::TypeDataStore;

#use QA::Sheet;
#use QA::Set;
#use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
unit class Library::DB::Client:auth<github:MARTIMM>:ver<0.1.0>;

has Str $!uri;
#has Str $!user-db-name;
has MongoDB::Client $!client;
has MongoDB::Cursor $!cursor;
has Hash $!user-data;

#`{{
has MongoDB::Database $!lib-db;         # Library
has MongoDB::Database $!user-db;        # any name not config

has MongoDB::Collection $!ext-coll;     # Extensions in Library db
has MongoDB::Collection $!mime-coll;    # Mimetypes in Library db

has MongoDB::Collection $!config-coll;  # MetaConfig in user db
has MongoDB::Collection $!data-coll;    # MetaData in user db
}}
#-------------------------------------------------------------------------------
submethod BUILD ( ) { #( Str:D :$!user-db-name ) {

  # Get config data
  my QA::Types $qa-types .= instance;
  my Hash $config = $qa-types.qa-load( 'client-config', :userdata);
#note "cfg: $config.gist()";

  # properties part
  my Hash $connect-prop = $config<connection><connect-properties> // %();

  # first uri options
  my Str $options = '';
  for $connect-prop<options>.keys -> Str $opt-key {
    #$options ~= ?$options ?? '&' !! '?';
    # only one Pair per option
#note "option: $opt-key, '=', $connect-prop<options>{$opt-key}";
    $options ~= [~] (?$options ?? '&' !! '?'),
                $opt-key, '=', $connect-prop<options>{$opt-key};
  }
#note "options: $options";

  # Assume user is current user. If not found in config use 'default-user' data
  $!user-data = self.get-user-data($config);
note 'data-config: ', $!user-data;

  # that the uri
  $!uri =
    [~] 'mongodb://',
    $connect-prop<server> // 'localhost', ':',
    $connect-prop<port> // '27017', '/',
    ($!user-data<acc-database> ?? "$!user-data<acc-database>" !! ''),
    $options;

note "Uri: $!uri";
}

#-------------------------------------------------------------------------------
method get-user-data ( Hash $config --> Hash ) {
#  CONTROL { when CX::Warn {  note .gist; .resume; } }

  # Assume user is current user. If not found in config use 'default-user' data
  my Hash $user-data = %();

  my Str $selected-project = Library::App::TypeDataStore.instance.project;
  for @($config<users>) -> Hash $user {
note 'projects: ', $user<projects>, ', ', $selected-project;

    next unless $user<name> eq $*USER;
    $user-data<name> = $user<name>;
    $user-data<password> = $user<password> if ?$user<password>;
    last unless $selected-project;

    for @($user<projects>) -> Hash $project {
#note 'project: ', $project<name>, ', ', $Library::app-config<project>;
      next unless $project<name> eq $selected-project;

      $user-data<database> = $project<database>;
      $user-data<acc-database> = $project<database>;
      $user-data<meta-config> = $project<meta-config>;
      $user-data<meta-data> = $project<meta-data>;
      $user-data<logfile> = $project<logfile>;
    }
  }

  if $user-data<database>:!exists {
    $user-data<name> //= $config<default-user><name>;
    $user-data<database> = $config<default-user><database>;
    $user-data<meta-config> = $config<default-user><meta-config>;
    $user-data<meta-data> = $config<default-user><meta-data>;
    $user-data<logfile> = $config<default-user><logfile>;
  }

  $user-data
}

#-------------------------------------------------------------------------------
method connect ( ) {
  $!client .= new(:$!uri);
}

#-------------------------------------------------------------------------------
method insert (
  Array:D $documents, Bool :$lib = False, Str:D :$user-collection-key
  --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  $db.run-command: (
    insert => $!user-data{$user-collection-key},
    documents => $documents
  )
}

#-------------------------------------------------------------------------------
method update (
  Array:D $updates, Bool :$lib = False, Str:D :$user-collection-key,
  --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  $db.run-command: (
    update => $!user-data{$user-collection-key},
    updates => $updates,
    ordered => True,
  )
}

#-------------------------------------------------------------------------------
method delete (
  Array:D $deletes, Bool :$lib = False, Str:D :$user-collection-key
  --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  $db.run-command: (
    delete => $!user-data{$user-collection-key},
    deletes => $deletes
  )
}

#-------------------------------------------------------------------------------
multi method count (
  List $query?, Bool :$lib = False, Str:D :$user-collection-key
  --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  my BSON::Document $req .= new;
  $req<count> = $!user-data{$user-collection-key};
  $req<query> = $query // BSON::Document.new;
#note "count req 1: ", $req.perl;

  $db.run-command($req)
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method count (
  BSON::Document $query?, Bool :$lib = False, Str:D :$user-collection-key
  --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  my BSON::Document $req .= new;
  $req<count> = $!user-data{$user-collection-key};
  $req<query> = $query // BSON::Document.new;
#note "count req 2: ", $req.perl;

  my BSON::Document $doc = $db.run-command($req);
#note "ret doc 2: ", $doc<ok>, ', ', $doc<n>;
  $doc
}

#-------------------------------------------------------------------------------
method find (
  BSON::Document $query?, Int :$limit, Bool :$debug = False,
  Bool :$lib = False, Str:D :$user-collection-key
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  given my BSON::Document $request .= new {
    .<find> = $!user-data{$user-collection-key};
    .<filter> = $query if ?$query;
    .<limit> = $limit if ?$limit;
  }
note 'req doc: ', $request.raku;

  my BSON::Document $doc = $db.run-command($request);
  if $doc<ok> {
#note 'ret doc: ', $doc.raku;
    $!cursor .= new( :$!client, :cursor-doc($doc<cursor>));
  }

  else {
#note 'Nothing found …';
    $!cursor = Nil;
  }
}

#-------------------------------------------------------------------------------
method get-document ( --> BSON::Document ) {
  ?$!cursor ?? $!cursor.fetch !! BSON::Document
}

#`{{
#-------------------------------------------------------------------------------
method documents (
  BSON::Document $find-result where ?*<cursor>
  --> Array
) {
  $find-result<cursor><firstBatch>
}

#-------------------------------------------------------------------------------
method get-more (
  BSON::Document $find-result where ?*<cursor>
  --> BSON::Document
) {

  # if id = 0 there are no documents left to retrieve
  return BSON::Document unless $find-result<cursor><id>;

  my BSON::Document $req .= new;
  $req<getMore> = $find-result<cursor><id>;
  $req<collection> = $find-result<cursor><ns>;

  my $doc = $!database.run-command($req);
note "Get more: ", $doc.perl;

  $doc
}
}}

#-------------------------------------------------------------------------------
method drop-collection (
  Bool :$lib = False, Str:D :$user-collection-key --> BSON::Document
) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  $db.run-command: (drop => $!user-data{$user-collection-key},);
}

#-------------------------------------------------------------------------------
method drop-database ( Bool :$lib = False --> BSON::Document ) {
  my MongoDB::Database $db =
    $lib ?? $!client.database('Library')
         !! $!client.database($!user-data<database>);

  $db.run-command: (dropDatabase => 1,);
}

#-------------------------------------------------------------------------------
method cleanup ( ) {
  $!client.cleanup;
  $!client = Nil;
}


=finish
#--[ Private methods ]----------------------------------------------------------
method !test-connection ( --> Bool ) {

#note "\ntest conn: $!collection-key, ", $Library::client.defined;
  return False unless $Library::client.defined;

  my Library::Configuration $lcg := $Library::lib-cfg;
#note "\nprog config: ", $lcg.prog-config;
#note "\nlib config: ", $lcg.lib-config;

  # get database and collection name from configuration
  my Str $db-name = $lcg.database-name(:$!use-lib-db);
  my Str $col-name = $lcg.collection-name( $!collection-key, :$!use-lib-db);
#note "lcg: $db-name, $col-name";

  # create database with client and get collection
  $!database = $Library::client.database($db-name);
  $!collection = $!database.collection($col-name);

note "Col: ", $!collection.full-collection-name;

  True
}
