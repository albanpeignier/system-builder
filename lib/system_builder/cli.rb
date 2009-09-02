require 'optparse'

module SystemBuilder
  class CLI
    def self.execute(stdout, arguments=[])
      options = {}
      mandatory_options = %w(config)

      OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Create and configure bootable systems

          Usage: #{File.basename($0)} [options] image command

          Options are:
        BANNER
        opts.separator ""
        opts.on("-c", "--config=FILE", String,
                "The file containing image and boot definitions") { |arg| options[:config] = arg }
        opts.on("-h", "--help", "Show this help message.") { stdout.puts opts; exit }

        opts.parse!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      load options[:config]

      image = SystemBuilder.configuration(arguments.unshift)
      image.create
    end
  end
end
