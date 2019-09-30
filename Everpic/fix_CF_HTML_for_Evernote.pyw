#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Problem to solve:
If CF_HTML content has </span> at start of line, and you paste that into Evernote,
Evernote will drop the line break there. The workaround is to swap \n and <span> ,
and add an extra <br> .

Example:

<pre>
foo<span>text

</span>bar
</pre>

will be changed to:

<pre>
foo<span>text</span>

bar
</pre>

"""

import os
import sys
import re
#import win32api
import win32clipboard as wc

CF_HTML = wc.RegisterClipboardFormat("HTML Format")

def cfhtml_update_field(cftext, fieldname, matchstr, is_match_start):
	matchpos = cftext.find(matchstr)
	if(matchpos<0):
		# print 'Bad, matchpos<0'
		return cftext
	
	if(not is_match_start):
		matchpos += len(matchstr)
	
	newposstr = "%010d"%(matchpos)
	# print "%s=%s"%(fieldname,newposstr)
	ret = re.sub(
		r'^%s:([0-9]{10})'%(fieldname), 
		r'%s:%s'%(fieldname, newposstr), 
		cftext, 
		1, # substitute only 1 time
		re.MULTILINE)
	return ret


def span_space_to_nbsp(r):
	return r.group(1) + r.group(2).replace(' ', '&nbsp;') + r.group(3)

def linenums_extra(htexti):
	htexto = htexti.replace('<li', '<br>\n<li')
	if(htexto==htexti):
		return htexto
	# Replace all space-chars inside <li>...</li> tag to &nbsp;
	# because Evernote 5 does not seem to recognize css-style "white-space: pre" .
	result = re.sub(r'(<span.*?>)(.+?)(</span>)', span_space_to_nbsp, htexto)
	return result

def do_fix():
	if(not wc.IsClipboardFormatAvailable(CF_HTML)):
		sys.stderr.write('No CF_HTML content in clipboard, nothing to do.\n')
		exit(101)

	wc.OpenClipboard()

	htexti = wc.GetClipboardData(CF_HTML)
	htexto = ""

	while True:
		htexto = htexti.replace('\n</span>', '</span><br>\n')
		if htexto==htexti:
			break
		else:
			htexti = htexto

	# For "linenums" css-class, we need extra process:
	htexto = linenums_extra(htexto)

	# Update CF_HTML header field values.
	# Must do this, otherwise, some text gets truncated at end when pasting into Evernote.
	htexto = cfhtml_update_field(htexto, "EndHTML", "</html>", False)
	htexto = cfhtml_update_field(htexto, "EndFragment", "<!--EndFragment-->", False)

	# print "@@@@@@@@@@", htexto
	wc.SetClipboardData(CF_HTML, htexto)

	wc.CloseClipboard()


do_fix()
