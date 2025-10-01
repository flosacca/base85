# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/spec'
require 'base85'

describe Base85 do
  def self.assertions(codec)
    Module.new do
      define_method(:assert_bidirectional) do |binary, ascii|
        assert_equal ascii, codec.encode(binary)
        assert_equal binary, codec.decode(ascii)
      end

      define_method(:assert_invertible) do |binary|
        assert_equal binary, codec.decode(codec.encode(binary))
      end

      define_method(:assert_rejects) do |ascii|
        assert_raises(ArgumentError) { codec.decode(ascii) }
      end
    end
  end

  describe :Z85 do
    include assertions(Base85::Z85)

    it 'preserves encoding' do
      assert_bidirectional '', ''
      assert_bidirectional ''.b, ''.b
      assert_bidirectional "\0\0\0\0", '00000'
      assert_bidirectional "\x86\x4F\xD2\x6F\xB5\x59\xF7\x5B".b, 'HelloWorld'.b
    end

    it 'handles lengths not divisible by four' do
      assert_bidirectional "\0", '00'
      assert_bidirectional "\0\0", '000'
      assert_bidirectional "\0\0\0", '0000'
      assert_bidirectional 'a', 've'
      assert_bidirectional 'aa', 'vpo'
      assert_bidirectional 'aaa', 'vprN'
    end

    it 'handles multibyte characters' do
      assert_bidirectional "\u304a\u3084\u3059\u307f", '<ai9FF}SfnND5>k'
      assert_bidirectional "\u3053\u3093\u306b\u3061\u306f", '<aiAOF%kkCTk!=8<ajx'
    end

    it 'handles random bytes' do
      10.times do
        assert_invertible Array.new(rand(1000)) { rand(256) }.pack('C*')
      end
    end

    describe 'decoder' do
      it 'rejects non-canonical representations' do
        assert_rejects '02'
        assert_rejects 'vf'
        assert_rejects 'vpp'
        assert_rejects 'vprO'
      end

      it 'rejects illegal lengths' do
        assert_rejects 'a'
      end

      it 'rejects unexpected characters' do
        assert_rejects '"""""'
      end

      it 'fails on a representaion of a too-big value' do
        assert_rejects '#####'
      end
    end
  end

  describe :Rfc1924 do
    include assertions(Base85::Rfc1924)

    it 'respects its character set' do
      assert_bidirectional 'HelloWorld', 'NM&qnZ&z<}Y-9'
      assert_bidirectional "\x36\x60\xe3\x0d\x65\x6b\x07\xf9".b, 'HelloWorld'.b
    end
  end

  describe :Ascii85 do
    include assertions(Base85::Ascii85)

    it 'respects its character set' do
      assert_bidirectional 'HelloWorld', '87cURDc^jtCh*'
      assert_bidirectional "\x7b\xdd\xcb\xd3\xaa\xe7\xf0\xbf".b, 'HelloWorld'.b
    end

    it 'handles special "z"s' do
      assert_bidirectional "\0\0\0\0".b * 4, 'z'.b * 4
      assert_bidirectional "\x2e\xab\xc6\x5f\0\0\0\0".b, '0!!!!z'.b
    end
  end

  it 'accepts any base85 representation' do
    binary = (0...85).map { |i| 85 ** 4 + i }.pack('N*')
    10.times do
      codec = Base85.new([*0...256].sample(85).pack('C*'))
      encoded = codec.encode(binary)
      decoded = codec.decode(encoded)
      assert_equal binary, decoded
      assert_equal codec.chars, encoded.unpack('x4a' * 85).join
    end
  end
end
