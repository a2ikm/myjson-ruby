class MyJSON
  Error = Class.new(StandardError)
  UnexpectedCharacter = Class.new(Error)

  def self.parse(json)
    tokens = Lexer.new(json).lex
    Parser.new(tokens).parse
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
          tokens << read_number
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
  end

  class Parser
    def initialize(tokens)
      @tokens = tokens
    end

    def parse
      @pos = 0

      number
    end

    private

    def current
      @tokens[@pos]
    end

    def number
      Integer(current)
    end
  end
end
