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

      task :setup do
        required_packages = []
        required_packages << "qemu" # to convert image files
        required_packages << "util-linux" # provides sfdisk
        required_packages << "sudo"
        required_packages << "debootstrap"
        required_packages << "rsync"
        required_packages << "extlinux"
        required_packages << "syslinux-common"
        
        FileUtils.sudo "apt-get install #{required_packages.join(' ')}"
      end
    end
  end

end
