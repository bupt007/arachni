=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents a remote server, mainly by checking for and logging remote resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Server < Base
    include Capabilities::WithAuditor

    def initialize( url )
        super url: url
        @initialization_options = url
    end

    # @note Ignores custom 404 responses.
    #
    # Logs a remote file or directory if it exists.
    #
    # @param    [String]    url
    #   Resource to check.
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    # @param    [Proc]      block
    #   Called if the file exists, just before logging the issue, and is passed
    #   the HTTP response.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    #
    # @see #remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        auditor.print_status( "Checking for #{url}" ) if !silent
        remote_file_exist?( url ) do |bool, res|
            auditor.print_status( 'Analyzing response for: ' + url ) if !silent
            next if !bool

            block.call( res ) if block_given?
            auditor.log_remote_file( res )

            # If the file exists let the trainer parse it since it may contain
            # brand new data to audit.
            auditor.framework.trainer.push( res )
        end
        true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    # @note Ignores custom 404 responses.
    #
    # Checks whether or not a remote resource exists.
    #
    # @param    [String]    url
    #   Resource to check.
    # @param    [Block] block
    #   Block to be passed  `true` if the resource exists or `false` otherwise
    #   and the response for the resource check.
    def remote_file_exist?( url, &block )
        if http.needs_custom_404_check?( url )
            http.get( url, performer: self ) do |r|
                if r.code == 200
                    http.custom_404?( r ) { |bool| block.call( !bool, r ) }
                else
                    block.call( false, r )
                end
            end
        else
            http.request( url, method: :head, performer: self ) do |response|
                block.call( response.code == 200, response )
            end
        end

        nil
    end
    alias :remote_file_exists? :remote_file_exist?

    def http
        auditor.http
    end

end
end
