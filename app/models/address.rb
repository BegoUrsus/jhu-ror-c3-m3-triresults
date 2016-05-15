class Address
	attr_accessor :city, :state, :location

	def initialize(city=nil, state=nil, loc=nil)
		@city = city
		@state = state
		if loc.nil?
			@location = Point.new(0.0, 0.0)
		else
			@location = Point.new(loc[:coordinates][0], loc[:coordinates][1])
		end  
	end

  # creates a DB-form of the instance
	# 	marshals the state of the instance into MongoDB format as a Ruby hash
	# 	produce a MongoDB format consistent with the following:
	# 			{:city=>"(city)", :state=>"(state)", :loc=>(point)}
	def mongoize
		return {
			:city => @city, 
			:state => @state, 
			:loc => {
				:type => 'Point', 
				:coordinates => [
					@location.longitude, @location.latitude
				]
			}		
		}
	end

	# returns the state marshalled into MongoDB format as a Ruby hash
  # takes in all forms of the object and produces a DB-friendly form
  def self.mongoize object

  	case object
  	when nil then
  		nil
  	when Hash then
  		Address.new(object[:city], object[:state], object[:loc]).mongoize
  	when Address then
  		object.mongoize
  	end
  end

	#creates an instance of the class from the DB-form of the data
	# returns an instance of the class (if appropriate)
	def self.demongoize object
		case object
		when nil
			nil
		when Hash then 
			Address.new(object[:city], object[:state], object[:loc])
		when Address then
			object
		end
	end

	# functionally behaves the same as the mongoize class method
  # used by criteria to convert object to DB-friendly form
  def self.evolve(object)
  	case object
  	when nil then
  		nil
  	when Address then 
  		object.mongoize
  	else 
  		object
  	end
  end

end