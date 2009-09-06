require 'tempfile'

class SystemBuilder::DiskImage

  attr_accessor :boot, :size
  attr_reader :file

  def initialize(file)
    @file = file
    @size = 512.megabytes
  end

  def create
    boot.create
    # TODO

    file_creation = (not File.exists?(file))
    if file_creation
      create_file
      create_partition_table
      format_root_fs
    end

    install_grub_files :stage_files => %w{e2fs_stage1_5 stage?}

    sync_root_fs
    install_grub if file_creation

    self
  end

  def create_file
    FileUtils::sh "dd if=/dev/zero of=#{file} count=#{size.in_megabytes.to_i} bs=1M"
  end

  def create_partition_table
    FileUtils::sh "echo '63,' | /sbin/sfdisk --no-reread -uS -H16 -S63 #{file}"
  end

  def format_root_fs
    loop_device = "/dev/loop0"
    begin
      FileUtils::sudo "losetup -o #{fs_offset} #{loop_device} #{file}"
      FileUtils::sudo "mke2fs -L #{fs_label} -jqF #{loop_device} #{fs_block_size}"
    ensure
      FileUtils::sudo "losetup -d #{loop_device}"
    end
  end

  def sync_root_fs
    mount_dir = "/tmp/mount_root_fs"
    FileUtils::mkdir_p mount_dir
    
    begin
      FileUtils::sudo "mount -o loop,offset=#{fs_offset} #{file} #{mount_dir}"
      FileUtils::sudo "rsync -av #{boot.root}/ #{mount_dir}"
    ensure
      FileUtils::sudo "umount #{mount_dir}"
    end

    FileUtils.touch file
  end

  def install_grub_files(options = {})
    stage_files = Array(options[:stage_files]).flatten

    boot.image do |image|
      image.mkdir "/boot/grub"

      install_grub_menu options  
      image.install "boot/grub", stage_files.collect { |f| '/usr/lib/grub/**/' + f }
    end
  end

  def install_grub
    IO.popen("sudo grub --device-map=/dev/null","w") { |grub| 
      grub.puts "device (hd0) #{file}"
      grub.puts "root (hd0,0)"
      grub.puts "setup (hd0)"
      grub.puts "quit"
    }
  end

  def install_grub_menu(options = {})
    root = (options[:root] or "LABEL=#{fs_label}")
    version = (options[:version] or Time.now.strftime("%Y%m%d%H%M"))

    boot.image.open("/boot/grub/menu.lst") do |f|
      f.puts "default 0"
      f.puts "timeout 2"
      f.puts "title #{version} Debian GNU/Linux"
      f.puts "kernel /vmlinuz root=#{root} ro"
      f.puts "initrd /initrd.img"
    end
  end

  def convert(export_file, options = {})
    unless FileUtils.uptodate? export_file, file
      arguments = []
      arguments << "-O #{options[:format]}" if options[:format]
      FileUtils::sh "qemu-img convert -f raw #{file} #{arguments.join(' ')} #{export_file}"
    end
  end

  def fs_block_size
    linux_partition_info = `/sbin/sfdisk -l #{file}`.scan(%r{#{file}.*Linux}).first
    linux_partition_info.split[4].to_i
  end

  def fs_offset
    32256
  end

  def fs_label
    "root"
  end

end
