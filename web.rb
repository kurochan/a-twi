require 'sinatra'
require 'sinatra/reloader'
require 'yaml'
require 'omniauth-twitter'
require 'twitter'

set :server, 'webrick'
CONFIG = YAML.load_file(File.expand_path('../config/config.yml', __FILE__))

configure do
  enable :sessions

  use OmniAuth::Builder do
    provider :twitter, CONFIG['twitter']['consumer_key'], CONFIG['twitter']['consumer_secret']
  end
end

helpers do
  # current_userは認証されたユーザーのことです
  def current_user
    !session[:auth].nil?
  end
end

before do
  # /auth/からパスが始まる時はTwitterへリダイレクトしたいわけではないので
  pass if request.path_info =~ /^\/auth\//

  # /auth/twitterはOmniAuthが使います
  # /auth/twitterに当てはまる場合、Twitterへリダイレクトします。
  redirect to('/auth/twitter') unless current_user
end

get '/auth/twitter/callback' do
  # ひょっとするとデータベースにも登録したくなるかもしれません。
  session[:auth] = env['omniauth.auth']['credentials']
  # これはあなたのアプリケーションへユーザーを戻すメソッドです
  redirect to('/')
end

get '/auth/failure' do
  # OmniAuthはなにか問題が起こると/auth/failureへリダイレクトします。
  # ここにあなたは何らかの処理を書くべきでしょう
end

get '/' do
  '<html><h3><a href=\'/a-twi\'>投稿する</a></h3></html>'
end

get '/a-twi' do
  client = Twitter::REST::Client.new(
    :consumer_key => CONFIG['twitter']['consumer_key'],
    :consumer_secret => CONFIG['twitter']['consumer_secret'],
    :access_token => session[:auth][:token],
    :access_token_secret => session[:auth][:secret]
  )
  client.update "暑い"
  '<html><h1>投稿しました</h1></br><a href=\'/\'>戻る</a></html>'
end
