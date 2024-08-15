source "https://rubygems.org"

gemspec

group :build do
  gem "rake",          ">= 10.1"
end

ruby_version = Gem::Version.new(RUBY_VERSION)

r310 = Gem::Version.new("3.1.0")
r300 = Gem::Version.new("3.0.0")

install_if -> { ruby_version >= r310 } do
  gem "minitar", "~> 1.0"
  gem "chef", ">= 18.0.0"
end

install_if -> { (r300...r310) === ruby_version } do
  gem "minitar", "~> 0.12"
  gem "chef", "~> 17.0"
end

install_if -> { ruby_version < r300 } do
  gem "minitar", "~> 0.12"
  gem "chef", ">= 15.7.32"
end


group :development do
  gem "aruba",         "~> 0.10" # Stay below 1 until aruba/in_process monkeypatching stops
  gem "debug"
  gem "cucumber",      ">1.0.5", "< 4.0" # until we identify what is generating the ~@no_run tag in CI
  gem "cucumber-expressions", "= 5.0.13"
  gem "chef-zero",     ">= 4.0"
  gem "dep_selector",  ">= 1.0"
  gem "fuubar",        ">= 2.0"
  gem "rspec",         ">= 3.0"
  gem "rspec-its",     ">= 1.2"
  gem "webmock",       ">= 1.11"
  gem "http",          ">= 0.9.8"
  gem "chefstyle"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
