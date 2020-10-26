docs/: docs/cognates/ docs/1800/ docs/index.html
	cowsay "moo"

clean:
	rm -rf docs/


### landing page ###

docs/index.html: src/index.md
	pandoc --from markdown-smart-auto_identifiers --to html $< > $@


### 1800 hanja ###

docs/1800/: docs/1800/index.html

docs/1800/index.html: src/1800/gen.js docs/1800/1800.json
	./src/1800/gen.js $(word 2, $^) > $@

docs/1800/1800.json: src/1800/namu.js
	mkdir -p docs/1800/
	./src/1800/namu.js > $@


### cognates ###

docs/cognates/: docs/cognates/index.html

docs/cognates/index.html: src/cognates/index.md docs/cognates/table.html
	pandoc --from markdown-smart-auto_identifiers --to html $< > $@
	cat $(word 2, $^) >> $@

docs/cognates/table.html: src/cognates/process.rb
	mkdir -p docs/cognates/
	cd src/cognates/; ruby ../../$< ../../docs/cognates/