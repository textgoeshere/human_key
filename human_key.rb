require 'digest/sha1'

# Maps random SHA1 hexdigest to new random string that only contains characters that are not commonly confused with
# other characters. The new string will never contain 0, O, 1, l and other characters that look similar to non-techies in
# common typefaces.
#
# Useful for API keys, one-time access keys, confirmation links etc. especially where the key may have to be spoken.

module Textgoeshere
  class HumanKey
    attr_reader :key, :raw_key, :original_key

    SEED  = 12347890
    CHARS = "2345679qwertyupasdfgjkzxcvbnm"
    DEFAULT_OPTIONS = {
      :chars          => CHARS,
      :splitter       => '-',
      :segment_length => 4,
      :length         => 12,
      :prefix         => nil,
      :suffix         => nil
    # case_sensitive => false
    # case           => :lower
    }

    # Takes same arguments as HumanKey.new but returns only the string not the HumanKey object   
    def self.generate(*args)
      new(args.first).key
    end

    # Returns HumanKey object
    def initialize(*args)
      @options      = DEFAULT_OPTIONS.merge(args.last.is_a?(Hash) ? args.pop : {})
      @original_key = @options[:key] || hex_key
      chars_size    = @options[:chars].size

      @key = @original_key.scan(/./).inject("") do |m, c|
        i = ((i || rand(chars_size)) + c.to_i(16)) % chars_size
        m << @options[:chars][i]
      end

      @raw_key = @key

      if @key.size > @options[:segment_length] && @options[:splitter]
        @key = @key.scan(Regexp.new("\\w{1,#{@options[:segment_length]}}")).join(@options[:splitter])
      end

      @key = [@options[:prefix], @key, @options[:suffix]].compact.join
    end

    private

    def hex_key
      Digest::SHA1.hexdigest(Time.now.to_s + rand(SEED).to_s)[1..@options[:length]]
    end
  end
end


if __FILE__ == $0
  require 'test/unit'
  require 'test/unit/ui/console/testrunner'

  class HumanKeyTest < Test::Unit::TestCase
#    def setup
#    end

#    def teardown
#    end

    def test_length
      length = 25
      assert_equal(Textgoeshere::HumanKey.generate(:length => length, :splitter => false).size, length,
             "It should use an optional length parameter")
    end

    def test_splitter
      splitter            = "#"
      segment_length      = 4
      number_of_segments  = 3
      length              = segment_length * number_of_segments

      regexp              = "([\\w]{#{segment_length}}#{splitter}){#{number_of_segments - 1}}[\\w]{#{segment_length}}"
      key                 = Textgoeshere::HumanKey.generate(:splitter => splitter, :length => length)
      assert_match(Regexp.new(regexp), key,
             "It should optionally split the key into segments separated by a character given by the splitter parameter")
    end

    def test_too_short_for_splitting
      splitter = "#"
      assert_no_match(/#{splitter}/, Textgoeshere::HumanKey.generate(:splitter => splitter, :key => "foo", :segement_length => 99),
             "It should not split the key into segments if the segment length is greater than the key length")
    end

    def test_prefix
      prefix = "a_prefix"
      assert_match(/^#{prefix}/, Textgoeshere::HumanKey.generate(:prefix => prefix),
                   "It should prepend an optional prefix")
    end

    def test_suffix
      suffix = "a_suffix"
      assert_match(/#{suffix}$/, Textgoeshere::HumanKey.generate(:suffix => suffix),
                   "It should append an optional suffix")
    end

    def test_default_original_key
      original_key = "123"
      assert_equal(Textgoeshere::HumanKey.new(:key => original_key).original_key, original_key,
             "It should use an optional original key parameter")
    end
  end
  
  Test::Unit::UI::Console::TestRunner.run(HumanKeyTest)
end