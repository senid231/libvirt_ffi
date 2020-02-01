# frozen_string_literal: true

class LogFormatter
  LOG_FORMAT = "%s, %s [%s/%s/%s] %s\n".freeze
  DEFAULT_DATETIME_FORMAT = "%F %T.%N".freeze

  attr_accessor :datetime_format

  def initialize
    @datetime_format = nil
  end

  def call(severity, time, progname, message)
    LOG_FORMAT % [
        severity[0..0],
        format_datetime(time),
        "0x#{Async::Task.current?&.object_id&.to_s(16)}",
        "0x#{Fiber.current.object_id.to_s(16)}",
        progname,
        format_message(message)
    ]
  end

  private

  def format_datetime(time)
    time.strftime(@datetime_format || DEFAULT_DATETIME_FORMAT)
  end

  def format_message(message)
    case message
    when ::String
      message
    when ::Exception
      "<#{message.class}>:#{message.message}\n#{(message.backtrace || []).join("\n")}"
    else
      message.inspect
    end
  end
end
