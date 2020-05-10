#!/usr/bin/env ruby

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
test '[]'
test '[1]'
test '[1,2]'
test '[1, 2]'
test '["a"]'
test '[[1], 2]'
test '{}'
test '{"a":1}'
test '{"a": 1, "b": "2"}'
