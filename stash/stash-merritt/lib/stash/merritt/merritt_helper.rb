require 'stash/deposit'
require 'stash/deposit/client'

module Stash
  module Merritt
    class MerrittHelper

      attr_reader :logger, :package

      def initialize(package:, logger: nil)
        @logger = logger
        @package = package
      end

      def submit!
        if resource.update_uri
          do_update
        else
          do_create
        end
      ensure
        resource.version_zipfile = File.basename(package.payload)
        resource.save!
      end

      # class method
      def self.sword_params
        {
          collection_uri: APP_CONFIG[:repository][:endpoint],
          username: APP_CONFIG[:repository][:username],
          password: APP_CONFIG[:repository][:password]
        }
      end

      # instance method
      def sword_params
        self.class.sword_params
      end

      private

      def resource
        package.resource
      end

      def tenant
        resource.tenant
      end

      def identifier_str
        resource.identifier_str
      end

      def merritt_client
        @merritt_client ||= Stash::Deposit::Client.new(logger: logger, **sword_params)
      end

      def do_create
        merritt_client.create(doi: identifier_str, payload: package.payload)
        # resource.download_uri = receipt.em_iri
        # resource.update_uri = receipt.edit_iri
      end

      def do_update
        merritt_client.update(doi: identifier_str, payload: package.payload, download_uri: resource.download_uri)
      end

    end
  end
end
