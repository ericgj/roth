module Actions
  class CreateFile < Action

    attr_accessor :base, :config, :data, :path

    def initialize(base, path, data, config={})
      @base, @config = base, {:verbose => true}.merge(base.config).merge(config)
      @path = path
      @data = data
    end
    
    def invoke
      ::FileUtils.mkdir_p(File.dirname(destination))
      ::File.open(destination, 'wb') { |f| f.write render }  
    end
    
    def revoke
      ::FileUtils.rm_rf(destination) if exists?
    end
    
    def conflict?
      exists?
    end
    
    def identical?
      exists? && File.binread(destination) == render
    end
    
    def exists?
      ::File.exists?(destination)  
    end
    
    def pretend?
      base.pretend?
    end
        
    def handle_conflict
      if identical?
        say_status :identical, :blue
        cancel = true
      else
        cancel = force_or_skip_or_prompt(force?, skip?)
      end
      return cancel
    end
    
    def before_invoke
      say_status :create, :green
    end
    
    def before_revoke
      say_status :remove, :red
    end    
    
    def destination
      ::File.expand_path(path, base.current_destination)
    end

    def relative_destination
      ::File.join(base.current_relative_destination, path)
    end

    def given_destination
      path
    end
    
    def verbose?
     !!config[:verbose]
    end

    def force?
      !!config[:force]
    end
    
    def skip?
      !!config[:skip]
    end
    
    private

    # demeter issue but does it matter enough?
    def say_status(status, color)
      base.shell.say_status(status, path, color) if verbose?
    end
    
    def render
      @render ||= if data.respond_to?(:call)
        data.call
      else
        data
      end
    end  
    
    def force_or_skip_or_prompt(force, skip)
      if force
        say_status :force, :yellow
        cancel = true
      elsif skip
        say_status :skip, :yellow
        cancel = true
      else
        say_status :conflict, :red
        cancel = force_or_skip_or_prompt(force_on_collision?, true)
      end
      return cancel
    end
    
    # demeter
    # also, not clear what #file_collision intends to return
    def force_on_collision?
      base.shell.file_collision(destination){ render }
    end
    
  end
end