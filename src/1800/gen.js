#!/usr/bin/env -S deno run --allow-read

import { readJson } from 'https://deno.land/std/fs/read_json.ts'

const INFILE = Deno.args[0]

await Deno.lstat(INFILE)
	.then(stat => {
		if (!stat.isFile)
			throw 'input file is not a file!'
	})

console.error(`using file [${INFILE}]`)
const data = await readJson(INFILE)

/* takes json file structured like
** [
**     {"hanja":"佳","meaning":"아름다울","hangul":"가"},
**     ...
** ]
*/
const grouped = data.reduce((all, curr) => {

	const { hangul } = curr

	if (all[hangul])
		all[hangul].push(curr)
	else
		all[hangul] = [curr]

	return all

}, {})

const table_data = Object.entries(grouped).map(([hangul, infos]) => {

	const [first, ...rest] = infos.map(({ hanja, meaning, hangul }) =>
		`<td class="character">${hanja}</td><td class="meaning">${meaning} ${hangul}</td>`
	)

	return `<tr><th id="${hangul}" rowspan="${1 + rest.length}">${hangul}</th>${first}<th style="visibility:hidden" rowspan="${1 + rest.length}">${hangul}</th></tr>`
		+ rest.map(contents => `<tr>${contents}</tr>`).join('')

}).join('<tr class="spacing"></tr>')

const nav = Object.keys(grouped).map(hangul => `<a href="#${hangul}">${hangul}</a>`).join(' ')

console.log(`
<style>
body { display: flex; flex-direction: column; align-items: center }
th { font-size: 2em; padding: 0 1em 0 1em }
.meaning { text-align: right }
.character { font-size: 1.5em }
.spacing { height: 2em }
.box { width: 32em; background-color: #eee }
.box, table { padding: 2em; margin: 1em }
</style>

<div class="box">
	<h1>'한문 교육용 기초 한자'</h1>
	<p>these are the 1800 '한문 교육용' hanja I scraped from namuwiki and formatted nicely. have fun!</p>
</div>

<div id="nav" class="box">
	${nav}
</div>

<table>${table_data}</table>`)