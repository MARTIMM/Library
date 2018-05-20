use v6;

for @$=pod -> $pb {
  say "\n", $pb.perl;
}

for @$=pod -> $pd {
  if $pd ~~ Pod::Block::Named and $pd.name eq 'data' {
    .say for @($pd.contents[0].contents).lines;
  }
};

=head1 test van weet ik veel
=begin comment

jhsdgfjhgsdfjhg

=end comment











=begin data :key<dataBlock>
a 1
b 2
c 3
=end data
