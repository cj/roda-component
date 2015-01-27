class Element
  alias_native :val
  alias_native :prepend
  alias_native :serialize_array, :serializeArray
  alias_native :has_class, :hasClass
  alias_native :click
end

class String
  def is_i?
    self.to_i.to_s == self
  end
end
