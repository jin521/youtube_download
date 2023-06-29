# frozen_string_literal: true

Rails.application.routes.draw do
  resources :transcripts, only: [] do
    collection do
      post :download_youtube_video
      get :youtube_video_download_status
    end
  end
end
