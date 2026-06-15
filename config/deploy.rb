# config valid for current version and patch releases of Capistrano
lock "~> 3.20.1"

set :application, "dumarket"
set :repo_url, "git@github.com:nwxxb/dumarket.git"
set :branch, :main

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# we don't put config/database.yml because it's already checked to git
# and not contain any secret
append :linked_files, "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "vendor/javascript", "tmp/sockets", "public/system", "storage"

# Default value for default_env is {}
set :default_env, {path: "/home/deployer/.local/share/mise/shims:$PATH"}

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
set :ssh_options, verify_host_key: :secure

# capistrano3-puma: https://github.com/seuros/capistrano-puma
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_enable_lingering, false
