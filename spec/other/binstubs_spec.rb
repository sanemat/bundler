require "spec_helper"

describe "bundle binstubs <gem>" do
  context "when the gem exists in the lockfile" do
    it "sets up the binstub" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "binstubs rack"

      expect(bundled_app("bin/rackup")).to exist
    end

    it "does not install other binstubs" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rails"
      G

      bundle "binstubs rails"

      expect(bundled_app("bin/rackup")).not_to exist
      expect(bundled_app("bin/rails")).to exist
    end

    it "does not bundle the bundler binary" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
      G

      bundle "binstubs bundler"

      expect(bundled_app("bin/bundle")).not_to exist
      expect(out).to eq("Skipping bundler, since can't bundle bundler.")
    end

    it "install binstubs from git gems" do
      FileUtils.mkdir_p(lib_path("foo/bin"))
      FileUtils.touch(lib_path("foo/bin/foo"))
      build_git "foo", "1.0", :path => lib_path("foo") do |s|
        s.executables = %w(foo)
      end
      install_gemfile <<-G
        gem "foo", :git => "#{lib_path('foo')}"
      G

      bundle "binstubs foo"

      expect(bundled_app("bin/foo")).to exist
    end

    it "installs binstubs from path gems" do
      FileUtils.mkdir_p(lib_path("foo/bin"))
      FileUtils.touch(lib_path("foo/bin/foo"))
      build_lib "foo" , "1.0", :path => lib_path("foo") do |s|
        s.executables = %w(foo)
      end
      install_gemfile <<-G
        gem "foo", :path => "#{lib_path('foo')}"
      G

      bundle "binstubs foo"

      expect(bundled_app("bin/foo")).to exist
    end
  end

  context "--binstubs" do
    it "sets the binstubs dir" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "binstubs rack --binstubs exec"

      expect(bundled_app("exec/rackup")).to exist
    end

    it "setting is saved for bundle install" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rails"
      G

      bundle "binstubs rack --binstubs exec"
      bundle :install

      expect(bundled_app("exec/rails")).to exist
    end
  end

  context "when the bin already exists" do
    it "don't override it and warn" do
      FileUtils.mkdir_p(bundled_app("bin"))
      File.open(bundled_app("bin/rackup"), 'wb') do |file|
        file.print "OMG"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "binstubs rack"

      expect(bundled_app("bin/rackup")).to exist
      expect(File.read(bundled_app("bin/rackup"))).to eq("OMG")
      expect(out).to eq("Skipping rackup, since it already exists.")
    end

    context "when using --force" do
      it "overrides the binstub" do
        FileUtils.mkdir_p(bundled_app("bin"))
        File.open(bundled_app("bin/rackup"), 'wb') do |file|
          file.print "OMG"
        end

        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack"
        G

        bundle "binstubs rack --force"

        expect(bundled_app("bin/rackup")).to exist
        expect(File.read(bundled_app("bin/rackup"))).not_to eq("OMG")
      end
    end
  end
end