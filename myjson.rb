class MyJSON
  Error = Class.new(StandardError)
  UnexpectedCharacter = Class.new(Error)
  UnknownKeyword = Class.new(Error)
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
  end

  class Lexer
    WHITESPACES = [" ", "\n", "\r", "\t"].freeze
    DIGITS = ("0".."9").to_a.freeze
    SYMBOLS = ["[", "]"].freeze

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
          raise UnexpectedCharacter
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
      start = @pos

      loop do
        if current == '"'
          break
        elsif current == '\\' && peek == '"'
          advance
          advance
        else
          advance
        end
      end

      # @pos indicates closing quotation
      string = @json[start...@pos].gsub('\"', '"')
      advance
      string
    end
  end

  class Parser
    def initialize(tokens)
      @tokens = tokens
    end

    def parse
      @pos = 0

      value
    end

    private

    def advance
      @pos += 1
    end

    def current
      @tokens[@pos]
    end

    def expect_type(type)
      if current.type == type
        token = current
        advance
        token
      else
        raise UnexpectedToken, "expected #{type} but got #{current.type}"
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
      if (token = consume_type(:symbol)) && token.string == symbol
        token
      end
    end

    def value
      v, ok = array
      return v if ok

      v, ok = number
      return v if ok

      v, ok = string
      return v if ok

      v, ok = keyword
      return v if ok

      raise NoValue
    end

    def array
      return nil, false unless token = consume_symbol("[")

      array = []
      loop do
        if consume_symbol("]")
          break
        end
      end

      return array, true
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

      v = case token.string
      when "true"
        true
      when "false"
        false
      when "null"
        nil
      else
        raise UnknownKeyword, "`#{token.string}`"
      end

      return v, true
    end
  end
end
