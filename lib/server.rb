require 'socket'

module DockerWatcher
  class Server
    attr_reader :name, :docker

    def initialize(conn_string)
      @docker = Docker::Connection.new(conn_string, {read_timeout: 3600 * 24 * 365})
      Docker.version(@docker) # force the lazy connection to connect

      @name = if !!conn_string.index('unix')
        Socket.gethostname
      else
        conn_string.split('/')[2].split(':').first
      end
    end

    def stream!
      retries = 0
      begin
        DaemonKit.logger.info("Connecting to #{name} for events")
        Docker::Event.stream({}, @docker) do |event|
          retries = 0
          yield event
        end
      rescue Docker::Error::TimeoutError
        DaemonKit.logger.error($!.message + "\n" + $!.backtrace.join("\n"))
        DaemonKit.logger.debug("Docker #{name} stream timed out, reconnecting")
        retry
      rescue Excon::Errors::SocketError
        DaemonKit.logger.error($!.message + "\n" + $!.backtrace.join("\n"))
        DaemonKit.logger.error("Docker #{name} stream closed, will attempt to reconnect in 5 seconds")
        sleep 5 if retries >= 3
        retries += 1
        retry
      end
    end

  end
end
