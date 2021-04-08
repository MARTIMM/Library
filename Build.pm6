use v6;

use QA::Sheet;
use QA::Set;
use QA::Question;
use QA::Types;

#------------------------------------------------------------------------------
unit class Build;

constant library-id = 'io.github.martimm.library';

has Str $!dist-path;

#my Str $*cfg-dir = '';
#my Str $*shr-dir = '';

#-------------------------------------------------------------------------------
method build ( Str $!dist-path --> Int ) {

note $!dist-path;
#  self.create-config-dirs;
  self.make-sheets;
note 'done';

  # return success
  1
}

#`{{
#-------------------------------------------------------------------------------
method create-config-dirs ( ) {

#https://learn.fotoware.com/FotoStation/10_Troubleshooting_FotoStation/Where_are_configuration_files_stored_in_Windows%3F
#https://stackoverflow.com/questions/43853548/xdg-basedir-directories-for-windows

  if $*DISTRO.is-win {
    $*cfg-dir = "$*HOME/dataDir/io.github.martimm.osm";
    $*shr-dir = "$*HOME/dataLocalDir/io.github.martimm.osm";
  }

  else {
    $*cfg-dir = "$*HOME/.config/io.github.martimm.osm";
    $*shr-dir = "$*HOME/.local/share/io.github.martimm.osm";
  }

  mkdir $*cfg-dir, 0o750 unless $cfg-dir.IO.d and $cfg-dir.IO.r;
  mkdir $*shr-dir, 0o750 unless $cfg-dir.IO.d and $cfg-dir.IO.r;
}
}}

#-------------------------------------------------------------------------------
method make-sheets ( ) {

  # let QA look at the proper locations
  given my QA::Types $qa-types {
    .data-file-type(QAYAML);
    .cfg-root(library-id);
#    .list-dirs.note;
  }

  # cleanup sheets before creating
  $qa-types.qa-remove( 'client-config', :sheet);
  $qa-types.qa-remove( 'tag-skip-filter-config', :sheet);
#  $qa-types.qa-remove( '', :sheet);


  self.client-config-sheet;
  self.tag-skip-filter-sheet;

  # cleanup sets afterwards
  $qa-types.qa-remove( 'connect-properties', :set);
  $qa-types.qa-remove( 'tag-filter-properties', :set);
  $qa-types.qa-remove( 'skip-filter-properties', :set);
#  $qa-types.qa-remove( '', :set);
}

#-------------------------------------------------------------------------------
method client-config-sheet ( ) {
  self.connect-properties-set;

  my QA::Sheet $sheet .= new(:sheet-name<client-config>);
#  $sheet.remove;

  $sheet.width = 400;
  $sheet.width = 525;
  $sheet.button-map<Finish> = 'Save';

  $sheet.add-page(
    'connection', :title('MongoDB Server'),
    :description('Information to connect to your MongoDB database server')
  );
  $sheet.add-set( 'connection', 'connect-properties');

  $sheet.save;
}

#-------------------------------------------------------------------------------
method connect-properties-set ( ) {
  my QA::Set $set;
  my QA::Question $question;

  $set .= new(:set-name<connect-properties>);
#  $set.remove;
  #$set.description = 'Properties of a map feature';

  $question .= new(:name<server>);
  $question.description = 'hostname or ip of server';
#  $question.required = True;
#  $question.default = '';
  $set.add-question($question);

  $question .= new(:name<port>);
  $question.description = 'Port of server';
  $question.default = 27017;
  $set.add-question($question);

  $question .= new(:name<con-opt>);
  $question.description = 'Connect options';
  $question.selectlist = [|<replicaSet>];
#  $question.fieldtype = QAEntry;
  $question.repeatable = True;
  $set.add-question($question);

  $question .= new(:name<database>);
  $question.description = 'Name of database';
  $question.required = True;
  $set.add-question($question);

  $question .= new(:name<username>);
  $question.description = 'Name of user account';
  #$question.required = True;
  $set.add-question($question);

  $question .= new(:name<password>);
  $question.description = 'Password of account';
  #$question.required = True;
  $set.add-question($question);

  $question .= new(:name<login-method>);
  $question.description = 'Login mechanism';
  $question.fieldtype = QAComboBox;
  $question.fieldlist = [|<SCRAM_SHA1 SCRAM_SHA256>];
  $set.add-question($question);

  $set.save;
}

#-------------------------------------------------------------------------------
method tag-skip-filter-sheet ( ) {
  self.tag-filter-set;
  self.skip-filter-set;

  my QA::Sheet $sheet .= new(:sheet-name<tag-skip-filter-config>);
#  $sheet.remove;

  $sheet.width = 525;
  $sheet.height = 450;

  $sheet.add-page(
    'filters', :title('Tag and Skip Filter List'),
    :description('Filter descriptions using Raku regex')
  );
  $sheet.add-set( 'filters', 'tag-filter-properties');
  $sheet.add-set( 'filters', 'skip-filter-properties');

  $sheet.save;
}

#-------------------------------------------------------------------------------
method tag-filter-set ( ) {
  my QA::Set $set;
  my QA::Question $question;

  $set .= new(:set-name<tag-filter-properties>);
  #$set.remove;
  $set.description = 'Tag filter properties';

  $question .= new(:name<tag-filter>);
  $question.description = 'Tag filters';
  $question.repeatable = True;
  $set.add-question($question);

  $set.save;
}

#-------------------------------------------------------------------------------
method skip-filter-set ( ) {
  my QA::Set $set;
  my QA::Question $question;

  $set .= new(:set-name<skip-filter-properties>);
  $set.description = 'skip filter properties';

  $question .= new(:name<skip-filter>);
  $question.description = 'Skip filters';
  $question.repeatable = True;
  $set.add-question($question);

  $set.save;
}
