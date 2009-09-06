require 'rake/tasklib'

class SystemBuilder::Task < Rake::TaskLib

  attr_reader :name

  def initialize(name, &block)
    @name = name

    @image =
      if block_given?
        block.call
      else
        SystemBuilder.config(name)
      end

    define
  end

  def define
    namespace name do
      desc "Create image #{name} in #{@image.file}"
      task :dist do
        @image.create
      end
      namespace :dist do
        desc "Create vmwaire image in #{@image.file}.vdmk"
        task :vmware do
          @image.convert "#{@image.file}.vmdk", :format => "vmdk"
        end
      end
      task "dist:vmware" => "dist"
    end
  end

end
