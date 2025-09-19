require 'z85'

describe Z85 do
  it 'preserves encoding' do
    assert_invertible "\x86\x4F\xD2\x6F\xB5\x59\xF7\x5B".b, 'HelloWorld'.b
    assert_invertible "\0\0\0\0", '00000'
  end

  it 'handles lengths not divisible by four' do
    assert_invertible "\0", '00'
    assert_invertible "\0\0", '000'
    assert_invertible "\0\0\0", '0000'
    assert_invertible 'a', 've'
    assert_invertible 'aa', 'vpo'
    assert_invertible 'aaa', 'vprN'
  end

  it 'handles multibyte characters' do
    assert_invertible "\u304a\u3084\u3059\u307f", '<ai9FF}SfnND5>k'
    assert_invertible "\u3053\u3093\u306b\u3061\u306f", '<aiAOF%kkCTk!=8<ajx'
  end

  describe 'the decoder' do
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

    def assert_rejects(ascii)
      assert_raises(ArgumentError) { Z85.decode(ascii) }
    end
  end

  def assert_invertible(binary, ascii)
    assert_equal ascii, Z85.encode(binary)
    assert_equal binary, Z85.decode(ascii)
  end
end
