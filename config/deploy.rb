# SMARTFLIX 
#
# deploy to external servers only: 
#      cap deploy 
#
# deploy to internal servers only:
#      cap deploy -S site=internal
#
# deploy to staging servers only (note: need 'stage' in /etc/hosts
#      cap deploy -S site=stage
#
#   restart:
#         cap deploy:restart [ -S ... ]

#----------
# variables 
#----------

set :application, "sfw"
set :repository, "svn+ssh://nitrogen/svn/bus/sf/src/#{application}"
set :use_sudo, false
set :rvm_install_with_sudo, true
set :checkout, 'export'
set :internal, @variables[:site] == "internal"

#----------
# rvm 
#----------
set :rvm_type, :system
set :rvm_ruby_string, "1.9.3-p429"
set :rvm_autolibs_flag, "read-only"        # more info: rvm help autolibs
before 'deploy:setup', 'rvm:install_rvm'   # install RVM
before 'deploy:setup', 'rvm:install_ruby'  # install Ruby and create gemset, OR:
before 'deploy:setup', 'rvm:create_gemset' # only create gemset
require "rvm/capistrano"

#----------
# target machines
#----------
set :rails_env, "production"
set :user,      "smart"
set :deploy_to, "/home/smart/rails/#{application}"

if @variables[:site] == "internal"

  role :web,      "sf-internal"
  role :app,      "sf-internal"
  role :db,       "sf-internal"

elsif @variables[:site] == "stage"

  role :web,      "sf-stage"
  role :app,      "sf-stage"
  role :db,       "sf-stage"
  set :rails_env, "stage"

else
  # storm
  role :web,         "smartflix.com"
  role :app,         "smartflix.com"
  role :db,          "smartflix.com"
end

#----------
# restart
#----------

deploy.task :restart, :roles => :web  do
  run "touch #{release_path}/tmp/restart.txt"
end

#----------
# deploy
#----------

deploy.task :update_code, :roles => [:app, :db, :web] do

  on_rollback { delete release_path, :recursive => true }

  # 1: build a tarball and push it
  #
  temp_dest = "export_for_deployment"
  tgz = "to_deploy.tgz"

  system("rm -rf #{temp_dest} #{tgz}")
  system("svn export -q #{repository} #{temp_dest}")
  system("tar -C #{temp_dest} -czf #{tgz}  --exclude='./config/sf_decrypt_key.pem' .")
  put(File.read(tgz), tgz, {:via => :scp})
  
  # 2: untar the code on the server
  #
  run <<-CMD
    mkdir -p  #{release_path}             &&
    tar -C    #{release_path} -xzf #{tgz} 
  CMD

  # 3: symlink the shared paths into our release directory
  #
  run <<-CMD
    ln -nfs #{shared_path}/log                #{release_path}/log                         &&
    ln -nfs #{shared_path}/public/assets      #{release_path}/public/assets               &&
    ln -nfs #{shared_path}/vendor/bundle      #{release_path}/vendor/bundle               &&
    ln -nfs #{deploy_to}/vidcaps              #{release_path}/public/vidcaps              &&
    ln -nfs #{deploy_to}/archive              #{release_path}/public/archive              &&
    ln -nfs #{deploy_to}/contest_entry_photos #{release_path}/public/contest_entry_photos &&
    ln -nfs #{deploy_to}/project_images       #{release_path}/public/project_images       &&
    ln -nfs #{deploy_to}/newsletter_static    #{release_path}/public/newsletter_static    
  CMD

  # 4: on internal systems make sure that there's a link to the decrypt key 
  # 
  if internal
    run <<-CMD
      ln -nfs #{shared_path}/config/sf_decrypt_key.pem #{release_path}/config/sf_decrypt_key.pem
    CMD
  end

  # clean up our archives
  run "rm -f #{tgz}"
  system("rm -rf #{temp_dest} #{tgz}")
end

#----------
# after deploy
#----------

after "deploy:update_code" do

  # Bundle
  #
  #   note that --deployment means to store gems in current/vendor/bundle
  #
  #   * Advantages   : no need for sudo
  #   * Disadvantages: unless you swizzle a link to shared_path, you do a TON of work each time
  #
  # We use a symlink to avoid the disadvantages.
  #
  run "cd #{release_path} && bundle install --deployment  --without development test"

  # update crontab
  #
  run("crontab #{release_path}/crontabs/$CAPISTRANO:HOST$/smart-tab.txt", :shell =>false)


  # update other things
  #
  if internal
    # nothing
  else
#    run("cd #{release_path} ; RAILS_ENV=#{rails_env} rake assets:precompile ")
    run("cd #{release_path} ; rake ts:configure RAILS_ENV=#{rails_env}")
    run("cd #{release_path} ; rake ts:rebuild RAILS_ENV=#{rails_env}")

  end


end
