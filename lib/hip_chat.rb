module DockerWatcher
  class HipChat

    def initialize(config)
      # TODO parse config
    end

    def send(event)
      DaemonKit.logger.debug("Sending event to #{@config}")
    end

  end
end
