#!/usr/bin/env perl6

use v6;
use GTK::Simple;
use GTK::Simple::App;

my $app = GTK::Simple::App.new( title => "Hello GTK!" );

my GTK::Simple::Button $b1 .= new(:label("Hello World!"));
my GTK::Simple::Button $b2 .= new(:label("Goodbye!"));
my GTK::Simple::HBox $hbox .= new;
$hbox.spacing(2);
$hbox.pack-start( $b1, False, False, 2);
$hbox.pack-start( $b2, False, False, 2);

my GTK::Simple::VBox $vbox .= new;
$vbox.pack-start( $hbox, False, False, 2);

my GTK::Simple::Frame $f1 .= new(:label('top level buttons'));
$f1.set-content($vbox);
$app.set-content($f1);
$app.border-width = 20;

$b2.sensitive = False;
$b1.clicked.tap({ .sensitive = False; $b2.sensitive = True });
$b2.clicked.tap({ $app.exit; });

$app.run;
