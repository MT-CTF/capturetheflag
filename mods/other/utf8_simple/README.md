# lua-utf8-simple

This "library" is meant to be a very thin helper that you can easily drop in to another project without really calling it a dependency.  It aims to provide the most minimal of handling functions for working with utf8 strings.  It does not aim to be feature-complete or even error-descriptive.  It works for what is practical but not complex.  You have been warned. =^__^=

## The require() Line

```lua
local utf8 = require('utf8_simple')
```

## The Only Functions You Need to Know

### utf8.chars(s[, no_subs])
- s: (string) the utf8 string to iterate over (by characters)
- nosubs: (boolean) true turns the substring utf8 characters into byte-lengths

```lua
-- i is the character/letter index within the string
-- c is the utf8 character (string of 1 or more bytes)
-- b is the byte index within the string
for i, c, b in utf8.chars('Αγαπώ τηγανίτες') do
	print(i, c, b)
end
```

Output:

	1	Α	1
	2	γ	3
	3	α	5
	4	π	7
	5	ώ	9
	6		11
	7	τ	12
	8	η	14
	9	γ	16
	10	α	18
	11	ν	20
	12	ί	22
	13	τ	24
	14	ε	26
	15	ς	28

### ALTERNATE FORM
Creating small substrings can be a performance concern, the 2nd parameter to utf8.chars()
allows you to toggle the substrings to instead by the byte width of the character.

This is for situations when you only care about the byte width (less common).

```lua
-- i is the character/letter index within the string
-- w is the utf8 character width (in bytes)
-- b is the byte index within the string
for i, w, b in utf8.chars('Αγαπώ τηγανίτες', true) do
	print(i, w, b)
end
```

Output:

	1	2	1
	2	2	3
	3	2	5
	4	2	7
	5	2	9
	6	1	11
	7	2	12
	8	2	14
	9	2	16
	10	2	18
	11	2	20
	12	2	22
	13	2	24
	14	2	26
	15	2	28

### utf8.map(s, f[, no_subs])
- s: (string) the utf8 string to map 'f' over
- f: (function) a function accepting: f(visual_index, utf8_char -or- width, byte_index)
- no_subs: (boolean) true means don't make small substrings from each character (byte width instead)

returns: (nothing)

```lua
> utf8.map('Αγαπώ τηγανίτες', print) -- does the same as the first example above
```

```lua
> utf8.map('Αγαπώ τηγανίτες', print, true) -- the alternate form from above
```

## Others

### utf8.len(s)
- s: (string) the utf8 string

returns: (number) the number of utf8 characters in s (not the byte length)

note: be aware of "invisible" utf8 characters

```lua
> = utf8.len('Αγαπώ τηγανίτες')
15
```

### utf8.reverse(s)
- s: (string) the utf8 string

returns: (string) the utf8-reversed form of s

note: reversing left-to-right utf8 strings that include directional formatting characters will look odd

```lua
> = utf8.reverse('Αγαπώ τηγανίτες')
ςετίναγητ ώπαγΑ
```

### utf8.strip(s)
- s: (string) the utf8 string

returns: (string) s with all non-ascii characters removed (characters > 1 byte)

```lua
> = utf8.strip('cat♥dog')
catdog
```

### utf8.replace(s, map)
- s: (string) the utf8 string
- map: (table) keys are utf8 characters to replace, values are their replacement

returns: (string) s with all the key-characters in map replaced

note: the keys must be utf8 characters, the values **can** be strings

```lua
> = utf8.replace('∃y ∀x ¬(x ≺ y)', { ['∃'] = 'E', ['∀'] = 'A', ['¬'] = '\r\n', ['≺'] = '<' })
Ey Ax 
(x < y)
```

### utf8.sub(s, i, j)
- s: (string) the utf8 string
- i: (string) the starting index in the utf8 string
- j: (stirng) the ending index in the utf8 string

returns: (string) the substring formed from i to j, inclusive (this is a utf8-aware string.sub())

```lua
> = utf8.sub('Αγαπώ τηγανίτες', 3, -5)
απώ τηγαν
```
