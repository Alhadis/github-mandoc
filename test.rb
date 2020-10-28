#!/usr/bin/env ruby

require "./lib/github/mandoc"

head = File.read("header.html")
body = GitHub::Mandoc::render_file "mdoc"
foot = File.read("footer.html")
page = head + body + foot
File.write("index.html", page)
