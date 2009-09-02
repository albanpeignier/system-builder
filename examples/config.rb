def working_dir(name, type)
  "/var/tmp/system-builder/#{name}/#{type}"
end

SystemBuilder.config(:simple_test) do
  SystemBuilder::DiskImage.new(working_dir("simple_test", :disk)).tap do |image|
    image.boot = SystemBuilder::DebianBoot.new(working_dir("simple_test", :boot)).tap do |boot|
      boot.mirror = "http://127.0.0.1:9999/debian"
    end
    
    image.boot.configure do |chroot|
      chroot.apt_install :sudo
    end
  end
end

SystemBuilder.config(:puppet_test) do
  SystemBuilder::DiskImage.new(working_dir("puppet_test", :disk)).tap do |image|
    image.boot = SystemBuilder::DebianBoot.new(working_dir("puppet_test", :boot)).tap do |boot|
      boot.mirror = "http://127.0.0.1:9999/debian"
    end

    # use manifests/site.pp in this directory
    image.boot.configurators << SystemBuilder::PuppetConfigurator.new(File.dirname(__FILE__))
  end
end
