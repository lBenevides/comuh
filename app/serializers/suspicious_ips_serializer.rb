class SuspiciousIpsSerializer
  def initialize(suspicious_ips)
    @suspicious_ips = suspicious_ips
  end

  def as_json(*)
    {
      suspicious_ips: @suspicious_ips
    }
  end
end
