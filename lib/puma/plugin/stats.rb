# frozen_string_literal: true

require 'puma/stats/dsl'

Puma::Plugin.create do
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def start(launcher)
    str = launcher.options[:stats_url] || 'tcp://0.0.0.0:51209'

    require 'puma/stats/app'

    app = Puma::Stats::App.new launcher
    uri = URI.parse str

    stats = Puma::Server.new app, launcher.events
    stats.min_threads = 0
    stats.max_threads = 1

    case uri.scheme
    when 'tcp'
      optional_token = launcher.options[:stats_token] ? "with auth token: #{launcher.options[:stats_token]}" : '' 
      launcher.events.log "* Starting stats server on URI: #{str} #{optional_token}"
      stats.add_tcp_listener uri.host, uri.port
    else
      launcher.events.error "Invalid stats server URI: #{str}"
    end

    launcher.events.register(:state) do |state|
      if %i[halt restart stop].include?(state)
        stats.stop(true) unless stats.shutting_down?
      end
    end

    stats.run
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
