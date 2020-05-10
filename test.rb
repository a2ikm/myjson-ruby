#!/usr/bin/env ruby

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "json"
end

require "json"
require_relative "myjson"

def test(json)
  expected = JSON.parse(json)
  actual = MyJSON.parse(json)
  if expected != actual
    c = caller(2).first
    abort "#{c}: expected #{expected.inspect} but got #{actual.inspect}"
  end
rescue MyJSON::Error => e
  c = caller(2).first
  abort "#{c}: #{e.class} #{e.message}"
end

test '1'
test '12'
test ' 1'
test '1 '
test ' 1 '
test 'true'
test 'false'
test 'null'
test '"a"'
test '"abc"'
test '""'
test '"\""'
test '"a\"b"'
test '"a\\b"'
test '"a\\\\b"'
test '"a\/b"'
test '"a\bb"'
test '"a\fb"'
test '"a\nb"'
test '"a\rb"'
test '"a\tb"'
test '"a\u1234b"'
test '[]'
test '[1]'
test '[1,2]'
test '[1, 2]'
test '["a"]'
test '[[1], 2]'
test '{}'
test '{"a":1}'
test '{"a": 1, "b": "2"}'
