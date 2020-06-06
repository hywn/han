require 'set'
require 'fileutils'

output_path = File.absolute_path ARGV[0]

abort "output `#{output_path}` is not a directory!" unless File.directory? output_path

# :tag 'hi', href: 'website' => <tag href="website">hi</tag>
class Symbol
	def tag(contents, attributes={})
		return "<#{self.to_s}#{attributes.empty? ? '' : ' '}#{attributes.map {|k, v| "#{k}=\"#{v}\""} .join ' '}>#{contents}</#{self.to_s}>"
	end
end

def lines(path)
	File.read(path).lines.map(&:strip).filter {|s| not s.empty?}
end

L_VARIANTS = lines 'sources/JPVariants.txt'
L_FURIGANAS = lines 'sources/JmdictFurigana.txt'
L_HANJAS = lines 'sources/hanja.txt'
L_HANJAEOS = lines 'sources/hanjas.csv'

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

most_jp = (lines 'sources/44492-japanese-words-latin-lines-removed.txt')
most_ko = (lines 'sources/ko_50k.txt').map {|line| line.split(' ')[0]}

most_jp_s = most_jp.to_set
most_ko_s = most_ko.to_set

most = common
	.filter {|h, j, k| most_jp_s.include? j and most_ko_s.include? k}
	.sort_by {|h, j, k| (most_jp.index j) + (most_ko.index k)}

#########################

def box(text)
	:div.tag (:p.tag text), 'class': 'centered slide'
end

def slidee(text)
	:div.tag (:p.tag text), 'class': 'centered slidee'
end

def slide(shown, hidden)
	:div.tag (slidee hidden) + (slidee shown), 'class': 'slide'
end

def row(font, contents)
	:div.tag contents, 'class': "row #{font}"
end

#########################

css_path = File.absolute_path 'word.css'

Dir.chdir output_path

Dir.mkdir 'word/' unless Dir.exist? 'word/'

table = '<table>'

most.first(500).each do |h, j, k|
	infos = h.chars.each_with_index.map {|char, i| hanjas[char][k[i]] }
	yomis = kanjigo_to_furiganas[j]

	next puts "skipped #{h} (due to furigana mismatch)" if yomis.length < j.length
	next puts "skipped #{h} (due to hanja mismatch)" if infos.any? &:nil?

	### generate each individual page ###

	page  = row 'kr', h.chars.map {|char| box char} .join

	page += row 'jp', yomis.each_with_index.map {|yomi, i| j[i] == h[i] ? (box yomi) : (slide yomi, j[i])} .join

	page += row 'kr', h.chars.each_with_index.map {|hanz, i| slide k[i], hanjas[hanz][k[i]]} .join

	File.write "word/#{h}.html", '<link rel="stylesheet" href="word.css">' + (:div.tag page, id: 'contents')

	### generate main index page ###

	tds  = :td.tag(:a.tag h, href: "word/#{h}.html")
	tds += :td.tag k
	tds += :td.tag kanjigo_to_furiganas[j].join

	table += :tr.tag tds
end

table += '</table>'

File.write 'table.html', table
FileUtils.cp css_path, 'word/word.css'