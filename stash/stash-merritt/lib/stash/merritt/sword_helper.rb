require 'stash/sword'
require 'stash/merritt_deposit'

module Stash
  module Merritt
    class SwordHelper

      class GoneAsynchronous < StandardError; end

      attr_reader :logger, :package

      def initialize(package:, logger: nil)
        @logger = logger
        @package = package
      end

      def submit!
        if (update_uri = resource.update_uri)
          do_update(update_uri)
        else
          do_create
        end

        # everything is now asynchronous.  Can move to new class since it's not sword in the future
        raise GoneAsynchronous

      ensure
        resource.version_zipfile = File.basename(package.payload)
        resource.save!
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
        @merritt_client ||= Stash::MerrittDeposit::Client.new(logger: logger, **tenant.sword_params)
      end

      def do_create
        merritt_client.create(doi: identifier_str, payload: package.payload)
        # resource.download_uri = receipt.em_iri
        # resource.update_uri = receipt.edit_iri
      end

      def do_update(update_uri)
        merritt_client.update(doi: identifier_str, payload: package.payload)
      end

    end
  end
end
