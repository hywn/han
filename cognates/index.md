<div class="box">
korean/japanese character cognates (scroll down for wordlist)
=============================================================
did you know that korean and japanese share a lot of vocabulary that came from the same origins (usually middle chinese)? below is a list of two-character words with readings in both japanese and korean. the list is sorted roughly by frequency in both languages (words should be used frequently in both languages).

if you click on a word, you can view it (along with the japanese and korean readings) on a pretty page. on the pretty page, you can hover over the japanese to view each character's japanese-simplified form (if it exists), and you can hover over the korean to view the full hanja identity/the hanja meaning + pronunciation.

the wordlist and word pages are generated with a ruby script that you can find [here](https://github.com/hywn/han).

### notable problems
- doesn't account for irregular japanese readings
	- 時計 -> とけい
- doesn't account for korean initial sound changes
	- 女子 -> 여자
- korean word frequency just accounts for hangul and not hanja
	- 以上, 理想, and 異常 are all equally as common b/c they are all 이상
- no home button/any navigation on word pages

### file sources
- [hanja word list](https://github.com/dbravender/hanja-dictionary) (hanjas.csv)
- [hanja info](https://github.com/myungcheol/hanja) (hanja.txt)
- [japanese to traditional character list](https://github.com/pinedance/hanTNsrc) (JPVariants.txt)
- [japanese readings](https://github.com/Doublevil/JmdictFurigana) (JmdictFurigana.txt)
- [korean frequency list](https://github.com/oprogramador/most-common-words-by-language) (ko_50k.txt)
- [japanese frequency list](https://github.com/hingston/japanese) (44492-japanese-words-latin-lines-removed.txt)
</div>

<style>
body {
	margin: 5em;

	display: flex;
	flex-direction: column;
	align-items: center;
}

.box { padding: 1em; width: 32em }

td { border: none; padding: 0.2em 1.2em 0.2em 1.2em }
</style>