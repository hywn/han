import html

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

hanjaeo = {han: (hangul, english) for (han, hangul, english, junk) in [line.split('|') for line in hanjaeo]}
variants = {jap: trad for (trad, jap) in [line.split('\t') for line in variants]}

# gets all japanese words that are entirely kanji
kanjigo = {jap: [z.split(':')[1] for z in furig.split(';')] for (jap, reading, furig) in [line.split('|') for line in furiganas] if all([char in hanjas or char in variants for char in jap])}

# gets all kanjigo in traditional characters, list of (trad, jap)
trad_kanjigo = [(''.join([variants[char] if char in variants else char for char in word]), word) for word in kanjigo]

# gets all trad_kanjigo that are also hanjaeo
common = {trad: (jap, hanjaeo[trad][0]) for (trad, jap) in trad_kanjigo if trad in hanjaeo and len(trad) == 2}

## TODO: sort by commonality in japanese OR korean
## TODO: fix ugly hanja definitions like 문서 권

style = style = '<link rel="stylesheet" href="han.css">'

def gen(trad):

	jap, hangul = common[trad]
	
	dmas = [(hangul[i], hanjas[trad[i]][hangul[i]]) for i in range(len(trad))] # [(dma, Emt)...]
	yomis = kanjigo[jap] # [yomi...]
	
	z = ''
	
	z += html.row(''.join([html.box(char) for char in trad]), 'kr')

	z += html.row(''.join([html.slide(yomis[i], jap[i]) if jap[i] != trad[i] else html.box(yomis[i]) for i in range(len(jap))]), 'jp')
	
	z += html.row(''.join([html.slide(dma, Emt) for (dma, Emt) in dmas]), 'kr')
	
	open(trad + '.html', 'w').write(style + html.div(z, id='contents'))

gen('家族')
gen('寫眞')
gen('約束')