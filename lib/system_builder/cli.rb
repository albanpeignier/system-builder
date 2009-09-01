require 'optparse'

module SystemBuilder
  class CLI
    def self.execute(stdout, arguments=[])
      image = DiskImage.new("/var/tmp/system-builder/disk").tap do |image|
        image.boot = DebianBoot.new('/var/tmp/system-builder/boot').tap do |boot|
          boot.mirror = "http://127.0.0.1:9999/debian"
        end

        image.boot.configure do |chroot|
          chroot.apt_install :puppet
        end
      end.create

      image.convert "/var/tmp/system-builder/disk.vmdk", :format => "vmdk"

      # NOTE: the option -p/--path= is given as an example, and should be replaced in your application.

      # options = {
      #   :path     => '~'
      # }
      # mandatory_options = %w(  )

      # parser = OptionParser.new do |opts|
      #   opts.banner = <<-BANNER.gsub(/^          /,'')
      #     This application is wonderful because...

      #     Usage: #{File.basename($0)} [options]

      #     Options are:
      #   BANNER
      #   opts.separator ""
      #   opts.on("-p", "--path=PATH", String,
      #           "This is a sample message.",
      #           "For multiple lines, add more strings.",
      #           "Default: ~") { |arg| options[:path] = arg }
      #   opts.on("-h", "--help",
      #           "Show this help message.") { stdout.puts opts; exit }
      #   opts.parse!(arguments)

      #   if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
      #     stdout.puts opts; exit
      #   end
      # end

      # path = options[:path]

      # # do stuff
      # stdout.puts "To update this executable, look in lib/system-builder/cli.rb"
    end
  end
end
