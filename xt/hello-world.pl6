#!/usr/bin/env perl6

use v6;

use GTK::Simple;
use GTK::Simple::App;

my GTK::Simple::App $app .= new(title => "Hello GTK!");

my $button = GTK::Simple::Button.new(label => "Hello World!");
my $second = GTK::Simple::Button.new(label => "Goodbye!");
$second.sensitive = False;
$button.clicked.tap({ .sensitive = False; $second.sensitive = True });
$second.clicked.tap({ app-exit; });

$app.set-content( GTK::Simple::VBox.new( $button, $second));
$app.border-width = 20;
$app.run;

sub app-exit( ) { $app.exit; }
