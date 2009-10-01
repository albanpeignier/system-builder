class SystemBuilder::DebianBoot
  
  attr_accessor :version, :mirror, :architecture
  attr_accessor :exclude, :include

  attr_reader :root
  attr_reader :configurators

  @@default_mirror = 'http://ftp.debian.org/debian'
  def self.default_mirror=(mirror)
    @@default_mirror = mirror    
  end

  def initialize(root)
    @root = root

    @version = :lenny
    @mirror = @@default_mirror
    @architecture = :i386
    @exclude = []
    @include = []

    # kernel can't be installed by debootstrap
    @configurators = 
      [ localhost_configurator, 
        apt_configurator, 
        kernel_configurator, 
        fstab_configurator, 
        timezone_configurator ]
    @cleaners = [ apt_cleaner ]
  end

  def create
    bootstrap
    configure
    clean
  end

  def bootstrap
    unless File.exists?(root)
      FileUtils::mkdir_p root
      FileUtils::sudo "debootstrap", debbootstrap_options, version, root, mirror
    end
  end

  def configure
    unless @configurators.empty?
      chroot do |chroot|
        @configurators.each do |configurator|
          configurator.configure(chroot)
        end
      end
    end
  end

  def clean
    unless @cleaners.empty?
      chroot do |chroot|
        @cleaners.each do |cleaner|
          cleaner.call(chroot)
        end
      end
    end
  end

  def kernel_configurator
    SystemBuilder::ProcConfigurator.new do |chroot|
      chroot.image.open("/etc/kernel-img.conf") do |f|
        f.puts "do_initrd = yes"
      end
      chroot.apt_install %w{linux-image-2.6-686 grub}
    end
  end

  def fstab_configurator
    SystemBuilder::ProcConfigurator.new do |chroot|
      chroot.image.open("/etc/fstab") do |f|
        %w{/tmp /var/run /var/log /var/lock /var/tmp}.each do |directory|
          f.puts "tmpfs #{directory} tmpfs defaults,noatime 0 0"
        end
      end
    end
  end

  def timezone_configurator
    SystemBuilder::ProcConfigurator.new do |chroot|
      # Use same timezone than build machine
      chroot.image.install "/etc/", "/etc/timezone", "/etc/localtime"
    end
  end

  def apt_configurator
    # TODO see if this step is really needed
    SystemBuilder::ProcConfigurator.new do |chroot|    
      chroot.image.install "/etc/apt", "/etc/apt/trusted.gpg"
      chroot.sudo "apt-get update"
    end
  end

  def apt_cleaner
    Proc.new do |chroot|
      chroot.sudo "apt-get clean"      
    end
  end

  def localhost_configurator
    SystemBuilder::ProcConfigurator.new do |chroot|
      chroot.image.open("/etc/hosts") do |f|
        f.puts "127.0.0.1	localhost"
        f.puts "::1     localhost ip6-localhost ip6-loopback"
      end
    end
  end

  def configure(&block)
    @configurators << SystemBuilder::ProcConfigurator.new(block)
  end

  def debbootstrap_options
    {
      :arch => architecture,  
      :exclude => exclude.join(','),
      :include => include.join(','),
      :variant => :minbase
    }.collect do |k,v| 
      ["--#{k}", Array(v).join(',')] unless v.blank?
    end.compact
  end

  def image(&block)
    @image ||= Image.new(root)

    if block_given?    
      yield @image
    else
      @image
    end
  end

  def chroot(&block)
    @chroot ||= Chroot.new(image)
    @chroot.execute &block
  end

  class Image
    
    def initialize(root)
      @root = root
    end

    def mkdir(directory)
      FileUtils::sudo "mkdir -p #{expand_path(directory)}"
    end

    def install(target, *sources)
      FileUtils::sudo "cp --preserve=mode,timestamps #{sources.join(' ')} #{expand_path(target)}"
    end

    def rsync(target, *sources)
      options = (Hash === sources.last ? sources.pop : {})
      rsync_options = options.collect { |k,v| "--#{k}=#{v}" }
      FileUtils::sudo "rsync -av #{rsync_options.join(' ')} #{sources.join(' ')} #{expand_path(target)}"
    end

    def open(filename, &block) 
      Tempfile.open(File.basename(filename)) do |f|
        yield f
        f.close
        
        File.chmod 0644, f.path
        install filename, f.path
      end
    end

    def expand_path(path)
      File.join(@root,path)
    end

  end

  class Chroot

    attr_reader :image

    def initialize(image)
      @image = image
    end

    def apt_install(*packages)
      sudo "apt-get install --yes --force-yes #{packages.join(' ')}"
    end

    def cp(*arguments)
      sudo "cp #{arguments.join(' ')}"
    end

    def sh(*arguments)
      FileUtils::sudo "chroot #{image.expand_path('/')} sh -c \"LC_ALL=C #{arguments.join(' ')}\""
    end
    alias_method :sudo, :sh

    def execute(&block)
      begin
        prepare_run
        yield self
      ensure
        unprepare_run
      end
    end

    def prepare_run
      FileUtils::sudo "mount proc #{image.expand_path('/proc')} -t proc"
    end

    def unprepare_run
      FileUtils::sudo "umount #{image.expand_path('/proc')}"
    end

  end
  
end
