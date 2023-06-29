require 'rails_helper'

RSpec.describe DownloadAndStoreVideoFromYoutube do
  subject { job.perform(url, status_key, bucket_name) }

  let(:job) { DownloadAndStoreVideoFromYoutube.new }
  let(:url) { 'https://www.youtube.com/watch?v=ZnjJpa1LBOY' }
  let(:status_key) { 'fake_status_key' }
  let(:bucket_name) { 'streem-transcript-requests-au' }

  let(:storage_service) { double('StorageService') }

  let(:youtube_api_url) { 'https://www.youtube.com/youtubei/v1/player' }
  let(:youtube_video_url) { 'https://fake.youtube.com/video.mp4' }

  let(:google_storage_url) { 'https://storage.googleapis.com/streem-test-au/test.mp4' }
  let(:mock_upload_result) { double('Google::Storage::Response', url: google_storage_url) }

  before do
    allow(GoogleStorageService).to receive(:new).with(bucket_name).and_return storage_service
  end

  it 'uploads the file to Google Cloud Storage service' do
    stub_request(:post, youtube_api_url).to_return(
      body: {
        'streamingData' => {
          'formats' => [
            {
              'itag' => 18,
              'url' => youtube_video_url,
              'mimeType' => 'video/fake',
              'contentLength' => '12345'
            }
          ]
        }
      }.to_json
    )

    stub_request(:get, youtube_video_url).to_return(
      body: 'fake video body data',
      status: 200
    )

    expect(storage_service).to receive(:upload) do |file:, upload_path:, options:|
      expect(file).to be_a(Tempfile)
      expect(file.read).to eq('fake video body data')
      expect(upload_path).to match(/^ZnjJpa1LBOY_\w{32}\.mp4$/)
      expect(options).to eq({ content_type: 'video/fake' })
    end.and_return(mock_upload_result)

    subject

    expect(Cache.get("#{status_key}:status")).to eq 'done'
    expect(Cache.get("#{status_key}:url")).to eq google_storage_url
  end

  context 'when youtube video api request fails' do
    before do
      stub_request(:post, youtube_api_url).to_return(status: 500)
    end

    it 'raises an error' do
      expect { subject }.to raise_error 'Youtube Video Request Failed'
    end
  end

  context 'when youtube video download request fails' do
    before do
      stub_request(:post, youtube_api_url).to_return(
        body: {
          'streamingData' => {
            'formats' => [
              {
                'itag' => 18,
                'url' => youtube_video_url,
                'mimeType' => 'video/fake',
                'contentLength' => '12345'
              }
            ]
          }
        }.to_json
      )

      stub_request(:get, youtube_video_url).to_return(status: 404)
    end

    it 'raises an error' do
      expect { subject }.to raise_error 'Youtube Video Download Failed'
    end
  end
end
