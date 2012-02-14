Simple script for gathering user details from http://phonebook.uwec.edu.

## To get all users:

    require './crawler'
    people = UWECPhonebook::Crawler.crawl
    # Serialize for storage (could also hook up ActiveRecord to Person):
    people.to_json # or to_xml, if you're old school

## To get a specific user:

    require './person'
    tan = UWECPhonebook::Person.lookup(:name_l => 'tan', :name_f => 'jack').first
    tan.dept # => "Computer Science"

Note:
This was originally written in Java but I had mistakenly deleted
the source files and committed the compiled .class files (whoops)

This could be optimized by threading requests and using a counting semaphore
to only allow `n` concurrent requests (to be polite), but... meh
