#!/usr/bin/env -S deno run --allow-net

/**
*** TODO: switch to unicode proprety regexes when they're available ?
**/

const got = await fetch('https://namu.wiki/w/한문 교육용 기초 한자').then(r => r.text())

const data = [...got.matchAll(/(?<hanja>.)<\/a>\s+\((?<meaning>.+?) (?<hangul>.)\)/g)]
	.map(match => match.groups)

console.error('got: ')
console.error(data)

console.log(JSON.stringify(data))