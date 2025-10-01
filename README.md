# Base85

## Description

A pure Ruby implementation of the general base-85 encoding, which encodes every 4 bytes into 5 other bytes within the given character set.

The performance has been fine-tuned (within pure Ruby, specifically for MRI implementation) to be acceptable for general not-too-large binary data (around 1-10M).

## Usage

To create a converter, specify a string with a length of exactly 85 as the character set.

```ruby
# create a converter with the character set from Ascii85
a85 = Base85.new([*'!'..'u'].join)

a85.encode('hello') # => "BOu!rDZ"
a85.decode('BOu!rDZ') # => "hello"
```

There are pre-defined converters `Base85::Z85`, `Base85::Rfc1924` and `Base85::Ascii85`. For general purposes, it is recommended to use `Base85::Z85`.
