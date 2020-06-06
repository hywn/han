index.html: index.md
	echo '<link rel="stylesheet" href="https://hywn.github.io/src/list.css" />' > index.html
	pandoc --from markdown-smart-auto_identifiers --to html index.md >> index.html

clean:
	rm -rf *.html