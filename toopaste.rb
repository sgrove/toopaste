#!/usr/local/bin/ruby -rubygems

require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'haml'
require 'sass'
require 'uv'
require 'rack-flash'

set :default_theme, 'zenburnesque'
set :preferred_languages, [
  'plain_text',
  'ruby',
  'python',
  'tcl',
  'javascript',
  'html',
  'c',
  'c++',
  'java',
  'php'
]

use Rack::Flash
enable :sessions
set :haml, :format => :html5

# setup constants for supported languages and themes, in ultraviolet they are 
# called syntax_name and render_style. In order to access the Textpow objects
# that include pretty names for each supported syntax file we need to extend
# the ultraviolet module because it does not provide an accessor:
module Uv
  def Uv.get_syntaxes
    @syntaxes
  end
end
languages = {}
Uv.init_syntaxes unless Uv.get_syntaxes
Uv.get_syntaxes.each do |syntax|
  languages[syntax.first] = syntax[1].name
end
LANGUAGES = languages
THEMES = Uv.themes

# this serves the static ultraviolet css files directly, another solution
# would be to copy these files to ./public (Uv.copy_files)
set :public, Uv.path.first + '/render/xhtml/files'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/toopaste.db")

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

class Snippet
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String, :required => true
  property :language,   String
  property :body,       Text,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!

# stylesheet
get '/stylesheet.css' do
    scss :stylesheet, :style => :compact
end

# new
get '/' do
  @preferred_languages = settings.preferred_languages
  @snippets = Snippet.last(10)
  haml :new
end

# create
post '/' do
  if LANGUAGES.keys.include? params[:snippet_language]
    language = params[:snippet_language]
  else
    language = 'plain_text'
  end

  @snippet = Snippet.new(:title => params[:snippet_title],
                         :body  => params[:snippet_body],
                      :language => language)

  if @snippet.save
    redirect "/#{@snippet.id}"
  else
    flash[:error] = "<strong>Uh-oh, something went wrong:</strong><br />"
    @snippet.errors.each { |e| flash[:error] += e.to_s + ".<br />" }
    redirect '/'
  end
end

# show
get %r{/(raw/)?(\d+)} do # '/:id' do
  raw = true if params[:captures][0]
  id = params[:captures][1]

  @snippet = Snippet.get(id)
  if @snippet
    if raw
      content_type 'text/plain'
      return @snippet.body    
    end

    # active theme (render_style)
    if session.has_key? :active_theme 
      # user selected theme saved in cookie
      @active_theme = session[:active_theme]  
    else
      @active_theme = settings.default_theme
    end

    @content = Uv.parse(@snippet.body, 'xhtml', @snippet.language, true, @active_theme)

    haml :show
  else
    raise not_found
  end
end

# switch active theme
post '/switch_theme' do
  if THEMES.include? params[:theme]
    session[:active_theme] = params[:theme]
  end
  redirect to("/#{params[:snippet_id]}")
end

# 404
not_found do
  haml :error404
end

# 403
error 403 do
  haml :error403
end

# other errors
error do
  haml :error500
end

