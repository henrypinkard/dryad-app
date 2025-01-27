
Steps for setting up Dryad on a new EC2 machine with Amazon Linux 2023
======================================================================

- Install an SSH key, so you can login to the machine directly
- git
```
sudo yum update
sudo yum install git
```
- emacs, ack
```
sudo yum install emacs-nox
mkdir emacs
curl "https://raw.githubusercontent.com/yoshiki/yaml-mode/master/yaml-mode.el" >emacs/yaml-mode.el
mkdir bin
curl https://beyondgrep.com/ack-v3.7.0 > ~/bin/ack && chmod 0755 ~/bin/ack
```
- git setup
  - edit the `/.ssh/known_hosts` file to contain the keys from https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
- install mysql
  - WARNING! MySQL may make their RPM unavailable, forcing you to go through
    their stupid GUI to get it. If so, just find the closest available version
    and copy it to the target machine.
```
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm 
sudo dnf install mysql80-community-release-el9-5.noarch.rpm -y
sudo dnf install mysql-community-server -y
sudo yum install mysql-devel
```
- check out the Dryad code
```
git clone https://github.com/CDL-Dryad/dryad-app.git
```
- install ruby
```
sudo yum install ruby
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison perl-core icu libicu-devel
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bash_profile
# restart the shell
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
git -C "$(rbenv root)"/plugins/ruby-build pull
cd dryad-app
rbenv install $(cat .ruby-version)
rbenv global $(cat .ruby-version)
sudo gem update --system --no-user-install
gem install libv8 -v '3.16.14.19' --
gem install therubyracer -v '0.12.3' --
gem install mysql2 -v '0.5.3' -- 
bundle install
```
- install node
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
nvm install 16.20.2
npm install --global yarn
cd ~/dryad-app
yarn install
npm install --legacy-peer-deps
```
- ensure config is correct in startup scripts; add the following to .bashrc
```
. ~/.nvm/nvm.sh
nvm use 16.20.2 >/dev/null
export RAILS_ENV=v3_stage 
```
- compile components
```
bin/webpack
bundle exec rails webpacker:compile
```
- run rails
```
cd ~/dryad-app
rails s
```

Database setup
===============

1. Create the database in RDS. When setting up the database in RDS, you must
   crete a parameter group to set the global variable
   `log_bin_trust_function_creators`. Once the parameter group, assign it to the
   database, and once the database has finished updating the config, reboot the
   database to ensure it takes effect.
2. Ensure the appropriate EC2 instances are "connected compute resources" for the database
3. Login to the EC2 instance and create a script to connect to the RDS instance,
   but not a specific database
   - This normally consists of a script and a `.my.cnf` file
   - Copy them from another server, but remove "dryad" from the script
4. Run the script to connect to the RDS instance, then create the database:
   `CREATE DATABASE dryad CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
5. Update the script to add the "dryad" database name


Importing data into AWS RDS database
=====================================

Backups are run using a cron command:
`nice -n 19 ionice -c 3 bundle exec rails dev_ops:backup RAILS_ENV=$1`

To restore from a backup file:
```
# First remove DEFINER statements because RDS doesn't allow the DB users to have
# enough permissions for them to work properly:
sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i myfile.sql

# Then import using the mysql command that you would normally use to run the DB client:
`mysql_stg.sh < myfile.sql`

