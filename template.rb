require "fileutils"

############################################################
# add needed gemfiles
############################################################
gem 'tzinfo-data'

gem_group :production do
  gem 'pg', '>= 0.18'
end

gem_group :development do
  gem 'sqlite3'
  gem 'simplecov'
end

gem_group :test do
  gem 'sqlite3'
  gem 'rubocop'
end

############################################################
# create dockerfile
############################################################
create_file 'Dockerfile' do
    <<-CODE
FROM ruby:2.5.1-alpine
LABEL maintainer="cheimke@loumaris.com"

EXPOSE 3000

WORKDIR /app

RUN apk --update add build-base git sqlite sqlite-dev sqlite-libs postgresql-dev && \
    gem install bundler

COPY . /app

RUN bundle install --jobs 20
    CODE
  end

############################################################
# create dockerignore
############################################################
create_file '.dockerignore' do
  <<-CODE
.git/
log/
Dockerfile
*.md
.dockerignore
.gitignore
  CODE
end

############################################################
# create gitlab ci
############################################################
create_file '.gitlab-ci.yml' do
  <<-CODE
stages:
  - test

test:
  stage: test
  script:
    - docker build -t #{@underscored_name} .
    - docker run -e "RAILS_ENV=test" #{@underscored_name} rails app:#{@underscored_name}:test
  tags:
    - dev
  CODE
end

############################################################
# create rubocop config
############################################################
create_file '.rubocop.yml' do
  <<-CODE
AllCops:
  Exclude:
    - db/**/*
    - config/**/*
    - bin/**/*
    - test/**/*

Metrics/LineLength:
  Max: 120

Style/Documentation:
  Enabled: false

Metrics/MethodLength:
  Max: 15
  CODE
end

############################################################
# add coverage directory to gitignore
############################################################
append_to_file '.gitignore' do
  "coverage/"
end

############################################################
# add simplecov to test helper
############################################################
insert_into_file 'test/test_helper.rb', after: /"test"/ do
  <<-RUBY

# simple coverage
require 'simplecov'
SimpleCov.start 'rails'
  RUBY
end

############################################################
# create rake task to run test suite
############################################################
rakefile("#{@underscored_name}_task.rake") do
  <<-TASK
    namespace :#{@underscored_name} do
      desc 'run testsuite'
      task test: ['db:migrate', :rubocop, 'test']

      desc 'run rubocop'
      task rubocop: :environment do
        sh 'rubocop app/'
      end
    end
  TASK
end


############################################################
# init git
############################################################
run """
cd ../../
git init
git add .
git commit -m 'init commit'
"""