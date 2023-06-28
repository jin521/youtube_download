class DownloadAndStoreVideoFromYoutube

  include Sidekiq::Job

  sidekiq_options :retry => 0

  CACHE_TTL = 5.minutes

  def perform(youtube_url, status_key, bucket_name)
    @status_key = status_key
    @video_id = get_video_id_from_youtube_url(youtube_url)
    @bucket_name = bucket_name

    file = Tempfile.new
    file.binmode

    update_status("started")

    video_file_details = get_video_file_details(@video_id)

    download_video_to_file!(file, :media_url => video_file_details["url"])

    url = upload_to_storage_service(file, :mime_type => video_file_details["mimeType"])

    update_status("done")
    Cache.setex("#{@status_key}:url", CACHE_TTL, url)
  ensure
    file.close
    file.unlink
  end

  private

  def get_video_id_from_youtube_url(url)
    id = ""
    url = url.gsub(/(>|<)/i, "").split(/(vi\/|v=|\/v\/|youtu\.be\/|\/embed\/)/)
    if url[2].nil?
      id = url
    else
      id = url[2].split(/[^0-9a-z_\-]/i)
      id = id[0]
    end
    id
  end

  def get_video_file_details(video_id)
    payload = {
      :context => {
        :client => {
          # As discovered by https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube.py#L238
          # these particular values make the Youtube API return the downloadable video URL
          :clientName => "ANDROID",
          :clientVersion => "16.49"
        }
      },
      :videoId => video_id
    }.to_json

    end_point = "https://www.youtube.com/youtubei/v1/player"
    headers = { "Content-Type" => "application/json" }

    response = Faraday.post(end_point, payload, headers)

    if response.status != 200
      update_status("error")
      raise "Youtube Video Request Failed"
    end

    data = JSON.parse(response.body.to_s)

    data["streamingData"]["formats"].find { |format| format["itag"] == 18 }
  end

  def download_video_to_file!(file, media_url:)
    request = Typhoeus::Request.new(media_url)

    request.on_headers do |response|
      if response.code != 200
        update_status("error")
        raise "Youtube Video Download Failed"
      end
    end

    request.on_body do |chunk|
      file.write(chunk)
    end

    request.run

    file.rewind
  end

  def upload_to_storage_service(file, mime_type:)
    tmp_filename = "#{@video_id}_#{SecureRandom.hex(16)}.mp4"

    GoogleStorageService.new(@bucket_name).upload(
      :file => file,
      :upload_path => tmp_filename,
      :options => {
        :content_type => mime_type
      }
    ).url
  end

  def update_status(value)
    Cache.setex("#{@status_key}:status", CACHE_TTL, value)
  end

end