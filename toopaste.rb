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

configure do
  use Rack::Flash
  enable :sessions

  set :pagetitle, 'paste.geekosphere.org'
  set :haml, :format => :html5
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
end

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

# the default location of sinatra for static files is ./public, this
# creates the directory for ultraviolet and copies the theme stylesheets.
# the other solution would be to copy the files in the repo.
uv_path = File.join(File.dirname(__FILE__), 'public', 'ultraviolet')
if not File.exists? uv_path
  Dir.mkdir(uv_path)
  Uv.copy_files('xhtml', uv_path)
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/toopaste.db")

class Snippet
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String
  property :language,   String
  property :body,       Text,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  def title
    if not @title.empty?
      @title
    else
      "##{@id}"
    end
  end

  # make sure the accessed language is supported by ultraviolet
  def language
    if LANGUAGES.keys.include? @language
      return @language
    else
      return 'plain_text'
    end
  end

  def filename
    safe_title = 'toopaste-' + title.gsub(/[^\w\-\.]/,'')
    Uv.get_syntaxes.each do |syntax|
      if syntax.first == @language and not syntax[1].fileTypes.empty?
        return "#{safe_title}.#{syntax[1].fileTypes.first}"
      end
    end
    return "#{safe_title}.txt"
  end
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
get %r{/(raw|download)?/?(\d+)} do # '/:id' do
  raw = true if params[:captures][0] and params[:captures][0] == 'raw'
  download = true if params[:captures][0] and params[:captures][0] == 'download'
  id = params[:captures][1]

  @snippet = Snippet.get(id)
  if @snippet
    if raw or download
      disposition = 'inline'
      disposition = 'attachment' if download

      content_type 'text/plain'
      headers['Content-Disposition'] = "#{disposition}; filename=\"#{@snippet.filename}\""
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

    @title = "#{@snippet.title} | #{settings.pagetitle}"

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

