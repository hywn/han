def tag(dom, contents='', cls=None, **kwargs):
	if cls is not None:
		kwargs['class'] = cls
	return '<{} {}>{}</{}>'.format(dom, ' '.join(['{}="{}"'.format(k, v) for k, v in kwargs.items()]), contents, dom)
def div(contents='', cls=None, **kwargs):
	return tag('div', contents, cls, **kwargs)
def p(contents='', cls=None, **kwargs):
	return tag('p', contents, cls, **kwargs)

def box(text):
	return '<div class="centered slide"><p>%s</p></div>' % text
def slide(shown, hidden):
	return '<div class="slide"><div class="centered slidee"><p>%s</p></div><div class="centered slidee"><p>%s</p></div></div>' % (hidden, shown)
def row(contents, font):
	return div(contents, 'row ' + font)