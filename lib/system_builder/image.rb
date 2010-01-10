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

    install_extlinux_files

    sync_root_fs
    install_extlinux

    self
  end

  def create_file
    FileUtils::sh "dd if=/dev/zero of=#{file} count=#{size.in_megabytes.to_i} bs=1M"
  end

  def create_partition_table
    # Partition must be bootable for syslinux
    FileUtils::sh "echo '63,,L,*' | /sbin/sfdisk --no-reread -uS -H16 -S63 #{file}"
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

  def mount_root_fs(&block)
    # TODO use a smarter mount_dir
    mount_dir = "/tmp/mount_root_fs"
    FileUtils::mkdir_p mount_dir

    begin
      FileUtils::sudo "mount -o loop,offset=#{fs_offset} #{file} #{mount_dir}"
      yield mount_dir
    ensure
      FileUtils::sudo "umount #{mount_dir}"
    end
  end

  def sync_root_fs
    mount_root_fs do |mount_dir|
      FileUtils::sudo "rsync -a --delete #{boot.root}/ #{mount_dir}"
    end
    FileUtils.touch file
  end

  def install_extlinux_files(options = {})
    root = (options[:root] or "LABEL=#{fs_label}")
    version = (options[:version] or Time.now.strftime("%Y%m%d%H%M"))

    boot.image do |image|
      image.mkdir "/boot/extlinux"

      boot.image.open("/boot/extlinux/extlinux.conf") do |f|
        f.puts "DEFAULT linux"
        f.puts "LABEL linux"
        f.puts "SAY Now booting #{version} from syslinux ..."
        f.puts "KERNEL /vmlinuz"
        f.puts "APPEND ro root=#{root} initrd=/initrd.img"
      end
    end
  end

  def install_grub_files(options = {})
    stage_files = Array(options[:stage_files]).flatten

    boot.image do |image|
      image.mkdir "/boot/grub"

      install_grub_menu options
      image.install "boot/grub", stage_files.collect { |f| '/usr/lib/grub/**/' + f }
    end
  end

  def install_extlinux
    # TODO install extlinux.sys only when needed
    mount_root_fs do |mount_dir|
      FileUtils::sudo "extlinux --install -H16 -S63 #{mount_dir}/boot/extlinux"
    end
    # TODO install mbr only when needed
    # install MBR
    FileUtils::sh "dd if=/usr/lib/syslinux/mbr.bin of=#{file} conv=notrunc"
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
    linux_partition_info.split[5].to_i
  end

  def fs_offset
    32256
  end

  def fs_label
    "root"
  end

end
