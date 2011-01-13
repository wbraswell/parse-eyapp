sub tutu { "tutu" }

sub plim {
  local &tutu = sub { "titi" };

  print &tutu()."\n"; # It will print "titi"
}

print &tutu()."\n"; # It will print "tutu"
