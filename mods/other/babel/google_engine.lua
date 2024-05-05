local httpapi

function babel.register_http(hat)
	httpapi = hat
end

babel.engine = "TRANSLATOR" -- used for tagging messages

babel.langcodes = {
	af = "Afrikaans",
	sq = "Albanian",
	am = "Amharic",
	ar = "Arabic",
	hy = "Armenian",
	az = "Azerbaijan",
	ba = "Bashkir",
	eu = "Basque",
	be = "Belarusian",
	bn = "Bengali",
	bs = "Bosnian",
	bg = "Bulgarian",
	ca = "Catalan",
	ceb = "Cebuano",
	zh = "Chinese",
	hr = "Croatian",
	cs = "Czech",
	da = "Danish",
	nl = "Dutch",
	en = "English",
	eo = "Esperanto",
	et = "Estonian",
	fi = "Finnish",
	fr = "French",
	gl = "Galician",
	ka = "Georgian",
	de = "German",
	el = "Greek",
	gu = "Gujarati",
	ht = "Haitian",
	he = "Hebrew",
	mrj = "Hill",
	hi = "Hindi",
	hu = "Hungarian",
	is = "Icelandic",
	id = "Indonesian",
	ga = "Irish",
	it = "Italian",
	ja = "Japanese",
	jv = "Javanese",
	kn = "Kannada",
	kk = "Kazakh",
	ko = "Korean",
	ky = "Kyrgyz",
	la = "Latin",
	lv = "Latvian",
	lt = "Lithuanian",
	mk = "Macedonian",
	mg = "Malagasy",
	ms = "Malay",
	ml = "Malayalam",
	mt = "Maltese",
	mi = "Maori",
	mr = "Marathi",
	mhr = "Mari",
	mn = "Mongolian",
	ne = "Nepali",
	no = "Norwegian",
	pap = "Papiamento",
	fa = "Persian",
	pl = "Polish",
	pt = "Portuguese",
	pa = "Punjabi",
	ro = "Romanian",
	ru = "Russian",
	gd = "Scottish",
	sr = "Serbian",
	si = "Sinhala",
	sk = "Slovakian",
	sl = "Slovenian",
	es = "Spanish",
	su = "Sundanese",
	sw = "Swahili",
	sv = "Swedish",
	tl = "Tagalog",
	tg = "Tajik",
	ta = "Tamil",
	tt = "Tatar",
	te = "Telugu",
	th = "Thai",
	tr = "Turkish",
	udm = "Udmurt",
	uk = "Ukrainian",
	ur = "Urdu",
	uz = "Uzbek",
	vi = "Vietnamese",
	cy = "Welsh",
	xh = "Xhosa",
	yi = "Yiddish",
}

local function urlencode(url)
	if url == nil then
		return
	end
	url = url:gsub("\n", "\r\n")
	url = url:gsub(".", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	return url
end

function babel.translateGoogle(self, phrase, lang, handler)
	local apiurl = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
	local transurl = apiurl .. babel.sanitize(lang) .. "&dt=t&q=" .. urlencode(phrase)

	httpapi.fetch({url = transurl}, function(htresponse)
		if htresponse.succeeded then
			local response_data = minetest.parse_json(htresponse.data)
			if response_data and response_data[1] then
				local sentences = ""
				for k = 1, #response_data[1] do
					sentences = sentences .. response_data[1][k][1] -- Merge the sentences in one line
				end
				handler(sentences)
			else
				handler("Failed request")
				minetest.log("error", "Error on requesting, received invalid data: " .. dump(htresponse))
			end
		else
			handler("Failed request")
			minetest.log("error", "Error on requesting: " .. dump(htresponse))
		end
	end)
end
