require 'stash/download/version_presigned'
require 'byebug'
require 'securerandom'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Download
    RSpec.describe VersionPresigned do
      before(:each) do
        @resource = create(:resource)
        create(:download_token, resource_id: @resource.id)
        _ignored, @local_id = @resource.merritt_protodomain_and_local_id
        @vp = VersionPresigned.new(resource: @resource)
      end


      describe "urls for Merritt service" do
        it 'creates correct assemble_version_url' do
          u = @vp.assemble_version_url
          expect(u).to eq("https://localhost/api/assemble-version/#{ERB::Util.url_encode(@local_id)}/1?content=producer&format=zip")
        end

        it 'creates correct status_url' do
          u = @vp.status_url
          expect(u).to eq("https://localhost/api/presign-obj-by-token/#{@resource.download_token.token}" \
            "?filename=#{@vp.filename}&no_redirect=true")
        end
      end

      describe '#valid_resource?' do
        !(@resource.blank? || @tenant.blank? || @version.blank? || @domain.blank? || @local_id.blank?)
        it 'is false if resource is blank' do
          @resource = nil
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp.valid_resource?).to be_falsey
        end

        it 'is false if tenant is blank' do
          @resource.tenant_id = 'grobber'
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp.valid_resource?).to be_falsey
        end

        it 'is false if version is blank' do
          @resource.stash_version.destroy!
          @resource.reload
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp.valid_resource?).to be_falsey
        end

        it 'is false if domain is blank' do
          allow(@resource).to receive(:tenant).
              and_return({ repository: { domain: nil}.to_ostruct}.to_ostruct)
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp.valid_resource?).to be_falsey
        end

        it 'is false if local_id is blank' do
          allow(@resource).to receive(:merritt_protodomain_and_local_id).and_return(['', nil])
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp.valid_resource?).to be_falsey
        end
      end

      describe '#assemble' do
        it 'returns non-success status in hash for items not in the 200 http status range' do
          stub_request(:get, %r{/api/assemble-version/.+/1\?content=producer&format=zip}).
              to_return(status: 500, body: "Internal server error", headers: {})

          expect(@vp.assemble).to eq({ status: 500 })
        end

        it 'saves token and predicted availability time to database on good response' do
          token = SecureRandom.uuid
          stub_request(:get, %r{/api/assemble-version/.+/1\?content=producer&format=zip}).
              to_return(status: 200, body:
                  { status: 200, token: token,
                    'anticipated-availability-time': (Time.new + 30).to_s
                  }.to_json,
                headers: { 'Content-Type' => 'application/json' })
          outhash = @vp.assemble
          expect(outhash[:status]).to eq(200)
          expect(outhash[:token]).to eq(token)

          dt = @resource.download_token
          expect(dt.token).to eq(token)
          expect(dt.available).to be_within(10.seconds).of(Time.new + 30)
        end
      end

      describe '#status' do
        it 'parses and returns json status' do
          # do assembly first so we have status to check
          token = SecureRandom.uuid
          stub_request(:get, %r{/api/assemble-version/.+/1\?content=producer&format=zip}).
              to_return(status: 200, body:
                  { status: 200, token: token,
                    'anticipated-availability-time': (Time.new + 30).to_s
                  }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

          stub_request(:get, %r{/api/presign-obj-by-token/#{token}.+}).
              to_return(status: 202, body:
                  {  status: 202,
                     token: token,
                     "cloud-content-byte": 4393274895,
                     message: 'Object is not ready' }.to_json,
                headers: { 'Content-Type' => 'application/json' })
          @vp.assemble

          s = @vp.status
          expect(s[:status]).to eq(202)
          expect(s[:token]).to eq(token)
          expect(s[:message]).to eq('Object is not ready')
        end
      end

      describe '#download' do
        it 'just returns the status if it has an unexpired token that works for (ie 200 code)' do
          expect(@vp).to receive(:status).and_return({ status: 200 })
          expect(@vp.download).to eq({ status: 200 })
        end

        it 'just returns the status if token has a pending (202) status and a long waiting time' do
          @resource.download_token.update(available: Time.new + 6.minutes.to_i)
          @resource.reload
          @vp = VersionPresigned.new(resource: @resource)
          expect(@vp).to receive(:status).and_return({ status: 202 })
          expect(@vp.download).to eq({ status: 202 })
        end

        it 'calls poll_and_download for things ready very soon to try to avoid extra popup' do
          @resource.download_token.update(available: Time.new + 15.seconds.to_i)
          @resource.reload
          @vp = VersionPresigned.new(resource: @resource)
          allow(@vp).to receive(:status).and_return({ status: 202 })
          expect(@vp).to receive(:poll_and_download).and_return({ status: 200})
          resp = @vp.download
          expect(resp[:status]).to eq(200)
        end

        it 're-assembles object and resends status if something is expired or not found (404 or 410)' do
          @resource.download_token.update(available: Time.new + 6.minutes.to_i)
          @resource.reload
          @vp = VersionPresigned.new(resource: @resource)
          allow(@vp).to receive(:status).and_return({ status: 410}, {status: 200} )
          expect(@vp).to receive(:assemble)
          resp = @vp.download
          expect(resp[:status]).to eq(200)
        end
      end

      describe '#poll_and_download' do
        it 'only polls up to :tries: times' do
          allow(@vp).to receive(:status).and_return({ status: 202}, {status: 202 }, {status: 200 })
          output = @vp.poll_and_download(delay: 0.01, tries: 2)
          expect(output[:status]).to eq(202) # should be second value in allow, not third
        end

        it 'exits early on geting a 200 status' do
          expect(@vp).to receive(:status).and_return({status: 200 })
          output = @vp.poll_and_download(delay: 0.01, tries: 2)
          expect(output[:status]).to eq(200) # should be second value in allow, not third
        end
      end
    end
  end
end
