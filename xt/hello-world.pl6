#!/usr/bin/env perl6

use v6;

#--[ Part taken from App ]--
use nqp;
use NativeCall;
use GTK::Simple::Raw :app, :DEFAULT;

my $arg_arr = CArray[Str].new;
$arg_arr[0] = $*PROGRAM.Str;
my $argc = CArray[int32].new;
$argc[0] = 1;
my $argv = CArray[CArray[Str]].new;
$argv[0] = $arg_arr;
gtk_init($argc, $argv);
#--[ End of part ]--

use GTK::Simple;
use GTK::Simple::App;

my $button = GTK::Simple::Button.new(label => "Hello World!");
my $second = GTK::Simple::Button.new(label => "Goodbye!");
$second.sensitive = False;
$button.clicked.tap({ .sensitive = False; $second.sensitive = True });
$second.clicked.tap({ app-exit; });

#--[ Statement moved down ]--
my GTK::Simple::App $app .= new(title => "Hello GTK!");
$app.set-content( GTK::Simple::VBox.new( $button, $second));
$app.border-width = 20;
$app.run;

sub app-exit( ) { $app.exit; }
