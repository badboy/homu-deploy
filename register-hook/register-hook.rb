#!/usr/bin/env ruby
# encoding: utf-8

require 'optparse'
require 'rubygems'
require 'bundler/setup'
require 'octokit'
require 'securerandom'
require 'yaml'

DEFAULT_REVIEWERS = ['you']
DEFAULT_TRY_USERS = []

HOMU_USER = "your-homu-user"
HOMU_TRAVIS_TOKEN = ENV['TRAVIS_TOKEN']
HOMU_PAYLOAD_URL = "http://your-homu-url.example.com/github"
TRAVIS_NOTIFY_DOMAIN = "notify.travis-ci.org"

def random_token
  SecureRandom.hex(20)
end

def config(owner, name, reviewers, try_users, secret)
  [{
    "owner"     => owner,
    "name"      => name,
    "reviewers" => reviewers || DEFAULT_REVIEWERS,
    "try_users" => try_users || DEFAULT_TRY_USERS,
    "secret"    => secret,
  }].to_yaml
end

def repo_slug(owner, repo)
  "#{owner}/#{repo}"
end

def add_homu_user(client, slug)
  client.add_collaborator(slug, HOMU_USER)
end

def cleanup_old_webhook(client, slug)
  hooks = client.hooks(slug)
    .select{|h| h[:name] == "web" && h["config"]["url"] == HOMU_PAYLOAD_URL }

  hooks.each do |hook|
    client.remove_hook(slug, hook[:id])
  end
end

def create_webhook(client, slug, secret)
  config = {
    "url" => HOMU_PAYLOAD_URL,
    "content_type" => "json",
    "secret" => secret,
  }
  options = {
    "events": [
      "push",
      "pull_request",
      "issue_comment",
      "status"
    ]
  }

  client.create_hook(slug, "web", config, options)
end

options = {}
optparser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename $0} [options] <owner> <repo>"

  opts.on("-r x,y,z", "--reviewer x,y,z", Array, "List of allowed reviewers") do |r|
    options[:reviewers] = r
  end

  opts.on("-t x,y,z", "--try-users x,y,z", Array, "List of allowed try users") do |t|
    options[:try_users] = t
  end
end
optparser.parse!

if ARGV.size != 2
  puts "Wrong number of arguments"
  puts
  puts optparser.help
  exit 2
end

owner = ARGV.shift
repo  = ARGV.shift
slug = repo_slug(owner, repo)

client = Octokit::Client.new(:netrc => true)

secret = random_token

add_homu_user(client, slug)
cleanup_old_webhook(client, slug)
create_webhook(client, slug, secret)
c = config(owner, repo, options[:reviewers], options[:try_users], secret)
puts c.sub(/^---$/, '').gsub(/^(.)/, '    \1')
