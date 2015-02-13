class NavigableHash < Hash

  def initialize(constructor = {}, &block)
    if block_given?
      yield self
    elsif constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end

  alias_method :get_value, :[] unless method_defined?(:get_value)
  alias_method :set_value, :[]= unless method_defined?(:set_value)

  def ==(other_hash)
    to_hash == self.class.new(other_hash).to_hash
  end

  # Assigns a new value to the hash:
  #
  #   hash = NavigableHash.new
  #   hash[:key] = "value"
  #
  def []=(key, value)
    set_value convert_key(key), navigate(value)
  end

  alias :store :[]=

  def [](key)
    get_value convert_key(key)
  end

  # Removes a specified key from the hash.
  def delete(key)
    super(convert_key(key))
  end

  # Returns an exact copy of the hash.
  def dup
    self.class.new to_hash
  end

  # Same as <tt>Hash#fetch</tt> where the key passed as argument can be
  # either a string or a symbol:
  #
  #   counters = NavigableHash.new
  #   counters[:foo] = 1
  #
  #   counters.fetch("foo")          # => 1
  #   counters.fetch(:bar, 0)        # => 0
  #   counters.fetch(:bar) {|key| 0} # => 0
  #   counters.fetch(:zoo)           # => KeyError: key not found: "zoo"
  #
  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  # Checks the hash for a key matching the argument passed in:
  #
  #   hash = NavigableHash.new
  #   hash["key"] = "value"
  #   hash.key? :key  # => true
  #   hash.key? "key" # => true
  #
  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  # Merges the instantiated and the specified hashes together, giving precedence to the values from the second hash.
  # Does not overwrite the existing hash.
  def merge(hash)
    self.dup.update(hash)
  end

  def respond_to?(m, include_private = false)
    has_key?(m) || super
  end

  def to_hash
    reduce({}) do |hash, (key, value)|
      hash.merge key.to_sym => convert_for_to_hash(value)
    end
  end

  # Updates the instantized hash with values from the second:
  #
  #   hash_1 = NavigableHash.new
  #   hash_1[:key] = "value"
  #
  #   hash_2 = NavigableHash.new
  #   hash_2[:key] = "New Value!"
  #
  #   hash_1.update(hash_2) # => {"key"=>"New Value!"}
  #
  def update(other_hash)
    other_hash.reduce(self) { |hash, (k, v)| hash[k] = navigate(v) ; hash }
  end

  alias_method :merge!, :update

  # Returns an array of the values at the specified indices:
  #
  #   hash = NavigableHash.new
  #   hash[:a] = "x"
  #   hash[:b] = "y"
  #   hash.values_at("a", "b") # => ["x", "y"]
  #
  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  protected :get_value, :set_value

  def convert_for_to_hash(value)
    case value
    when NavigableHash
      convert_navigable_hash_for_to_hash value
    when Array
      convert_array_for_to_hash value
    else
      convert_value_for_to_hash value
    end
  end

  def convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end

  def convert_navigable_hash_for_to_hash(value)
    value.to_hash
  end

  def convert_array_for_to_hash(value)
    value.map { |item| convert_for_to_hash item }
  end

  def convert_value_for_to_hash(value)
    value
  end

  def navigate value
    case value
    when self.class
      value
    when Hash
      navigate_hash value
    when Array
      navigate_array value
    else
      navigate_value value
    end
  end

  def navigate_hash(value)
    self.class.new value
  end

  def navigate_array(value)
    value.map { |item| navigate item }
  end

  def navigate_value(value)
    value
  end

  def navigate_hash_from_block(key, &block)
    self[key] = self.class.new &block
  end

  private

  def set_and_cache_value(key, value)
    cache_getter! key
    self[key] = value
  end

  def get_and_cache_value(key)
    cache_getter! key
    self[key]
  end

  def cache_getter!(key)
    define_singleton_method(key) { self[key] } unless respond_to? key
  end

  def method_missing(m, *args, &block)
    m = m.to_s
    if m.chomp!('=') && args.count == 1
      set_and_cache_value(m, *args)
    elsif args.empty? && block_given?
      self.navigate_hash_from_block m, &block
    elsif args.empty?
      get_and_cache_value(m)
    else
      fail ArgumentError, "wrong number of arguments (#{args.count} for 0)"
    end
  end

end
