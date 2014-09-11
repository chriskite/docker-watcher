require 'socket'

module DockerWatcher
  class Server
    attr_reader :name, :docker

    def initialize(conn_string)
      @docker = Docker::Connection.new(conn_string, {})
      Docker.version(@docker) # force the lazy connection to connect

      @name = if !!conn_string.index('unix')
        Socket.gethostname
      else
        conn_string.split('/')[2].split(':').first
      end
    end

    def stream!
      begin
        Docker::Event.stream({}, @docker) do |event|
          DaemonKit.logger.debug(event)
          yield event
        end
      rescue Docker::Error::TimeoutError
        DaemonKit.logger.debug("Docker #{name} stream timed out, reconnecting")
        retry
      rescue Excon::Errors::SocketError
        DaemonKit.logger.error("Docker #{name} stream closed, attempting to reconnect")
        sleep 5
        retry
      end
    end

  end
end
