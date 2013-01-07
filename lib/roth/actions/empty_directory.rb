module Actions
  class EmptyDirectory < Action

    attr_accessor :base, :config, :dir

    def initialize(base, dir, config={})
      @base, @config = base, {:verbose => true}.merge(base.config).merge(config)
      @dir = dir
    end

    def invoke
      ::FileUtils.mkdir_p(destination)
    end

    def revoke
      ::FileUtils.rm_rf(destination) if exists?
    end

    def conflict?
      exists?
    end

    def exists?
      ::File.exists?(destination)
    end
    
    def pretend?
      base.pretend?
    end
    
    def handle_conflict
      say_status :exist, :blue
      cancel = true
    end
    
    def before_invoke
      say_status :create, :green
    end
    
    def before_revoke
      say_status :remove, :red
    end

    def relative_destination
      ::File.join(base.current_relative_destination, dir)
    end
    
    def destination
      ::File.expand_path(dir, base.current_destination)
    end
    
    # for compatibility with Thor, not really needed
    def given_destination
      dir
    end
    
    def verbose?
     !!config[:verbose]
    end

    private

    # demeter issue but does it matter enough?
    def say_status(status, color)
      base.shell.say_status(status, dir, color) if verbose?
    end

  end
end
