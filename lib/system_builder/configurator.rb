module SystemBuilder

  class ProcConfigurator

    def initialize(proc = nil, &block)
      @proc = (proc or block)
    end

    def configure(chroot)
      @proc.call chroot
    end

  end

  class PuppetConfigurator

    attr_reader :manifest

    def initialize(manifest = ".")
      @manifest = manifest
    end

    def configure(chroot)
      chroot.apt_install :puppet

      unless File.directory?(manifest)
        chroot.image.install "/tmp/puppet.pp", manifest
        chroot.sudo "puppet tmp/puppet.pp"
      else
        chroot.image.mkdir "/tmp/puppet"
        chroot.image.rsync "/tmp/puppet", "#{manifest}/manifests"
        chroot.sudo "puppet tmp/puppet/manifests/site.pp"
      end
    end

  end

end