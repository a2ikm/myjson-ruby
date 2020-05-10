class MyJSON
  Error = Class.new(StandardError)
  UnexpectedCharacter = Class.new(Error)
  UnknownKeyword = Class.new(Error)

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

    def value
      number || keyword
    end

    def number
      return nil unless token = consume_type(:number)
      Integer(token.string)
    end

    def keyword
      return nil unless token = consume_type(:keyword)
      case token.string
      when "true"
        true
      when "false"
        false
      else
        raise UnknownKeyword, "`#{token.string}`"
      end
    end
  end
end
