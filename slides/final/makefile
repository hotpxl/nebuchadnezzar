.PHONY: all watch clean

all: main.pdf

main.pdf: main.tex
	latexmk -xelatex main.tex

watch:
	latexmk -xelatex -pvc -interaction=nonstopmode -synctex=1 main.tex

clean:
	latexmk -c
	rm -rf *.snm *.nav *.synctex.gz
