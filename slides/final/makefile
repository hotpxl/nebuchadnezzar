all: main.pdf

main.pdf: main.tex
	latexmk -xelatex main.tex

clean:
	latexmk -c
	rm -rf *.snm *.nav
