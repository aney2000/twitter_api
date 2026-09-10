require "ipaddr"
require "resolv"
require "uri"

# Guards outbound fetches against SSRF: only http(s) URLs whose host resolves
# exclusively to public IP addresses are considered safe. IP literals are
# checked directly (no DNS), so cloud-metadata and private addresses are
# rejected even when passed literally.
class UrlSafety
  BLOCKED_RANGES = [
    "0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8",
    "169.254.0.0/16", "172.16.0.0/12", "192.168.0.0/16",
    "::1/128", "fc00::/7", "fe80::/10"
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  def initialize(resolver: Resolv)
    @resolver = resolver
  end

  def safe?(url)
    uri = URI.parse(url)
    return false unless uri.is_a?(URI::HTTP) && uri.host.present?

    addresses = resolve(uri.host)
    addresses.any? && addresses.all? { |ip| public_address?(ip) }
  rescue URI::InvalidURIError
    false
  end

  private

  def resolve(host)
    literal = to_ipaddr(host)
    return [ literal ] if literal

    @resolver.getaddresses(host).filter_map { |address| to_ipaddr(address) }
  end

  def to_ipaddr(value)
    IPAddr.new(value)
  rescue IPAddr::InvalidAddressError
    nil
  end

  def public_address?(ip)
    BLOCKED_RANGES.none? { |range| range.include?(ip) }
  end
end
