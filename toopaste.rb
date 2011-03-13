#!/usr/local/bin/ruby -rubygems

# TO DO:
# - snippet retention
# - language selection
# - deletion url
# - tags
# - line wrapping?

require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'coderay'
require 'rack/codehighlighter'
require 'haml'
require 'sass'

set :haml, :format => :html5

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

use Rack::Codehighlighter, :coderay, :element => "pre", :pattern => /\A:::(\w+)\s*\n/

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/toopaste.db")

class Snippet
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String, :required => true, :length => 32
  property :language,   String
  property :body,       Text,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_presence_of :body
  validates_length_of :body, :minimum => 1
end

DataMapper.finalize
DataMapper.auto_upgrade!
#File.open('toopaste.pid', 'w') { |f| f.write(Process.pid) }

# stylesheet
get '/stylesheet.css' do
    scss :stylesheet, :style => :compact
end

# list
get '/' do
    @snippets = Snippet.all
    if @snippets
        haml :list
    else
        redirect '/new'
    end
end

# new
get '/new' do
    @languages = %w{C CSS Delphi diff HTML RHTML Nitro-XHTML Java JavaScript JSON Ruby YAML}
    haml :new
end

# create
post '/' do
  @snippet = Snippet.new(:title => params[:snippet_title],
                         :body  => params[:snippet_body],
                      :language => params[:snippet_language])

  if @snippet.save
    redirect "/#{@snippet.id}"
  else
    redirect '/'
  end
end

# show
get '/:id' do
  @snippet = Snippet.get(params[:id])
  if @snippet
    haml :show
  else
    raise not_found
  end
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
