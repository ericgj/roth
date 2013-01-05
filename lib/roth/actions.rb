
class FileActions

  attr_accessor :shell
  
  def initialize(dest=nil, sources=[], options={})
  end

  def empty_directory(path, options={})
    instance = EmptyDirectory.new(self, path, options)
    with_conflict_resolution(instance) do
      action instance
    end
  end
  
  def action(a)
    if revoke? 
      a.before_revoke
      a.revoke! unless pretend?
      a.after_revoke
    else
      a.before_invoke
      a.invoke! unless pretend?
      a.after_invoke
    end
  end
  
  def with_conflict_resolution(a)
    cancel = false
    if a.conflict? 
      a.before_conflict
      a.handle_conflict cancel
      a.after_conflict cancel
    end
    yield unless cancel
  end
    
    
end
