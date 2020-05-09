#!/usr/bin/env ruby

require_relative "myjson"

def test(expected, source)
  actual = MyJSON.parse(source)
  if expected != actual
    c = caller(1).first
    abort "#{c}: expected #{expected} but got #{actual}"
  end
end

test 1, "1"
test 12, "12"
