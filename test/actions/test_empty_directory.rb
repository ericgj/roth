require_relative '../test_helper'
require_relative '../../lib/roth/file_actions'

describe Actions::EmptyDirectory do
  include TestHelpers
  
  def reset
    ::FileUtils.rm_rf(destination_root)
  end

  def empty_directory(destination, options={})
    @action = Actions::EmptyDirectory.new(base, destination)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def base
    @base ||= FileActions.new(destination_root, [], :shell => Shell::Basic.new)
  end


  describe "#destination" do
    before { reset }
    it "returns the full destination with the destination_root" do
      assert_equal File.join(destination_root, 'doc'), 
                   empty_directory('doc').destination
    end

    it "takes relative root into account" do
      base.inside('doc') do
        assert_equal File.join(destination_root, 'doc', 'contents'), 
                     empty_directory('contents').destination
      end
    end
  end  
  
  describe "#relative_destination" do
    before { reset }
    it "returns the relative destination to the original destination root" do
      base.inside('doc') do
        assert_equal 'doc/contents', empty_directory('contents').relative_destination
      end
    end
  end
  
  describe "#given_destination" do
    before { reset }
    it "returns the destination supplied by the user" do
      base.inside('doc') do
        assert_equal 'contents', empty_directory('contents').given_destination
      end
    end
  end

  describe "#invoke!" do
    before { reset }
    it "copies the file to the specified destination" do
      empty_directory("doc")
      invoke!
      assert File.exists?(File.join(destination_root, "doc"))
    end

    it "shows created status to the user" do
      empty_directory("doc")
      assert_equal "      create  doc\n", invoke!
    end

    it "does not create a directory if pretending" do
      base.inside("foo", :pretend => true) do
        empty_directory("ghost")
      end
      refute File.exists?(File.join(base.root_destination, "ghost"))
    end

    describe "when directory exists" do     
      it "shows exist status" do
        empty_directory("doc")
        invoke!
        assert_equal "       exist  doc\n", invoke!
      end
      
    end
  end
  
  describe "#revoke!" do
    before { reset }
    it "removes the destination file" do
      empty_directory("doc")
      invoke!
      revoke!
      refute File.exists?(@action.destination)
    end
  end

  describe "#exists?" do
    before { reset }
    it "returns true if the destination file exists" do
      empty_directory("doc")
      refute @action.exists?
      invoke!
      assert @action.exists?
    end
  end
  
end

