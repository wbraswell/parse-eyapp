PERL5LIB=/home/pl/doc/casiano/PLBOOK/PLBOOK/code/Simple-Types/lib/:/home/pl/src/perl/YappWithDefaultAction/lib/:/home/pl/src/perl/Parse-YATW/lib/
Types.pm: Types.eyp Trans.pm
	eyapp -m Simple::Types Types.eyp
	perl -c Types.pm

Trans.pm: Trans.trg
	treereg -m Simple::Types Trans
	#treereg -nonumber -m Simple::Types Trans

