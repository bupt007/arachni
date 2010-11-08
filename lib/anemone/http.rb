=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'net/https'
require Arachni::Options.instance.dir['lib'] + 'anemone/page'
require Arachni::Options.instance.dir['lib'] + 'anemone/cookie_store'


#
# Overides Anemone's HTTP class methods:
#  o refresh_connection( ): added proxy support
#  o get_response( ): upped the retry counter to 7 and generalized exception handling
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Anemone

class HTTP

    include Arachni::UI::Output

    # Maximum number of redirects to follow on each get_response
    REDIRECT_LIMIT = 5

    # CookieStore for this HTTP client
    attr_reader :cookie_store

    def initialize(opts = {})
      @connections = {}
      @opts = opts
      @cookie_store = CookieStore.new(@opts[:cookies])
    end

    #
    # Fetch a single Page from the response of an HTTP request to *url*.
    # Just gets the final destination page.
    #
    def fetch_page(url, referer = nil, depth = nil)
      fetch_pages(url, referer, depth).last
    end

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_pages(url, referer = nil, depth = nil)
      begin
        url = URI(url) unless url.is_a?(URI)
        pages = []
        get(url, referer) do |response, code, location, redirect_to, response_time|
          pages << Page.new(location, :body => response.body.dup,
                                      :code => code,
                                      :headers => response.to_hash,
                                      :referer => referer,
                                      :depth => depth,
                                      :redirect_to => redirect_to,
                                      :response_time => response_time)
        end

        return pages
      rescue => e
        if verbose?
          puts e.inspect
          puts e.backtrace
        end
        return [Page.new(url, :error => e)]
      end
    end

    #
    # The maximum number of redirects to follow
    #
    def redirect_limit
      @opts[:redirect_limit] || REDIRECT_LIMIT
    end

    #
    # The user-agent string which will be sent with each request,
    # or nil if no such option is set
    #
    def user_agent
      @opts[:user_agent]
    end

    #
    # Does this HTTP client accept cookies from the server?
    #
    def accept_cookies?
      @opts[:accept_cookies]
    end

    private

    #
    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    #
    def get(url, referer = nil)
      limit = redirect_limit
      loc = url
      begin
          # if redirected to a relative url, merge it with the host of the original
          # request url
          loc = url.merge(loc) if loc.relative?

          response, response_time = get_response(loc, referer)
          code = Integer(response.code)
          redirect_to = response.is_a?(Net::HTTPRedirection) ?  URI(response['location']).normalize : nil
          yield response, code, loc, redirect_to, response_time
          limit -= 1
      end while (loc = redirect_to) && allowed?(redirect_to, url) && limit > 0
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
        full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"

        opts = {}
        opts['User-Agent'] = user_agent if user_agent
        opts['Referer'] = referer.to_s if referer
        opts['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)
        opts['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'

        retries = 0
        begin
            start = Time.now()
            response = connection(url).get(full_path, opts)
            finish = Time.now()
            response_time = ((finish - start) * 1000).round
            @cookie_store.merge!(response['Set-Cookie']) if accept_cookies?
            return response, response_time
        rescue Exception => e
            retries += 1

            print_error( e.to_s )
            print_info( ( 7 - retries ).to_s +
                ' retries remaining for url: ' + url.to_s )

            print_debug_backtrace( e )
            refresh_connection(url)
            retry unless retries > 7
        end
    end

    def connection(url)
      @connections[url.host] ||= {}

      if conn = @connections[url.host][url.port]
        return conn
      end

      refresh_connection url
    end

    def refresh_connection( url )

        http = Net::HTTP.new( url.host, url.port,
        @opts['proxy_addr'], @opts['proxy_port'],
        @opts['proxy_user'], @opts['proxy_pass'] )

        if url.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @connections[url.host][url.port] = http.start
    end

    def verbose?
      @opts[:verbose]
    end

    #
    # Allowed to connect to the requested url?
    #
    def allowed?(to_url, from_url)
      to_url.host.nil? || (to_url.host == from_url.host)
    end


end
end
