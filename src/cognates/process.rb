require 'set'
require 'fileutils'

#########################

def lines(path)
	File.read(path).lines.map(&:strip).filter {|s| not s.empty?}
end

L_VARIANTS  = lines 'sources/JPVariants.txt'
L_FURIGANAS = lines 'sources/JmdictFurigana.txt'
L_HANJAS    = lines 'sources/hanja.txt'
L_HANJAEOS  = lines 'sources/hanjas.csv'

# just nice to see types
kanji_to_hanzi       = {}
hanzigo_to_kanjigo   = {}
kanjigo_to_furiganas = {}
hanjas               = {}
kanjigo              = Set.new
hanjaeo              = {}

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

most_jp = (lines 'sources/44492-japanese-words-latin-lines-removed.txt')
most_ko = (lines 'sources/ko_50k.txt').map {|line| line.split(' ')[0]}

most_jp_s = most_jp.to_set
most_ko_s = most_ko.to_set

most = common
	.filter {|h, j, k| most_jp_s.include? j and most_ko_s.include? k}
	.sort_by {|h, j, k| (most_jp.index j) + (most_ko.index k)}

#########################

def slidee(contents)
	%Q[<div class="slidee">#{contents}</div>]
end

def slide(contents)
	%Q[<div class="slide">#{contents}</div>]
end

def slider(shown, hidden)
	slide((slidee hidden) + (slidee shown))
end

#########################

# output_path/
# ├── word/
# │   ├── word.css
# │   ├── ??.html
# │   └── ...
# └── table.html

# not very nice to check args at very end but

output_path = File.absolute_path ARGV[0]
abort "output `#{output_path}` is not a directory!" unless File.directory? output_path

css_path = File.absolute_path 'word.css'

Dir.chdir output_path

FileUtils.mkdir_p 'word/'
FileUtils.cp css_path, 'word/word.css'

trs = ''

most.first(500).each do |h, j, k|
	infos = h.chars.each_with_index.map {|char, i| hanjas[char][k[i]] }
	yomis = kanjigo_to_furiganas[j]

	next puts "skipped #{h} (due to furigana mismatch)" if yomis.length < j.length
	next puts "skipped #{h} (due to hanja mismatch)" if infos.any? &:nil?

	### generate each individual page ###

	page  = h.chars.map {|char| slide char} .join

	page += yomis.each_with_index.map {|yomi, i| j[i] == h[i] ? (slide yomi) : (slider yomi, j[i])} .join

	page += h.chars.each_with_index.map {|hanz, i| slider k[i], hanjas[hanz][k[i]]} .join

	File.write "word/#{h}.html", '<link rel="stylesheet" href="word.css">' + page

	### generate main index page ###

	tds  = %Q[<td><a href="word/#{h}.html">#{h}</a></td>]
	tds += %Q[<td>#{k}</td>]
	tds += %Q[<td>#{kanjigo_to_furiganas[j].join}</td>]

	trs += %Q[<tr>#{tds}</tr>]
end

File.write 'table.html', %Q[<table>#{trs}</table>]