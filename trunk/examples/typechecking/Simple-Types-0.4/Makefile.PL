use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Simple::Types',
    VERSION_FROM      => 'lib/Simple/Types.pm', # finds $VERSION
    PREREQ_PM         => {Parse::Eyapp => "1.06"}, # e.g., Module::Name => 1.1
);

sub MY::postamble {
return <<'EOT';
release: 
	cd lib/Simple; eyapp -m Simple::Types Types.eyp; perl -c Types.pm; treereg -m Simple::Types Trans

pdf:
	atopdf lib/Simple/Types.eyp lib/Simple/Trans.trg script/usetypes.pl -o /tmp/SimpleTypes.pdf
EOT
}

