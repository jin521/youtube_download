require 'rails_helper'

RSpec.describe TranscriptsController do
  let(:account_manager) { create(:user) }
  let(:organisation) { create(:organisation, account_manager:) }
  let(:user) { create(:user, organisation:) }
  let(:transcript) do
    create(
      :transcript,
      user:,
      source_name: 'SourceName',
      template_id: 1,
      account_manager: user,
      secondary_account_manager: user,
      file_url: ['http://url.to/file.aac']
    )
  end

  let(:admin) { create(:admin) }
  let(:auth_token) { generate_admin_auth_token(admin) }
  let(:current_time) { Time.current }

  describe 'POST download_youtube_video' do
    let(:outcome) { Struct.new(:result).new('status_key') }

    it 'download youtube video by calling TriggerDownloadAndStoreVideoFromYoutube action' do
      expect(TriggerDownloadAndStoreVideoFromYoutube).to receive(:run).and_return(outcome)

      post '/admin/transcripts/download_youtube_video', params: {
        auth_token:
      }

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq({ 'status_key' => 'status_key' })
    end
  end

  describe 'GET youtube_video_download_status' do
    let(:status_key) { "youtube_video_download:#{SecureRandom.hex(16)}" }

    before do
      Cache.setex("#{status_key}:status", 5.minutes, 'started')
      Cache.setex("#{status_key}:url", 5.minutes, 'test_url')
    end

    after do
      Cache.del("#{status_key}:status")
      Cache.del("#{status_key}:url")
    end

    it 'returns status, progress and url ' do
      get '/admin/transcripts/youtube_video_download_status', params: {
        auth_token:,
        status_key:
      }

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq(
        {
          'status' => 'started',
          'url' => 'test_url'
        }
      )
    end
  end
end
