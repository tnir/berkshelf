require "aruba/api"

World(Aruba::Api)
World(Berkshelf::RSpec::ChefAPI)
World(Berkshelf::RSpec::FileSystemMatchers)

Given /^a cookbook named "(.*?)"$/ do |name|
  create_directory(name)
  write_file(File.join(name, "metadata.rb"), "name '#{name}'")
end

Given /^the cookbook "(.*?)" has the file "(.*?)" with:$/ do |cookbook_name, file_name, content|
  write_file(::File.join(cookbook_name, file_name), content)
end

Given /^the cookbook store has the cookbooks:$/ do |cookbooks|
  cookbooks.raw.each do |name, version, license|
    generate_cookbook(cookbook_store.storage_path, name, version, license: license)
  end
end

Given /^the cookbook store has the git cookbooks:$/ do |cookbooks|
  cookbooks.raw.each do |name, version, sha|
    folder   = "#{name}-#{sha}"
    metadata = File.join(folder, "metadata.rb")

    create_directory(folder)
    write_file(metadata, [
      "name '#{name}'",
      "version '#{version}'",
    ].join("\n"))
  end
end

Given /^the cookbook store contains a cookbook "(.*?)" "(.*?)" with dependencies:$/ do |name, version, dependencies|
  generate_cookbook(cookbook_store.storage_path, name, version, dependencies: dependencies.raw)
end

Given(/^the cookbook store cookbook "(.*?)" "(.*?)" is vendored without a metadata.rb$/) do |name, version|
  cookbook_path = File.join(cookbook_store.storage_path, "#{name}-#{version}")
  cookbook = Berkshelf::CachedCookbook.from_path(cookbook_path)
  cookbook.compile_metadata
  metadata_file = File.join(cookbook_path, "metadata.rb")
  File.unlink(metadata_file) if File.file?(metadata_file)
end

Given(/^the cookbook store cookbook "(.*?)" "(.*?)" is vendored with a metadata.rb$/) do |name, version|
  cookbook_path = File.join(cookbook_store.storage_path, "#{name}-#{version}")
  cookbook = Berkshelf::CachedCookbook.from_path(cookbook_path)
  cookbook.compile_metadata
  metadata_file = File.join(cookbook_path, "metadata.rb")
  raise "internal error, fixture cookbook should have a metadata.rb" unless File.file?(metadata_file)
end

Given(/^the cookbook store is empty$/) do
  Berkshelf::CookbookStore.instance.clean!
end

Then /^the cookbook store should have the cookbooks:$/ do |cookbooks|
  cookbooks.raw.each do |name, version|
    expect(cookbook_store.storage_path).to have_structure {
      directory "#{name}-#{version}" do
        file "metadata.{rb,json}" do
          contains version
        end
      end
    }
  end
end

Then /^the cookbook store should have the git cookbooks:$/ do |cookbooks|
  cookbooks.raw.each do |name, version, sha1|
    expect(cookbook_store.storage_path).to have_structure {
      directory "#{name}-#{sha1}" do
        file "metadata.{rb,json}" do
          contains version
        end
      end
    }
  end
end

Then /^the cookbook store should not have the cookbooks:$/ do |cookbooks|
  cookbooks.raw.each do |name, version|
    expect(cookbook_store.storage_path).to_not have_structure {
      directory "#{name}-#{version}"
    }
  end
end

Then /^I should have a new cookbook skeleton "(.*?)"$/ do |name|
  cb_path = Pathname.new(current_dir).join(name)
  expect(cb_path).to have_structure {
    directory "attributes"
    directory "files" do
      directory "default"
    end
    directory "libraries"
    directory "providers"
    directory "recipes" do
      file "default.rb"
    end
    directory "resources"
    directory "templates" do
      directory "default"
    end
    file ".gitignore"
    file "chefignore"
    file "Berksfile" do
      contains "metadata"
    end
    file "Gemfile"
    file "metadata.rb"
    file "README.md"
    file "Vagrantfile" do
      contains "recipe[#{name}::default]"
    end
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with Chef-Minitest support$/ do |name|
  steps %Q{ Then I should have a new cookbook skeleton "#{name}" }

  cb_path = Pathname.new(current_dir).join(name)
  expect(cb_path).to have_structure {
    file "Berksfile" do
      contains "cookbook 'minitest-handler'"
    end
    file "Vagrantfile" do
      contains "recipe[minitest-handler::default]"
    end
    directory "files" do
      directory "default" do
        directory "tests" do
          directory "minitest" do
            file "default_test.rb" do
              contains "describe '#{name}::default' do"
              contains "include Helpers::#{name.capitalize}"
            end
            directory "support" do
              file "helpers.rb" do
                contains "module #{name.capitalize}"
              end
            end
          end
        end
      end
    end
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with Foodcritic support$/ do |name|
  steps %Q{ Then I should have a new cookbook skeleton "#{name}" }

  cb_path = Pathname.new(current_dir).join(name)
  expect(cb_path).to have_structure {
    file "Gemfile" do
      contains "gem 'thor-foodcritic'"
    end
    file "Thorfile" do
      contains "require 'thor/foodcritic'"
    end
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with SCMVersion support$/ do |name|
  steps %Q{ Then I should have a new cookbook skeleton "#{name}" }

  cb_path = Pathname.new(current_dir).join(name)
  expect(cb_path).to have_structure {
    file "Gemfile" do
      contains "gem 'thor-scmversion'"
    end
    file "Thorfile" do
      contains "require 'thor/scmversion'"
    end
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with no Bundler support$/ do |name|
  cb_path = Pathname.new(current_dir).join(name)
  expect(cb_path).to have_structure {
    directory "attributes"
    directory "files" do
      directory "default"
    end
    directory "libraries"
    directory "providers"
    directory "recipes" do
      file "default.rb"
    end
    directory "resources"
    directory "templates" do
      directory "default"
    end
    file "README.md"
    file "metadata.rb"
    file "Berksfile" do
      contains "metadata"
    end
    file "chefignore"
    file "Berksfile"
    no_file "Gemfile"
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with no Git support$/ do |name|
  expect(Pathname.new(current_dir).join(name)).to have_structure {
    no_file ".gitignore"
  }
end

Then /^I should have a new cookbook skeleton "(.*?)" with no Vagrant support$/ do |name|
  expect(Pathname.new(current_dir).join(name)).to have_structure {
    file "Gemfile" do
      does_not_contain "gem 'vagrant'"
    end
    no_file "Vagrantfile"
  }
end

Then(/^I should have a new cookbook skeleton "(.*?)" with no Test Kitchen support$/) do |name|
  expect(Pathname.new(current_dir).join(name)).to have_structure {
    file "Gemfile" do
      does_not_contain "gem 'test-kitchen'"
    end
    no_file ".kitchen.yml"
    no_file ".kitchen.yml.local"
  }
end

Then /^the cookbook "(.*?)" should have the following files:$/ do |name, files|
  check_file_presence(files.raw.map { |file_row| ::File.join(name, file_row[0]) }, true)
end

Then /^the cookbook "(.*?)" should not have the following files:$/ do |name, files|
  check_file_presence(files.raw.map { |file_row| ::File.join(name, file_row[0]) }, false)
end

Then /^the git cookbook "(.*?)" should not have the following directories:$/ do |name, directories|
  !directories.raw.map do |directory_row|
    ::File.join(cookbook_store.storage_path.to_path, name, directory_row[0])
  end.any? { |a_dir| Dir.exist?(a_dir) }
end

Then /^the file "(.*?)" in the cookbook "(.*?)" should contain:$/ do |file_name, cookbook_name, content|
  expect(Pathname.new(current_dir).join(cookbook_name)).to have_structure {
    file "Berksfile" do
      contains content
    end
    file "chefignore"
  }
end

Then /^the resulting "(.+)" Vagrantfile should contain:$/ do |cookbook_name, content|
  expect(Pathname.new(current_dir).join(cookbook_name)).to have_structure {
    file "Vagrantfile" do
      if content.respond_to?(:raw)
        content.raw.flatten.each { |string| contains string }
      else
        contains(content)
      end
    end
  }
end

Then /^the directory "(.*?)" should have the following files:$/ do |name, files|
  check_file_presence(files.raw.map { |file_row| ::File.join(name, file_row[0]) }, true)
end

Then /^the directory "(.*?)" should not have the following files:$/ do |name, files|
  check_file_presence(files.raw.map { |file_row| ::File.join(name, file_row[0]) }, false)
end

Then /^the file "(.*?)" in the directory "(.*?)" should not contain:$/ do |file_name, directory_name, content|
  Pathname.new(current_dir).join(directory_name).should_not have_structure {
    file "Berksfile" do
      contains content
    end
  }
end

Then(/^the directory "(.*?)" should contain version "(.*?)" of the "(.*?)" cookbook$/) do |path, version, name|
  cookbook_path = expand_path(path)
  cookbook = Berkshelf::CachedCookbook.from_path(cookbook_path)
  expect(cookbook.version).to eq(version)
  expect(cookbook.cookbook_name).to eq(name)
end
