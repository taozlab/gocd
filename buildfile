#*************************GO-LICENSE-START********************************
# Copyright 2014 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or a-qgreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#*************************GO-LICENSE-END**********************************

require 'java' if RUBY_PLATFORM == "java"
require 'json'

$PROJECT_BASE = File.expand_path("../", __FILE__)

RUNNING_TESTS = 'running_tests'

def running_tests?
  ENV[RUNNING_TESTS] == 'true'
end

def running_tests!
  ENV[RUNNING_TESTS] = 'true'
end

def not_running_tests!
  ENV[RUNNING_TESTS] = 'false'
end

# Generated by Buildr 1.3.4, change to your liking
# Version number for this release
GO_VERSION     = '15.3.0'
VERSION_NUMBER = if ENV['GO_DIST_VERSION']
                   "#{GO_VERSION}-#{ENV['GO_DIST_VERSION']}"
                 else
                   GO_VERSION
                 end

# Group identifier for your projects
GROUP          = "cruise"

#discover the revision and commit digest
def stdout_of command
  Util.win_os? && command.gsub!(/'/, '"')
  stdout = `#{command}`
  $?.success? || fail("`#{command}` failed")
  stdout
end

GIT_SHA          = stdout_of("git log -1 --pretty='%H'").strip
RELEASE_REVISION = stdout_of("git log --pretty=format:''").length
RELEASE_COMMIT   = "#{RELEASE_REVISION}-#{GIT_SHA}"

# Specify Maven 2.0 remote repositories here, like this:
repositories.remote << "http://repo1.maven.org/maven2/"

desc "Go - ThoughtWorks Studios"
define "cruise" do |project|
  compile.options[:other] = %w[-encoding UTF-8 -target 1.7 -source 1.7]
  TMP_DIR                 = test.options[:properties]['java.io.tmpdir'] = _('target/temp')
  mkpath TMP_DIR

  manifest['Go-Version'] = VERSION_NUMBER

  project.version = VERSION_NUMBER
  project.group   = GROUP

  ENV["VERSION_NUMBER"] = VERSION_NUMBER
  ENV["RELEASE_COMMIT"] = RELEASE_COMMIT

  require './cruise-modules'

  desc "generate a version file"
  task :version_file do
    mkdir_p _('target', 'pkg')
    File.open(_('target', 'pkg', 'version.json'), 'w') do |f|
      f.puts(JSON.pretty_generate({
                                    go_version:       GO_VERSION,
                                    go_build_number:  RELEASE_REVISION,
                                    maven_version:    VERSION_NUMBER,
                                    git_sha:          GIT_SHA,
                                    pipeline_name:    ENV['GO_PIPELINE_NAME'],
                                    pipeline_counter: ENV['GO_PIPELINE_COUNTER'],
                                    pipeline_label:   ENV['GO_PIPELINE_LABEL'],
                                    stage_name:       ENV['GO_STAGE_NAME'],
                                    stage_counter:    ENV['GO_STAGE_COUNTER'],
                                    job_name:         ENV['GO_JOB_NAME']
                                  }))
    end
  end

  desc "bump version number"
  task :update_versions do
    bump_command = "mvn versions:set -DnewVersion=#{VERSION_NUMBER} -DgenerateBackupPoms=false --batch-mode"
    sh(bump_command, verbose: true)
  end

  clean do
    mkpath TMP_DIR
  end
end

