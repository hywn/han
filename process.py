import html
import os.path

##################### important files #########################
#                                                             #
# hanjas.csv                                                  #
#     contains hanjaeo data                                   #
#     format: hanja|hangul|english|hanja but with SPACES      #
#                                                             #
# hanja.txt                                                   #
#     contains hanja definitions/info                         #
#     format: hanja=dma Emt,...                               #
#     might contain lines with [zzz] because it is dictionary.#
#                                                             #
# JmdictFurigana.txt                                          #
#     contains furigana readings for a ton of japanese words  #
#     format: japanese|full reading|indexed non-kana character readings separated by semicolons
#                                   e.g. '0:しゃ;1:しん'      #
#                                                             #
# JPVariants.txt                                              #
#     containts traditional-character equivalents of kanji    #
#     format: traditional\tkanji                              #
#                                                             #
########################### sources ###########################
#                                                             #
# github.com/dbravender/hanja-dictionary                      #
# github.com/myungcheol/hanja                                 #
# github.com/pinedance/hanTNsrc                               #
# github.com/Doublevil/JmdictFurigana                         #
# github.com/oprogramador/most-common-words-by-language       #
# github.com/hingston/japanese                                #
#                                                             #
###############################################################

def tag(dom, contents='', **kwargs):
	return '<{} {}>{}</{}>'.format(dom, ' '.join(['{}="{}"'.format(k, v) for k, v in kwargs.items()]), contents, dom)

def lines(path):
	return [line for line in open(path, 'r').read().split('\n') if line]

hanja_lines = lines('hanja.txt')
hanjas = {}
dma = ''
for line in hanja_lines:
	if line[0] == '[':
		dma = line[1]
	else:
		hanja = line[0]
		if hanja in hanjas:
			hanjas[hanja][dma] = line[2:].split(',')[0]
		else:
			hanjas[hanja] = {dma: line[2:].split(',')[0]}

hanjaeo = lines('hanjas.csv')
furiganas = lines('JmdictFurigana.txt')
variants = lines('JPVariants.txt')

# make sure trim down hangul bc some have 하다 tacked on or something
hanjaeo = {han: (hangul[:len(han)], english) for (han, hangul, english, junk) in [line.split('|') for line in hanjaeo]}
variants = {jap: trad for (trad, jap) in [line.split('\t') for line in variants]}

kanjigo = {} # jap: (yomis)
for line in furiganas:
	jap, reading, unsplit_furig = line.split('|')
	yomis = [z.split(':')[1] for z in unsplit_furig.split(';')]
	
	if jap in kanjigo: continue # JmdictFurigana.txt sometimes has obscure readings at bottom of file. only get first, common reading
	else: kanjigo[jap] = yomis

# gets all japanese words that are entirely kanji

# gets all kanjigo in traditional characters, dict of {trad: jap}
trad_kanjigo = {''.join([variants[char] if char in variants else char for char in word]): word for word in kanjigo}

#for t in trad_kanjigo:
#	print(t)

# gets all hanjaeo that have some connection to japanese
# do not use pure traditional bc is sometimes unclear what pure traditional is like 漢 vs 漢
common = {han: (trad_kanjigo[han] if han in trad_kanjigo else han, hanjaeo[han][0]) for han in hanjaeo if len(han) == 2 and (han in trad_kanjigo or han in kanjigo)}

## TODO: sort by commonality in japanese OR korean
## TODO: fix ugly hanja definitions like 문서 권

style = style = '<link rel="stylesheet" href="word.css">'

# for some reason hanjas.csv sometimes includes endings like for 約束 it is '약속하다'

def gen(han):

	if os.path.isfile('word/%s.html' % han):
		return

	jap, hangul = common[han]
	
	dmas = [hanjas[char] for char in han]
	# 약 is technically 략...
	dmas = [(hangul[i], dmas[i][hangul[i]] if hangul[i] in dmas else [Emt for (dma, Emt) in dmas[i].items()][0]) for i in range(len(han))] # [(dma, Emt)...]
	yomis = kanjigo[jap] # [yomi...]
	
	z = ''
	
	if len(yomis) < len(jap):
		print(han, hangul, jap, yomis)
		return
	
	z += html.row(''.join([html.box(char) for char in han]), 'kr')

	z += html.row(''.join([html.slide(yomis[i], jap[i]) if jap[i] != han[i] else html.box(yomis[i]) for i in range(len(jap))]), 'jp')
	
	z += html.row(''.join([html.slide(dma, Emt) for (dma, Emt) in dmas]), 'kr')
	
	open('word/%s.html' % han, 'w').write(style + html.div(z, id='contents'))

#for (han, (jap, hangul)) in common.items():
#	print(han, jap, hangul)

most_jp = lines('44492-japanese-words-latin-lines-removed.txt')
most_ko = [line.split(' ')[0] for line in lines('ko_50k.txt')]

# only keep words that we can provide info about
most = [han for (han, jap, hangul) in sorted([(han, jap, hangul) for (han, (jap, hangul)) in common.items() if jap in most_jp and hangul in most_ko], key=lambda z: most_jp.index(z[1]) + most_ko.index(z[2]))]

#top_jp = [han for (han, jap, hangul) in sorted([(han, jap, hangul) for (han, (jap, hangul)) in common.items() if jap in most_jp and hangul in most_ko], key=lambda z: most_jp.index(z[1]))]
#top_kr = [han for (han, jap, hangul) in sorted([(han, jap, hangul) for (han, (jap, hangul)) in common.items() if jap in most_jp and hangul in most_ko], key=lambda z: most_ko.index(z[2]))]

print('약속' in most_ko)

magic = 500

for han in most[:magic]:
	gen(han)

table = ''

def getTDs(han):
	
	jap, hangul = common[han]
	yomis = kanjigo[jap]
	
	tds  = tag('td', tag('a', han, href='word/%s.html' % han))
	tds += tag('td', hangul)
	tds += tag('td', ''.join(yomis))
	
	return tds

for i in range(magic):
	
	row = ''
	
	row += getTDs(most[i])
	
	table += tag('tr', row)

index = '''
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
'''

open('index.html', 'w').write(index + tag('table', table))