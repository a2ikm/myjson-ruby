class MyJSON
  Error = Class.new(StandardError)
  UnexpectedCharacter = Class.new(Error)
  UnexpectedToken = Class.new(Error)
  NoValue = Class.new(Error)

  def self.parse(json)
    tokens = Lexer.new(json).lex
    Parser.new(tokens).parse
  end

  class Token
    attr_reader :type, :string

    def initialize(type, string)
      @type = type
      @string = string
    end

    def inspect
      "#<%s:%s @type=%s @string=%s>" % [
        self.class.name,
        object_id,
        @type.to_s,
        @string.inspect,
      ]
    end
  end

  class Lexer
    WHITESPACES = [" ", "\n", "\r", "\t"].freeze
    DIGITS = ("0".."9").to_a.freeze
    SYMBOLS = ["[", "]", "{", "}", ",", ":"].freeze
    ESCAPE_MAP = {
      '"'   => '"',
      '\\'  => '\\',
      '/'   => "\/",
      'b'   => "\b",
      'f'   => "\f",
      'n'   => "\n",
      'r'   => "\r",
      't'   => "\t",
    }.freeze

    def initialize(json)
      @json = json
      @len = @json.length
    end

    def lex
      @pos = 0
      tokens = []

      until eos?
        case
        when skip_whitespace
          next
        when symbol?(current)
          tokens << Token.new(:symbol, read_symbol)
          next
        when current == '"'
          tokens << Token.new(:string, read_string)
          next
        when digit?(current)
          tokens << Token.new(:number,  read_number)
          next
        when alphabet?(current)
          tokens << Token.new(:keyword, read_keyword)
          next
        else
          raise UnexpectedCharacter, "unexpected character #{current.inspect}"
        end
      end

      tokens
    end

    private

    def eos?
      @len <= @pos
    end

    def advance
      @pos += 1
    end

    def current
      @json[@pos]
    end

    def peek
      @json[@pos+1]
    end

    def whitespace?(c)
      WHITESPACES.include?(c)
    end

    def skip_whitespace
      skipped = false
      while whitespace?(current)
        skipped = true
        advance
      end
      skipped
    end

    def symbol?(c)
      SYMBOLS.include?(c)
    end

    def read_symbol
      c = current
      advance
      c
    end

    def digit?(c)
      DIGITS.include?(c)
    end

    def read_number
      start = @pos

      while digit?(peek)
        advance
      end

      number = @json[start..@pos]
      advance
      number
    end

    def alphabet?(c)
      /[a-z]/.match?(c)
    end

    def read_keyword
      start = @pos

      while alphabet?(peek)
        advance
      end

      keyword = @json[start..@pos]
      advance
      keyword
    end

    def read_string
      advance

      string = String.new

      loop do
        if current == '"'
          advance
          break
        elsif current == '\\'
          if ESCAPE_MAP.key?(peek)
            string += ESCAPE_MAP[peek]
          elsif peek == "u" && m = @json[@pos+2, 4].match(/\A[0-9a-fA-F]{4}\z/)
            string += Integer("0x#{m[0]}").chr(Encoding::UTF_8)
            4.times { advance }
          else
            string += peek
          end
          advance
          advance
        else
          string += current
          advance
        end
      end

      string
    end
  end

  class Parser
    KEYWORD_MAP = {
      "true"  => true,
      "false" => false,
      "null"  => nil,
    }.freeze

    def initialize(tokens)
      @tokens = tokens
    end

    def parse
      @pos = 0

      value!
    end

    private

    def advance
      @pos += 1
    end

    def current
      @tokens[@pos]
    end

    def expect_symbol(symbol)
      if current.type == :symbol && current.string == symbol
        token = current
        advance
        token
      else
        raise UnexpectedToken, "expected symbol #{symbol} but got #{current.inspect}"
      end
    end

    def consume_type(type)
      if current.type == type
        token = current
        advance
        token
      end
    end

    def consume_symbol(symbol)
      if current.type == :symbol && current.string == symbol
        token = current
        advance
        token
      end
    end

    def value
      v, ok = object
      return v, ok if ok

      v, ok = array
      return v, ok if ok

      v, ok = number
      return v, ok if ok

      v, ok = string
      return v, ok if ok

      v, ok = keyword
      return v, ok if ok

      return nil, false
    end

    def value!
      v, ok = value
      raise NoValue unless ok
      v
    end

    def object
      return nil, false unless token = consume_symbol("{")

      o = {}
      unless consume_symbol("}")
        k, v = pair
        o[k] = v
        while consume_symbol(",")
          k, v = pair
          o[k] = v
        end
        expect_symbol("}")
      end

      return o, true
    end

    def pair
      k, ok = string
      raise UnexpectedToken, "expected string but got #{current.inspect}" unless ok

      expect_symbol(":")
      v = value!

      return k, v
    end

    def array
      return nil, false unless token = consume_symbol("[")

      a = []
      unless consume_symbol("]")
        a << value!
        while consume_symbol(",")
          a << value!
        end
        expect_symbol("]")
      end

      return a, true
    end

    def number
      return nil, false unless token = consume_type(:number)
      return Integer(token.string), true
    end

    def string
      return nil, false unless token = consume_type(:string)
      return token.string, true
    end

    def keyword
      return nil, false unless token = consume_type(:keyword)

      if KEYWORD_MAP.key?(token.string)
        return KEYWORD_MAP[token.string], true
      else
        raise UnexpectedToken, "expected one of (#{KEYWORD_MAP.join(", ")}) but got #{token.string}"
      end
    end
  end
end
