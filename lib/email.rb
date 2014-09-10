module DockerWatcher
  class Email

    def initialize(address, via_options = nil)
      @address = address 
      @via_options = via_options
    end

    def send(server, event)
      DaemonKit.logger.debug("Sending event to #{@address}")

      subject = "#{event.from} #{event.status}"

      body = <<END
#{server.inspect}
#{event}
END

      opts = {
        to: @address,
        subject: subject,
        body: body
      }

      opts.merge!(via_options: @via_options) if !!@via_options

      DaemonKit.logger.debug(opts)
      Pony.mail(opts)
    end

  end
end
