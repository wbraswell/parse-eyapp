dvi:addressassign.tex codegeneration.tex introduction.tex lexicalanalysis.tex machineindependentoptimizations.tex output.tex peephole.tex phases.tex syntacticanalysis.tex theperlreview.tex
	latex theperlreview.tex
	bibtex theperlreview
	latex theperlreview.tex
	
pdf: addressassign.tex codegeneration.tex introduction.tex lexicalanalysis.tex machineindependentoptimizations.tex output.tex peephole.tex phases.tex syntacticanalysis.tex theperlreview.tex
	pdflatex theperlreview

html: dvi
	latex2html theperlreview

public: html
	cp theperlreview/* /home/pl/public_html/eyapsimple/
	cp theperlreview.dvi /home/pl/public_html/eyapsimple/eyapsimple.dvi
	chmod a+r /home/pl/public_html/eyapsimple/*

clean:
	rm -f *.log *.dvi *.aux *.bbl *.blg *~
	
cleanall:
	rm -f *.log *.dvi *.aux *.bbl *.blg *~ *.pdf *.ps

tar:
	tar cvzf /tmp/theperlreview07_casiano.tar.gz *.dvi *.tex *.bbl *.sty *.pdf makefile src/*
	chmod a+r /tmp/theperlreview07_casiano.tar.gz

link:
	ln -s ${HOME}/Lbook/perlbib/perl.bib
