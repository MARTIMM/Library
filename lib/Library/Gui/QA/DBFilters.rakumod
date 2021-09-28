use v6.d;


use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
#use Gnome::Gtk3::Window;
#use Gnome::Gtk3::Grid;
#use Gnome::Gtk3::Button;
#use Gnome::Gtk3::Label;

use QA::Gui::SheetSimple;
#use QA::Gui::Frame;
#use QA::Gui::Value;
#use QA::Types;
#use QA::Question;

#use Gnome::N::X;

use BSON::Document;

use Library::DB::Client;

#-------------------------------------------------------------------------------
unit class Library::Gui::QA::DBFilters:auth<github:MARTIMM>:ver<0.1.0>;

has Str $!sheet-name = 'tag-skip-filter-config';
has Library::DB::Client $!db is required;

#-------------------------------------------------------------------------------
submethod BUILD ( Library::DB::Client:D :$!db ) { }

#-------------------------------------------------------------------------------
method show-dialog ( ) {

  my Hash $user-data = self.get-filter-data(:filter<tag-filter>);

  my QA::Gui::SheetSimple $sheet-dialog .= new(
    :$!sheet-name, :show-cancel-warning, :!save-data, :$user-data
  );

  my Int $response = $sheet-dialog.show-sheet;
  self.display-result( $response, $sheet-dialog);
  $sheet-dialog.result-user-data // %();

  self.save-filter-data($sheet-dialog.result-user-data);
#note 'sheet results: ', $sheet-dialog.result-user-data.gist;
}

#-------------------------------------------------------------------------------
method get-filter-data ( Str:D :$filter --> Hash ) {
  my Hash $user-data = %(
    filters => %(
      skip-filter-properties => %(
        skip-filter => [],
      ),
      tag-filter-properties => %(
        tag-filter => [],
      )
    )
  );

  my BSON::Document $query .= new: ( :config-type<skip-filter>, );
  $!db.find( $query, :user-collection-key<meta-config>);
  my BSON::Document $filter-data = $!db.get-document;
  if ?$filter-data {
#note 'skip filter: ', $filter-data, ', ', $filter-data<skips>;
    $user-data<filters><skip-filter-properties><skip-filter> =
      $filter-data<skips>;
  }

  else {
    self.create-skip-filter;
  }

  $query .= new: ( :config-type<tag-filter>, );
  $!db.find( $query, :user-collection-key<meta-config>);
  $filter-data = $!db.get-document;
  if ?$filter-data {
    $user-data<filters><tag-filter-properties><tag-filter> = $filter-data<tags>;
  }

  else {
    self.create-tag-filter;
  }

  $user-data
}

#-------------------------------------------------------------------------------
method save-filter-data ( Hash $user-data ) {
  my BSON::Document $sfupd .= new: (
    :q(:config-type<skip-filter>),
    :u( '$set' => (
        :skips($user-data<filters><skip-filter-properties><skip-filter>)
      )
    ),
  );

  my BSON::Document $tfupd .= new: (
    :q(:config-type<tag-filter>),
    :u( '$set' => (
        :tags($user-data<filters><tag-filter-properties><tag-filter>)
      )
    ),
    :upsert
  );

  note $!db.update( [ $sfupd, $tfupd], :user-collection-key<meta-config>);
}

#-------------------------------------------------------------------------------
method create-skip-filter ( ) {
  my BSON::Document $doc .= new: (
    :config-type<skip-filter>,
    :skips([ ]),
  );
  $!db.insert( [$doc,], :user-collection-key<meta-config>);
}

#-------------------------------------------------------------------------------
method create-tag-filter ( ) {
  my BSON::Document $doc .= new: (
    :config-type<tag-filter>,
    :tags([ ]),
  );
  $!db.insert( [$doc,], :user-collection-key<meta-config>);
}

#-------------------------------------------------------------------------------
method display-result ( Int $response, QA::Gui::Dialog $dialog ) {

  note "Dialog return status: ", GtkResponseType($response);
  self.show-hash($dialog.result-user-data) if $response ~~ GTK_RESPONSE_OK;
  $dialog.widget-destroy unless $response ~~ GTK_RESPONSE_NONE;
}

#-------------------------------------------------------------------------------
method show-hash ( Hash $h, Int :$i is copy ) {
  if $i.defined {
    $i++;
  }

  else {
    note '';
    $i = 0;
  }

  for $h.keys.sort -> $k {
    if $h{$k} ~~ Hash {
      note '  ' x $i, "$k => \{";
      self.show-hash( $h{$k}, :$i);
      note '  ' x $i, '}';
    }

    elsif $h{$k} ~~ Array {
      note '  ' x $i, "$k => $h{$k}.perl()";
    }

    else {
      note '  ' x $i, "$k => $h{$k}";
    }
  }

  $i--;
}
