require 'server'
require 'email'
require 'hip_chat'

module DockerWatcher
  class Watcher

    def initialize
      load_config
    end

    def stream!
      threads = []
      @servers.each do |server|
        threads << Thread.new(server) do |server|
          server.stream! { |event| handle(server, event) }
        end
      end
      threads.each { |t| t.join }
    end

    protected

    def handle(server, event)
      DaemonKit.logger.info(event)
      if @events.include?(event.status)
        (@emails + @hipchats).each { |e| e.send(server, event) }
      end
    end

    def load_config
      file = DaemonKit.arguments.options[:config_file]

      raise "Must specify configuration file with -f" unless !!file
      raise "No such config file '#{file}'" unless File.exists?(file)

      content = YAML.load( File.read(file) )

      @servers = []
      content['servers'].each do |s|
        begin
          s = DockerWatcher::Server.new(s)
          @servers << s
        rescue
          DaemonKit.logger.error("Could not connect to server '#{s}'\n" + $!.message) 
        end
      end

      @emails = if !!content['emails']
        content['emails'].map { |e| DockerWatcher::Email.new(e, content['smtp']) }
      else
        []
      end

      @hipchats = if !!content['hipchats']
        content['hipchats'].map { |h| DockerWatcher::HipChat.new(h) }
      else
        []
      end

      @events = content['events'] || %w(start stop die)

      raise "No servers specified in config" unless !!@servers
    end

  end
end
