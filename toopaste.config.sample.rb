configure do
  set :adminpass, 'changeme'
  set :default_theme, 'zenburnesque'
  set :pagetitle, 'paste.geekosphere.org'
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

  # you shouldn't use your owner account here, create a
  # dedicated rbot user:
  #
  #   user create toopaste changeme
  #   permissions set +remotectl for toopaste
  #   permissions set +basics::talk::do::say for toopaste
  #
  set :announce_irc, {
    :uri => 'druby://127.0.0.1:7268',
    :user => 'toopaste',
    :pass => 'changeme',
    :channel => '#changeme'
  }
end
