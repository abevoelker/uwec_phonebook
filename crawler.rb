require File.join(File.dirname(__FILE__), 'person.rb')
require File.join(File.dirname(__FILE__), 'errors.rb')

module UWECPhonebook
  class Crawler

    def self.crawl(username='') # Could crawl on name_l, alternatively
      puts "crawling on #{username}"
      begin
        Person.lookup(:username => username)
      rescue UWECPhonebook::TooManyResults
        # Recurse by adding each alphabet letter to previous query
        return ('a'..'z').map {|l| crawl(username + l)}.flatten
      end
    end

  end
end
