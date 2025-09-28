class Base85
  P, P2, P3, P4 = 85, 85 ** 2, 85 ** 3, 85 ** 4
  B, B4 = 256, 256 ** 4

  attr_reader :chars

  def initialize(chars)
    @chars = -chars

    f = chars.bytes
    if f.size != 85 || f.uniq.size != f.size
      raise ArgumentError
    end
    f.freeze
    @forward_table = f

    g = Array.new(256)
    f.each_with_index do |v, i|
      g[v] = i
    end
    g.freeze
    @backward_table = g
  end

  def encode(str)
    enc = str.encoding
    t = str.b

    l = t.size
    if l % 4 != 0
      t += "\0" * (4 - l % 4)
    end

    f = @forward_table
    s = String.new(capacity: t.size / 4 * 5)
    t.unpack('N*') do |v|
      s << f[v / P4] \
        << f[v / P3 % P] \
        << f[v / P2 % P] \
        << f[v / P % P] \
        << f[v % P]
    end
    s[s.size - (t.size - l)..] = ''

    if enc.ascii_compatible?
      s.force_encoding(enc)
    end
    s
  end

  def decode(str)
    enc = str.encoding
    s = str.b

    l = s.size
    if l % 5 == 1
      raise ArgumentError, 'illegal length'
    end
    if l % 5 != 0
      s += @forward_table[84].chr * (5 - l % 5)
    end
    s = s.bytes

    g = @backward_table
    r = []
    0.step(s.size - 1, 5) do |i|
      begin
        v = g[s[i]] * P4 \
          + g[s[i + 1]] * P3 \
          + g[s[i + 2]] * P2 \
          + g[s[i + 3]] * P \
          + g[s[i + 4]]
      rescue NoMethodError
        raise ArgumentError, 'invalid char'
      end
      if v >= B4
        raise ArgumentError, 'invalid value'
      end
      r << v
    end

    m = s.size - l
    if m != 0 && r[-1] % B ** m >= P ** m
      raise ArgumentError, 'bad representation'
    end
    t = r.pack('N*')
    t[t.size - m..] = ''

    t.force_encoding(enc)
    if !t.valid_encoding?
      t.force_encoding(Encoding::ASCII_8BIT)
    end
    t
  end

  Z85 = new(%w[
    0123456789
    abcdefghij
    klmnopqrst
    uvwxyzABCD
    EFGHIJKLMN
    OPQRSTUVWX
    YZ.-:+=^!/
    *?&<>()[]{
    }@%$#
  ].join)
end
