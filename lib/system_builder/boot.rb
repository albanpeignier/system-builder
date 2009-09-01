class SystemBuilder::DebianBoot
  
  attr_accessor :version, :mirror, :architecture
  attr_accessor :exclude, :include

  attr_reader :root

  def initialize(root)
    @root = root

    @version = :lenny
    @mirror = 'http://ftp.debian.org/debian'
    @architecture = :i386
    @exclude = []
    @include = []

    # kernel can't be installed by debootstrap
    @configurators = [ kernel_configurator ]
  end

  def create
    unless File.exists?(root)
      FileUtils::mkdir_p root
      FileUtils::sudo "debootstrap", debbootstrap_options, version, root, mirror
    end

    unless @configurators.empty?
      chroot do |chroot|
        @configurators.each do |configurator|
          configurator.call chroot
        end
      end
    end
  end

  def kernel_configurator
    Proc.new do |chroot|
      chroot.apt_install %w{linux-image-2.6-686 grub}
    end
  end

  def configure(&block)
    @configurators << block
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
    @chroot ||= Chroot.new(root)
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

    def expand_path(path)
      File.join(@root,path)
    end

  end

  class Chroot

    def initialize(root)
      @root = root
    end

    def apt_install(*packages)
      sudo "apt-get install --yes --force-yes #{packages.join(' ')}"
    end

    def sh(*arguments)
      FileUtils::sudo "chroot #{@root} sh -c \"LC_ALL=C #{arguments.join(' ')}\""
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
      FileUtils::sudo "mount proc #{@root}/proc -t proc"
    end

    def unprepare_run
      FileUtils::sudo "umount #{@root}/proc"
    end

  end
  
end
