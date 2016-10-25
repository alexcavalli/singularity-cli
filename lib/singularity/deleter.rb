module Singularity
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
        print "#{task_id}".light_blue
        puts ' DELETED'.red
      rescue
        puts "#{task_id} #{$!.response}"
      end
    end
  end
end