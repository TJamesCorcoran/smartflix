class Time
  def to_datetime
     DateTime.parse(self.to_s)
  end
end
