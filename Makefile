docs/:
	mkdir docs/

	make docs/index.html
	make docs/1800/
	make docs/cognates/

clean:
	rm -rf docs/


### landing page ###

docs/index.html: src/index.md
	echo '<link rel="stylesheet" href="https://hywn.github.io/src/list.css" />' > $@
	pandoc --from markdown-smart-auto_identifiers --to html $< >> $@


### 1800 hanja ###

docs/1800/:
	mkdir docs/1800/
	cp src/1800/index.html docs/1800/


### cognates ###

docs/cognates/:
	mkdir docs/cognates/
	make docs/cognates/index.html

docs/cognates/index.html: src/cognates/index.md docs/cognates/table.html
	pandoc --from markdown-smart-auto_identifiers --to html $< > $@
	cat $(word 2, $^) >> $@

docs/cognates/table.html: src/cognates/process.rb
	cd src/cognates/; ruby ../../$< ../../docs/cognates/