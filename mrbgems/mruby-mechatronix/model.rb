# Questo è un file di prova!!!


class Container
  attr_accessor :name, :match, :content
  attr_accessor :key_converter

  def self.[](hsh)
    raise ArgumentError, "Need a Hash" unless hsh.respond_to? :to_hash
    m = self.new
    hsh.to_hash.each do |k,v|
      m.send("#{k}=".to_sym, v)
    end
    return m
  end

  def initialize(name="My model")
    @name = name
    @match = /^[A-Z]/
    @content= Hash.new
    @key_converter = :to_sym
    return self
  end

  def key_converter=(sym)
    raise RuntimeError, "Either :to_s or :to_sym" unless [:to_s, :to_sym].include? sym
    @key_converter = sym
  end

  def [](key)
    return @content[key.send(@key_converter)]
  end

  def []=(key, value)
    @content[key.send(@key_converter)] = value
  end

  def method_missing name, *args, &block
    unless name.to_s.match(@match)
      raise RuntimeError, "Undefined method #{name}"
    end

    case name.to_s
    when /=$/
      key = name.to_s.chop.to_sym
      @content[key.send(@key_converter)] = args.first
    else
      return @content[name.send(@key_converter)]
    end
  end

  def inspect
    return @content.inspect
  end

  alias :to_hash :content
end


if __FILE__ == $0 then
  puts
  m          = Container.new
  m.Array    = [1,2,3]   # Anche nomi "strani"
  m.Defaults = {
    a:     1,
    n:     m.Array.size,
    c:     [1,2,3],
    avorP: m.Array.reverse
  }
  m.Radius   = m.Array.first * 2
  puts "#{m.name} Radius is #{m.Radius}"
  puts "#{m.name} Array is #{m[:Array]}" # funziona come una Hash
  p m # shortcut per p m.content

  puts
  # È anche possibile cambiare la regola di accettazione delle chiavi:
  m.match = /^_|_={0,1}$/ # => deve cominciare o finire con un undescore
                          #    le assegnazioni terminano con '='
  m._length = 10.0
  m.sides_  = 13
  puts m.sides_
  puts
  p m
  puts

  m.embedded_ = Container["A"=>1, B:2, C:[1,2,3]]
  p m.to_hash
end