require 'rails_helper'
require 'active_interaction'

RSpec.describe TriggerDownloadAndStoreVideoFromYoutube do
  subject do
    TriggerDownloadAndStoreVideoFromYoutube.run!(youtube_url:)
  end

  let(:youtube_url) { 'https://www.youtube.com/watch?v=ZnjJpa1LBOY' }
  let(:key) { SecureRandom.hex(16) }

  before do
    allow(SecureRandom).to receive(:hex).with(16).and_return(key)
  end

  describe 'validation' do
    context 'when youtube_url does not match regex' do
      let(:youtube_url) { 'https://www.google.com/watch?v=ZnjJpa1LBOY' }

      it 'raise error' do
        assert_raises(ActiveInteraction::InvalidInteractionError) { subject }
      end
    end

    context 'when youtube_url is not string' do
      let(:youtube_url) { 123 }

      it 'raise error' do
        assert_raises(ActiveInteraction::InvalidInteractionError) { subject }
      end
    end

    context 'when youtube_url is not present' do
      let(:youtube_url) { nil }

      it 'raise error' do
        assert_raises(ActiveInteraction::InvalidInteractionError) { subject }
      end
    end
  end

  it 'download youtube video by calling DownloadAndStoreVideoFromYoutube job' do
    expect(DownloadAndStoreVideoFromYoutube).to receive(:perform_async)

    subject

    expect(Cache.get("youtube_video_download:#{key}:status")).to eq 'pending'
  end
end
