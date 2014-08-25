=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::OptionGroups

# Holds paths to the directories of various system components.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Paths < Arachni::OptionGroup

    attr_accessor :root
    attr_accessor :arachni
    attr_accessor :gfx
    attr_accessor :components
    attr_accessor :logs
    attr_accessor :executables
    attr_accessor :checks
    attr_accessor :reporters
    attr_accessor :plugins
    attr_accessor :services
    attr_accessor :path_extractors
    attr_accessor :fingerprinters
    attr_accessor :lib
    attr_accessor :support
    attr_accessor :mixins
    attr_accessor :snapshots

    def initialize
        @root       = root_path
        @gfx        = @root + 'gfx/'
        @components = @root + 'components/'
        @snapshots  = @root + 'snapshots/'

        @logs = ENV['ARACHNI_FRAMEWORK_LOGDIR'] ?
            "#{ENV['ARACHNI_FRAMEWORK_LOGDIR']}/" : @root + 'logs/'

        @checks          = @components + 'checks/'
        @reporters       = @components + 'reporters/'
        @plugins         = @components + 'plugins/'
        @services   = @components + 'services/'
        @path_extractors = @components + 'path_extractors/'
        @fingerprinters  = @components + 'fingerprinters/'

        @lib     = @root + 'lib/arachni/'

        @executables = @lib + 'processes/executables/'
        @support     = @lib + 'support/'
        @mixins      = @support + 'mixins/'
        @arachni     = @lib[0...-1]
    end

    # @return   [String]    Root path of the framework.
    def root_path
        File.expand_path( File.dirname( __FILE__ ) + '/../../..' ) + '/'
    end

end
end