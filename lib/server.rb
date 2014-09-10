module DockerWatcher
  class Server

    def initialize(conn_string)
      @docker = Docker::Connection.new(conn_string, {})
      Docker.version(@docker) # force the lazy connection to connect
    end

    def stream!
      Docker::Event.stream({}, @docker) do |event|
        DaemonKit.logger.debug(event)
        yield event
      end
    end

  end
end
