class Admin::TranscriptsController < AdminController

  def download_youtube_video
    status_key = TriggerDownloadAndStoreVideoFromYoutube
                   .run(:youtube_url => params[:youtube_url])
                   .result

    render :json => { :status_key => status_key }
  end

  def youtube_video_download_status
    status = Cache.get("#{params[:status_key]}:status")
    url = Cache.get("#{params[:status_key]}:url")

    render :json => { :status => status, :url => url }
  end

end