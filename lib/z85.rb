module GeneralBase85
  P, P2, P3, P4 = 85, 85 ** 2, 85 ** 3, 85 ** 4
  B, B4 = 256, 256 ** 4

  def self.new(chars)
    f = chars.unpack('C*')
    if f.size != 85 || f.uniq.size != f.size
      raise ArgumentError
    end
    f.freeze

    g = {}
    f.each_with_index do |v, i|
      g[v] = i
    end
    g.freeze

    mod = self
    Module.new do
      include mod
      define_method(:forward_table) { f }
      define_method(:backward_table) { g }
    end
  end

  def encode(str)
    enc = str.encoding
    str = str.b

    l = str.size
    while str.size % 4 != 0
      str << 0
    end

    digits = []
    str.unpack('N*').each do |v|
      # 'N' for big-endian u32
      a = v / P4
      b = v / P3 % P
      c = v / P2 % P
      d = v / P % P
      e = v % P
      digits.push(a, b, c, d, e)
    end
    digits.pop(str.size - l)

    f = forward_table
    char_codes = digits.map { |v| f[v] }
    encoded = char_codes.pack('C*')

    if enc.ascii_compatible?
      encoded.force_encoding(enc)
    end
    encoded
  end

  def decode(str)
    l = str.bytesize
    if l % 5 == 1
      raise ArgumentError, 'illegal length'
    end

    g = backward_table
    digits = str.each_byte.map { |v|
      i = g[v]
      if i == nil
        raise ArgumentError, 'invalid char'
      end
      i
    }

    while digits.size % 5 != 0
      digits << 84
    end

    values = []
    digits.each_slice(5) do |a, b, c, d, e|
      v = a * P4 + b * P3 + c * P2 + d * P + e
      if v >= B4
        raise ArgumentError, 'invalid value'
      end
      values << v
    end

    m = digits.size - l
    if m == 0
      decoded = values.pack('N*')
    else
      last = values.pop
      if last % B ** m >= P ** m
        raise ArgumentError, 'bad representation'
      end
      decoded = values.pack('N*')
      decoded << [last].pack('N')[0, 4 - m]
    end

    decoded.force_encoding(str.encoding)
    if !decoded.valid_encoding?
      decoded.force_encoding(Encoding::ASCII_8BIT)
    end
    decoded
  end
end

module Z85
  CHARS = %w[
    0123456789
    abcdefghij
    klmnopqrst
    uvwxyzABCD
    EFGHIJKLMN
    OPQRSTUVWX
    YZ.-:+=^!/
    *?&<>()[]{
    }@%$#
  ].join.freeze

  extend GeneralBase85.new(CHARS)
end
