index.html: index.md table.html
	pandoc --from markdown-smart-auto_identifiers --to html index.md > index.html
	cat table.html >> index.html

table.html: process.rb
	ruby process.rb

clean:
	rm -rf *.html
	rm -rf word/*.html