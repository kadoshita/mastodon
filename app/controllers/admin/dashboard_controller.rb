# frozen_string_literal: true
require 'sidekiq/api'
require 'net/http'
require 'uri'
require 'json'
require 'date'

module Admin
  class DashboardController < BaseController
    def index
      @users_count           = User.count
      @registrations_week    = Redis.current.get("activity:accounts:local:#{current_week}") || 0
      @logins_week           = Redis.current.pfcount("activity:logins:#{current_week}")
      @interactions_week     = Redis.current.get("activity:interactions:#{current_week}") || 0
      @relay_enabled         = Relay.enabled.exists?
      @single_user_mode      = Rails.configuration.x.single_user_mode
      @registrations_enabled = Setting.registrations_mode != 'none'
      @deletions_enabled     = Setting.open_deletion
      @invites_enabled       = Setting.min_invite_role == 'user'
      @search_enabled        = Chewy.enabled?
      @version               = Mastodon::Version.to_s
      @database_version      = ActiveRecord::Base.connection.execute('SELECT VERSION()').first['version'].match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
      @redis_version         = redis_info['redis_version']
      @reports_count         = Report.unresolved.count
      @queue_backlog         = Sidekiq::Stats.new.enqueued
      @recent_users          = User.confirmed.recent.includes(:account).limit(4)
      @database_size         = ActiveRecord::Base.connection.execute('SELECT pg_database_size(current_database())').first['pg_database_size']
      @redis_size            = redis_info['used_memory']
      @minio_size            = get_minio_storage_used()
      @ldap_enabled          = ENV['LDAP_ENABLED'] == 'true'
      @cas_enabled           = ENV['CAS_ENABLED'] == 'true'
      @saml_enabled          = ENV['SAML_ENABLED'] == 'true'
      @pam_enabled           = ENV['PAM_ENABLED'] == 'true'
      @hidden_service        = ENV['ALLOW_ACCESS_TO_HIDDEN_SERVICE'] == 'true'
      @trending_hashtags     = TrendingTags.get(7)
      @profile_directory     = Setting.profile_directory
      @timeline_preview      = Setting.timeline_preview
    end

    private

    def current_week
      @current_week ||= Time.now.utc.to_date.cweek
    end

    def redis_info
      @redis_info ||= Redis.current.info
    end

    def get_minio_storage_used
      token = auth_req()
      return get_storage_info(token)
    end

    def get_x_amz_date
      return Time.now.strftime('%Y%m%dT%H%M%SZ')
    end

    def auth_req
      minio_url = ENV['S3_ENDPOINT'] + '/minio/webrpc'
      access_id = ENV['AWS_ACCESS_KEY_ID']
      access_key = ENV['AWS_SECRET_ACCESS_KEY']
      uri = URI.parse(minio_url)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request['X-Amz-Date'] = get_x_amz_date()
      request.body = JSON.dump({
        'id' => 1,
        'jsonrpc' => '2.0',
        'params' => {
          'username' => access_id,
          'password' => access_key
        },
        'method' => 'Web.Login'
      })

      req_options = {
        use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      result=JSON.parse(response.body);

      return result['result']['token']
    end

    def get_storage_info(token)
      minio_url = ENV['S3_ENDPOINT'] + '/minio/webrpc'
      uri = URI.parse(minio_url)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request['Authorization'] = 'Bearer '+token
      request['X-Amz-Date'] = get_x_amz_date()
      request.body = JSON.dump({
        'id' => 1,
        'jsonrpc' => '2.0',
        'params' => {},
        'method' => 'Web.StorageInfo'
      })

      req_options = {
        use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      result=JSON.parse(response.body);

      return result['result']['storageInfo']['Used']
    end
  end
end
