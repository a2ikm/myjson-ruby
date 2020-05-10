#!/usr/bin/env ruby

require_relative "myjson"

def test(expected, source)
  actual = MyJSON.parse(source)
  if expected != actual
    c = caller(2).first
    abort "#{c}: expected #{expected.inspect} but got #{actual.inspect}"
  end
rescue MyJSON::Error => e
  c = caller(2).first
  abort "#{c}: #{e.class} #{e.message}"
end

test 1, '1'
test 12, '12'
test 1, ' 1'
test 1, '1 '
test 1, ' 1 '
test true, 'true'
test false, 'false'
test nil, 'null'
test "a", '"a"'
test "abc", '"abc"'
test "", '""'
test "\"", '"\""'
test [], '[]'
test [1], '[1]'
test [1, 2], '[1,2]'
test [1, 2], '[1, 2]'
test ["a"], '["a"]'
test [[1], 2], '[[1], 2]'
test({}, '{}')
