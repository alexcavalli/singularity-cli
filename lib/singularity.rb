require 'erb'
require 'json'
require 'rest-client'
require 'colorize'
require 'yaml'

module Singularity
  class Request
    attr_accessor :release, :cpus, :mem, :envs, :schedule, :cmd, :arguments, :request_id, :repo, :release_string, :release_id_string
    def get_binding
      binding()
    end
  end

  class Deployer
    def initialize(uri, file, release)
      @uri = uri
      @file = file
      @release = release
      @config = ERB.new(open(file).read)
      @r = Request.new
      @r.release = @release
      @data = JSON.parse(@config.result(@r.get_binding))
      print @data['id']
    end

    def is_paused
      begin
        resp = RestClient.get "#{@uri}/api/requests/request/#{@data['id']}"
        JSON.parse(resp)['state'] == 'PAUSED'
      rescue
        print " CREATING...".blue
        false
      end
    end

    def deploy
      begin
        if is_paused()
          puts " PAUSED, SKIPPING".yellow
          return
        else
          # create or update the request
          resp = RestClient.post "#{@uri}/api/requests", @data.to_json, :content_type => :json
        end
        # deploy the request
        @data['requestId'] = @data['id']
        @data['id'] = "#{@release}.#{Time.now.to_i}"
        deploy = {
         'deploy' => @data,
         'user' => `whoami`.chomp,
         'unpauseOnSuccessfulDeploy' => false
        }
        resp = RestClient.post "#{@uri}/api/deploys", deploy.to_json, :content_type => :json
        puts " DEPLOYED".green
      rescue Exception => e
        puts " #{e.response}".red
      end
    end
  end

  class Deleter
    def initialize(uri, file)
      @uri = uri
      @file = file
    end
    # Deleter.delete -- arguments are <uri>, <file>
    def delete
      begin
        task_id = "#{@file}".gsub(/\.\/singularity\//, "").gsub(/\.json/, "")
        # delete the request
        RestClient.delete "#{@uri}/api/requests/request/#{task_id}"
        puts "#{task_id} DELETED"
      rescue
        puts "#{task_id} #{$!.response}"
      end
    end
  end 

  class Runner
    def initialize(script)
      # check to see that .mescal.json and mesos-deploy.yml exist
      #
      # TODO
      #

      # read .mescal.json for ssh command, image, release number, cpus, mem
      mescalDotJson = File.join(Dir.pwd, ".mescal.json")
      mescalConfig = ERB.new(open(mescalDotJson).read)
      mescalData = JSON.parse(@mescalConfig.result(Request.new.get_binding))
      sshCmd = @mescalData['sshCmd']
      @image = @mescalData['image'].split(':')[0]
      @release = @mescalData['image'].split(':')[1]

      # read mesos-deploy.yml for singularity url
      mesosDeployDotYml = File.join(Dir.pwd, "mesos-deploy.yml")
      mesosDeployConfig = YAML.load_file(mesosDeployDotYml)
      @uri = mesosDeployConfig['singularity_url']

      # create request and deploy json data
      @data = Hash.new
      @data['id'] = script.join("_")
      @data['command'] = "/sbin/my_init"
      # args are either the script/commands passed to 'singularity run', or the ssh command
      if script != "ssh"
        @data['arguments'] = ["--"]
        script.each { |i| @data['arguments'].push i }
      else 
        @data['arguments'] = sshCmd
      end 
      @data['resources']['mem'] = @mescalData['mem']
      @data['resources']['cpus'] = @mescalData['cpus']
      @data['env']['APPLICATION_ENV'] = "production"
      @data['containerInfo']['type'] = "DOCKER"
      @data['containerInfo']['docker']['image'] = @mescalData['image']
    end

    def is_paused
      begin
        resp = RestClient.get "#{@uri}/api/requests/request/#{@data['id']}"
        JSON.parse(resp)['state'] == 'PAUSED'
      rescue
        print " CREATING...".blue
        false
      end
    end

    def runner
      begin
        if is_paused()
          puts " PAUSED, SKIPPING".yellow
          return
        else
          # create or update the request
          @data['requestType'] = "RUN_ONCE"
          resp = RestClient.post "#{@uri}/api/requests", @data.to_json, :content_type => :json
        end
        # put script in commands & arguments line
        
        # deploy the request
        @data['requestId'] = @data['id']
        @data['id'] = "#{@release}.#{Time.now.to_i}"
        deploy = {
         'deploy' => @data,
         'user' => `whoami`.chomp,
         'unpauseOnSuccessfulDeploy' => false
        }
        resp = RestClient.post "#{@uri}/api/deploys", deploy.to_json, :content_type => :json
        
        puts " Deployed and running #{@script}".green
        # the line below needs to be changed to call the output from the API and print it to this console
        #
        # TODO
        #
        puts " Task will exit after script is complete, check #{@uri} for the output."
      rescue Exception => e
        puts " #{e.response}".red
      end
    end
  end
end
