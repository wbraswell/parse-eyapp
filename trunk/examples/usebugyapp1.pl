use A;
my $p = A->new();

for ("5") {
  $p->YYParse(
    yylex => sub { ("NUM", "5") },
    yyerror => sub { die "Error" },
    yydebug => 1,
  );
}
