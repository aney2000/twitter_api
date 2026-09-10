require "open-uri"
require "uri"

# Fetches an HTTP(S) body while defending against SSRF and resource exhaustion:
#   * every URL (including each redirect hop) must pass UrlSafety;
#   * automatic redirect following is disabled and handled manually so each hop
#     is re-validated;
#   * open/read timeouts bound slow hosts;
#   * a byte limit rejects oversized responses (when Content-Length is known)
#     and caps how much is read into memory.
# Returns the body String, or nil on any failure.
class SafeHttpFetcher
  class UnsafeUrl < StandardError; end
  class ResponseTooLarge < StandardError; end

  MAX_REDIRECTS = 3
  MAX_BYTES = 2_000_000
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5

  def initialize(url_safety: UrlSafety.new, logger: Rails.logger,
                 open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT,
                 max_redirects: MAX_REDIRECTS, max_bytes: MAX_BYTES)
    @url_safety = url_safety
    @logger = logger
    @open_timeout = open_timeout
    @read_timeout = read_timeout
    @max_redirects = max_redirects
    @max_bytes = max_bytes
  end

  def fetch(url)
    follow(url, @max_redirects)
  rescue StandardError => e
    @logger.error "Failed to fetch #{url}: #{e.message}"
    nil
  end

  private

  def follow(url, remaining)
    raise UnsafeUrl, url unless @url_safety.safe?(url)

    URI.open(url, **open_options) { |io| io.read(@max_bytes) }
  rescue OpenURI::HTTPRedirect => e
    raise if remaining <= 0

    follow(e.uri.to_s, remaining - 1)
  end

  def open_options
    {
      open_timeout: @open_timeout,
      read_timeout: @read_timeout,
      redirect: false,
      content_length_proc: method(:guard_size)
    }
  end

  def guard_size(size)
    raise ResponseTooLarge, size.to_s if size && size > @max_bytes
  end
end
