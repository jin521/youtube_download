class TriggerDownloadAndStoreVideoFromYoutube < ActiveInteraction::Base
  string :youtube_url

  REGEXP_YOUTUBE_URL = %r{
    \A(?:https?://)?
    (?:www\.)?
    (?:youtu\.be/|youtube\.com/(?:embed/|v/|watch\?v=|watch\?.+&v=))
    ((\w|-){11})(?:\S+)?\z
    }x

  validates :youtube_url,
            presence: true,
            format: {
              with: REGEXP_YOUTUBE_URL
            }

  def execute
    status_key = "youtube_video_download:#{SecureRandom.hex(16)}"

    Cache.set("#{status_key}:status", 'pending')

    bucket_name = Settings.google_cloud.storage_buckets.transcript_requests

    DownloadAndStoreVideoFromYoutube.perform_async(youtube_url, status_key, bucket_name)

    status_key
  end
end
