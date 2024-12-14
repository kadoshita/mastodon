# frozen_string_literal: true

class Mastodon::RackMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # ref: https://tech.unifa-e.com/entry/2017/01/31/192820
    OpenTelemetry::Trace.current_span.add_attributes({
      'http.request_id' => env['action_dispatch.request_id'],
    })

    @app.call(env)
  ensure
    clean_up_sockets!
  end

  private

  def clean_up_sockets!
    clean_up_redis_socket!
    clean_up_statsd_socket!
  end

  def clean_up_redis_socket!
    RedisConnection.pool.checkin if Thread.current[:redis]
    Thread.current[:redis] = nil
  end

  def clean_up_statsd_socket!
    Thread.current[:statsd_socket]&.close
    Thread.current[:statsd_socket] = nil
  end
end
