#!/usr/bin/env ruby

require 'set'

# :tag 'hi', href: 'website' => <tag href="website">hi</tag>
class Symbol
	def tag(contents, attributes={})
		return "<#{self.to_s} #{attributes.map {|k, v| "#{k}=\"#{v}\""} .join ' '}>#{contents}</#{self.to_s}>"
	end
end

def lines(path)
	File.read(path).lines.map(&:strip).filter {|s| not s.empty?}
end

L_VARIANTS = lines 'JPVariants.txt'
L_FURIGANAS = lines 'JmdictFurigana.txt'
L_HANJAS = lines 'hanja.txt'
L_HANJAEOS = lines 'hanjas.csv'

kanji_to_hanzi = {}
hanzigo_to_kanjigo = {}
kanjigo_to_furiganas = {}
hanjas = {}
kanjigo = Set.new
hanjaeo = {}

# build kanji_to_hanzi
kanji_to_hanzi = L_VARIANTS.map {|line| line.split("\t").reverse} .to_h
hanzi_to_kanji = L_VARIANTS.map {|line| line.split("\t")} .to_h

#build hanzi_to_kanjigo
hanzigo_to_kanjigo = L_FURIGANAS
	.map {|line| line.split('|')}
	.map {|word, _| [
		word.chars.map {|kanji| kanji_to_hanzi[kanji] or kanji} .join,
		word
	]} .reverse.to_h

#build hanzi_to_furiganas
kanjigo_to_furiganas = L_FURIGANAS
	.map {|line| line.split('|')}
	.map {|word, yomi_full, yomi_parts| [
		word,
		yomi_parts.split(';').map {|parts| parts[/(?<=:).+/]}
	]} .reverse.to_h # keep first reading only; file has obscure readings towards bottom.

# build hanjas
curr_syllable = ''
L_HANJAS.each do |line|
	curr_syllable = line[1] and next if line[0] == '['

	hanja = line[0]
	info = line[/(?<==).+?(?=,|\()/]

	hanjas[hanja] = {} if not hanjas[hanja]
	hanjas[hanja][curr_syllable] = info
end

# build kanjigo
kanjigo = L_FURIGANAS.map {|line| line.split('|')[0]} .to_set

# build hanjaeo
hanjaeo = L_HANJAEOS
	.map {|line| line.split('|')[0..1] }
	.map {|hanjas, hanguls| [hanjas, hanguls[0...hanjas.length]]} # hanjas.csv: 約束|약속하다|promise| 約 束
	.to_h

#########################

common = hanjaeo.filter_map do |hanjaeo, hangul|

	jp_equivalent = hanjaeo if kanjigo.include? hanjaeo
	jp_equivalent = hanzigo_to_kanjigo[hanjaeo] if !jp_equivalent

	[hanjaeo, jp_equivalent, hangul] if jp_equivalent
end

common = common.filter {|h, _| h.length == 2}

most_jp = (lines '44492-japanese-words-latin-lines-removed.txt')
most_ko = (lines 'ko_50k.txt').map {|line| line.split(' ')[0]}

most_jp_s = most_jp.to_set
most_ko_s = most_ko.to_set

most = common
	.filter {|h, j, k| most_jp_s.include? j and most_ko_s.include? k}
	.sort_by {|h, j, k| (most_jp.index j) + (most_ko.index k)}

#########################

def box(text)
	"<div class=\"centered slide\"><p>#{text}</p></div>"
end

def slide(shown, hidden)
	"<div class=\"slide\"><div class=\"centered slidee\"><p>#{hidden}</p></div><div class=\"centered slidee\"><p>#{shown}</p></div></div>"
end

def row(font, contents)
	"<div class=\"row #{font}\">#{contents}</div>"
end

#########################

index = %{
<style>
body {
	display: flex;
	flex-wrap: wrap;
	justify-content: center;
	align-items: center;
	flex-direction: column;
}

.box { width: 33em; align-items: right; padding: 1em }

td { border: none; padding: 0.2em 1.2em 0.2em 1.2em }
</style>

<div class="box">
	<h1>korean/japanese character cognates (scroll down for wordlist)</h1>
	<p>did you know that korean and japanese share a lot of vocabulary that came from the same origins (usually middle chinese)? below is a list of two-character words with readings in both japanese and korean. the list is sorted roughly by frequency in both languages (words should be used frequently in both languages).</p>
	<p>if you click on a word, you can view it (along with the japanese and korean readings) on a pretty page. on the pretty page, you can hover over the japanese to view each character's japanese-simplified form (if it exists), and you can hover over the korean to view the full hanja identity/the hanja meaning + pronunciation.</p>
	<p>the wordlist and word pages are generated with a super hacked-together python script (this text is literally in the script). i'll probably clean it up one day, but that day is not today.</p>
	<p>notable problems</p>
	<ul>
		<li>doesn't account for japanese irregularities and as a result just doesn't generate some pages, e.g. 時計 -> とけい</li>
		<li>korean word frequency just accounts for hangul and not hanja, e.g. 以上, 理想, and 異常 are all equally as common b/c they are all 이상</li>
		<li>no home button/any navigation on word pages</li>
	</ul>
	<p>file sources</p>
	<ul>
		<li><a href="https://github.com/dbravender/hanja-dictionary">hanja word list</a> (hanjas.csv)</li>
		<li><a href="https://github.com/myungcheol/hanja">hanja info</a> (hanja.txt)</li>
		<li><a href="https://github.com/pinedance/hanTNsrc">japanese to traditional character list</a> (JPVariants.txt)</li>
		<li><a href="https://github.com/Doublevil/JmdictFurigana">japanese readings</a> (JmdictFurigana.txt)</li>
		<li><a href="https://github.com/oprogramador/most-common-words-by-language">korean frequency list</a> (ko_50k.txt)</li>
		<li><a href="https://github.com/hingston/japanese">japanese frequency list</a> (44492-japanese-words-latin-lines-removed.txt)</li>
	</ul>
</div>
<table>
}

most.first(500).each do |h, j, k|
	infos = h.chars.each_with_index.map {|char, i| hanjas[char][k[i]] }
	yomis = kanjigo_to_furiganas[j]

	next puts "skipped #{h} (due to furigana mismatch)" if yomis.length < j.length
	next puts "skipped #{h} (due to hanja mismatch)" if infos.any? &:nil?

	### generate each individual page ###

	page  = row 'kr', h.chars.map {|char| box char} .join

	page += row 'jp', yomis.each_with_index.map {|yomi, i| j[i] == h[i] ? (box yomi) : (slide yomi, j[i])} .join

	page += row 'kr', h.chars.each_with_index.map {|hanz, i| slide k[i], hanjas[hanz][k[i]]} .join

	File.write "testpages/#{h}.html", '<link rel="stylesheet" href="word.css">' + (:div.tag page, id: 'contents')

	### generate main index page ###

	tds  = :td.tag(:a.tag h, href: "testpages/#{h}.html")
	tds += :td.tag k
	tds += :td.tag kanjigo_to_furiganas[j].join

	index += :tr.tag tds
end

index += '</table>'

File.write 'rindex.html', index