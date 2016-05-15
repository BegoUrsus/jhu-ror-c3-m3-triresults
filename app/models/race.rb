class Race
	include Mongoid::Document
	include Mongoid::Timestamps

	field :n, as: :name, type: String
	field :date, as: :date, type: Date
	field :loc, as: :location, type: Address

	field :next_bib, type: Integer, default: 0

	embeds_many :events, as: :parent, order: [:order.asc]

	scope :upcoming, -> { where(:date.gte => Date.current) }
	scope :past, -> { where( :date.lt => Date.current) }

	has_many :entrants, foreign_key: "race._id", dependent: :delete, order: [:secs.asc, :bib.asc]

	# data hash that defines the default properties
	DEFAULT_EVENTS = {
		"swim" => {:order=>0, :name=>"swim", :distance=>1.0,  :units=>"miles"},
		"t1"   => {:order=>1, :name=>"t1"},
		"bike" => {:order=>2, :name=>"bike", :distance=>25.0, :units=>"miles"},
		"t2"   => {:order=>3, :name=>"t2"},
		"run"  => {:order=>4, :name=>"run", :distance=>10.0,  :units=>"kilometers"}
	}	

	# Metadataprogramming definition
	# The outer loop is driven by the keys of the DEFAULT_EVENT hash shown above 
	# and defines the implementation for getting and/or creating the event. 
	# The inner loop conditionally creates and getter/setter for the lower-level property 
	# if a value exists in the hash.
	DEFAULT_EVENTS.keys.each do |name|
		define_method("#{name}") do
			event=events.select {|event| name==event.name}.first
			event||=events.build(DEFAULT_EVENTS["#{name}"])
		end
		["order","distance","units"].each do |prop|
			if DEFAULT_EVENTS["#{name}"][prop.to_sym]
				define_method("#{name}_#{prop}") do
					event=self.send("#{name}").send("#{prop}")
				end
				define_method("#{name}_#{prop}=") do |value|
					event=self.send("#{name}").send("#{prop}=", value)
				end
			end
		end
	end	

	# Implementation of a default instance of the Race given a source of event keys
	def self.default
		Race.new do |race|
			DEFAULT_EVENTS.keys.each {|leg|race.send("#{leg}")}
		end
	end

	# provides flattened access to city and state
	["city", "state"].each do |action|
		define_method("#{action}") do
			self.location ? self.location.send("#{action}") : nil
		end
		define_method("#{action}=") do |name|
			object=self.location ||= Address.new
			object.send("#{action}=", name)
			self.location=object
		end
	end

	# performs an atomic increment of the next_bib value and 
	# returns the result of next_bib
	def next_bib
    self[:next_bib] = self.inc(next_bib: 1)[:next_bib]
	end

	# returns a Placing instance with its name set to the name of 
	# the age group the racer will be competing in
	def get_group racer
		if racer && racer.birth_year && racer.gender
			quotient=(date.year-racer.birth_year)/10
			min_age=quotient*10
			max_age=((quotient+1)*10)-1
			gender=racer.gender
			name=min_age >= 60 ? "masters #{gender}" : "#{min_age} to #{max_age} (#{gender})"
			Placing.demongoize(:name=>name)
		end
	end

	# creates a new Entrant for the Race for a supplied Racer
	def create_entrant racer
		entrant = Entrant.new
		entrant.race = self.attributes.symbolize_keys.slice(:_id, :n, :date)
		entrant.racer = racer.info.attributes
		entrant.group = self.get_group(racer)
		events.each do |event|
    	  	if event
        		entrant.send("#{event.name}=", event)
      		end
    	end
    	entrant.validate
		if (entrant.valid?) 
			entrant.bib = next_bib
			entrant.save
		end
		return entrant
	end

	# returns complete Race instances being held on or after today that are 
	# not in a list of race_ids for the racer
	def self.upcoming_available_to racer
		# returns an array of upcoming race_ids for the racer
		#upcoming_race_ids = racer.races.upcoming.pluck(:race).map { |r| r[:id] }

		# returns race information for races that match a set of IDs
		#set_race_info = Race.in(:id=>upcoming_race_ids).pluck(:name, :date)

		# returns races on or after today no matter who is registered for them
		#upcoming_races = Race.upcoming.where(:name=>{:$regex=>"A2"}).pluck(:name,:date)

		upcoming_race_ids = racer.races.upcoming.pluck(:race).map { |r| r[:_id] }
    self.upcoming.not_in(:id => upcoming_race_ids)
	end

end
