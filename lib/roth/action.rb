# Base class
class Action
  
  # throw this in handle_conflict if decision on what to do is needed
  # further up the call stack
  ConflictError = Class.new(StandardError)
  
  def invoke!
    with_conflict_resolution do
      before_invoke
      invoke unless pretend?
      after_invoke
    end
  end
  
  def revoke!
    before_revoke
    revoke unless pretend?
    after_revoke
  end
  
  def with_conflict_resolution
    cancel = false
    if conflict?
      cancel = handle_conflict
    end
    yield unless cancel 
  end
  
  # required in subclasses
  def invoke; end
  def revoke; end
  def conflict?; end
  def pretend?; end
  def handle_conflict; end
  
  # optional in subclasses
  def before_invoke; end
  def after_invoke; end
  def before_revoke; end
  def after_revoke; end
  
end