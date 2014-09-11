module DockerWatcher
  class Email

    def initialize(address, smtp_options = {})
      @address = address 
      @smtp_options = smtp_options || {}
    end

    def send(server, event)
      DaemonKit.logger.debug("Sending event to #{@address}")

      container = Docker::Container.get(event.id, {}, server.docker)

      container_name = container.info['Config']['Hostname'] || event.id

      subject = "#{server.name} #{container_name} #{event.status}'d"

      body = <<END
Server: #{servername}
Container: #{container_name}
Command: #{container['Config']['Cmd']}
Status: #{event.status}'d
Timestamp: #{Time.at(event.time)}
END

      opts = {
        to: @address,
        subject: subject,
        body: body,
        from: @smtp_options[:from]
      }

      opts.merge!(smtp_options: @smtp_options) if !!@smtp_options

      DaemonKit.logger.debug(opts)
      Pony.mail(opts)
      rescue
        DaemonKit.logger.error("Error sending email:\n" + $!.message + "\n" + $!.backtrace.join("\n"))
    end

  end
end
