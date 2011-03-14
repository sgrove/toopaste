#!/usr/local/bin/ruby -rubygems

require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'rack/codehighlighter'
require 'haml'
require 'sass'
require 'uv'

use Rack::Codehighlighter, :ultraviolet, :lines => true, :markdown => false, :element => "pre"

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/toopaste.db")
set :haml, :format => :html5

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

class Snippet
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String, :required => true, :length => 32
  property :language,   String
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

# new
get '/' do
  @languages = %w{Actionscript Active4d Active4d_html Active4d_ini Active4d_library Ada Antlr Apache Applescript Asp Asp_vb.net Bibtex Blog_html Blog_markdown Blog_text Blog_textile Build Bulletin_board C C++ Cake Camlp4 Cm Coldfusion Context_free Cs Css Css_experimental Csv D Diff Dokuwiki Dot Doxygen Dylan Eiffel Erlang F-script Fortran Fxscript Greasemonkey Gri Groovy Gtd Gtdalt Haml Haskell Html Html-asp Html_django Html_for_asp.net Html_mason Html_rails Html_tcl Icalendar Inform Ini Installer_distribution_script Io Java Javaproperties Javascript Javascript_+_prototype Javascript_+_prototype_bracketed Jquery_javascript Json Languagedefinition Latex Latex_beamer Latex_log Latex_memoir Lexflex Lighttpd Lilypond Lisp Literate_haskell Logo Logtalk Lua M Macports_portfile Mail Makefile Man Markdown Mediawiki Mel Mips Mod_perl Modula-3 Moinmoin Mootools Movable_type Multimarkdown Objective-c Objective-c++ Ocaml Ocamllex Ocamlyacc Opengl Pascal Perl Php Plain_text Pmwiki Postscript Processing Prolog Property_list Python Python_django Qmake_project Qt_c++ Quake3_config R R_console Ragel Rd_r_documentation Regexp Regular_expressions_oniguruma Regular_expressions_python Release_notes Remind Restructuredtext Rez Ruby Ruby_experimental Ruby_on_rails S5 Scheme Scilab Setext Shell-unix-generic Slate Smarty Sql Sql_rails Ssh-config Standard_ml Strings_file Subversion_commit_message Sweave Swig Tcl Template_toolkit Tex Tex_math Textile Tsv Twiki Txt2tags Vectorscript Xhtml_1.0 Xml Xml_strict Xsl Yaml Yui_javascript}
  @snippets = Snippet.last(10)
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
  @snippets = Snippet.last(10)
  @snippet = Snippet.get(params[:id])
  if @snippet
    if @snippet.language
      @snippet.body = ":::#{h @snippet.language.downcase}\n#{@snippet.body}"
    else
      @snippet.body = ":::blog_text\n#{@snippet.body}\n"
    end
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
